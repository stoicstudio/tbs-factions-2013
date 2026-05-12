package tbs.srv.web.svc.iap.init;

import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON;

import tbs.srv.db.models.SessionData;
import tbs.srv.db.models.UserData;
import tbs.srv.util.GameConfig;
import tbs.srv.util.InAppPurchaseItemDef;
import tbs.srv.util.steam.Steam;
import tbs.srv.util.steam.Steam.ISteamMicroTxn.SteamTxnResponseData;
import tbs.srv.web.WebConfig;
import tbs.srv.web.svc.iap.IapCartItem;
import tbs.srv.web.svc.iap.IapUtil;

import com.newrelic.api.agent.NewRelic;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class IapInitSvc {

	public static final Logger logger = Logger.getLogger(IapInitSvc.class.getSimpleName());

	private Steam.ISteamMicroTxn.SteamUserInfo attemptSteamUserInfo(final SessionData session) {

		long start = System.currentTimeMillis();

		// wait a bit, if necessary
		for (int i = 0; i < 10; ++i) {
			Steam.ISteamMicroTxn.SteamUserInfo sui = session.getSteamUserInfo(GameConfig.instance.rdsDatasource);
			if (sui != null) {
				if (sui.isOk()) {
					return sui;
				}
				if (GameConfig.instance.STEAM_TXN_FORCE_FINALIZE) {
					sui.fakeIt();
					return sui;
				}
			}

			if (sui == null || !sui.isOk()) {

				long cur = System.currentTimeMillis();
				long delta = cur - start;

				if (delta > 10000) {
					logger.error("timeout getting SteamUserInfo for " + session);
					return null;
				}
				try {
					Thread.sleep(1000);
				} catch (InterruptedException e) {

				}
			}
		}
		logger.error("gave up getting SteamUserInfo for " + session);
		return null;

	}

	@Path("/{sessionKey}")
	@POST
	public Response init(String body, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		if (GameConfig.instance.iapTxnIdRange == null) {
			return Response.serverError().entity("server txns disabled").build();
		}

		final Steam.ISteamMicroTxn.SteamUserInfo sui = attemptSteamUserInfo(session);

		if (sui == null) {
			logger.warn("init NO SteamUserInfo session=" + session);
			return Response.serverError().entity("no steam user info").build();
		}

		if (!sui.isOk()) {
			logger.warn("init BROKEN SteamUserInfo session=" + session);
			return Response.serverError().entity("init broken steam user info: " + sui.debugString()).build();
		}

		@SuppressWarnings("unchecked")
		final Map<String, Object> json = (Map<String, Object>) JSON.parse(body);

		final Boolean overlay = (Boolean) json.get("overlay");
		final Object[] items = (Object[]) json.get("items");
		final String language = (String) json.get("language");

		int extra_units = 0;
		int extra_rows = 0;

		int usd_estimate_total = 0;

		IapCartItem[] cart = new IapCartItem[items.length];
		for (int i = 0; i < items.length; ++i) {
			@SuppressWarnings("rawtypes")
			Map itemv = (Map) items[i];
			final String id = (String) itemv.get("id");
			final int qty = ((Number) itemv.get("qty")).intValue();
			final String description = (String) itemv.get("description");

			final InAppPurchaseItemDef item = WebConfig.instance.in_app_purchase_items.getItem(id);

			if (item == null) {
				return Response.status(Status.BAD_REQUEST).build();
			}

			final int unit_price = WebConfig.instance.in_app_purchase_items.getPrice(item, sui.currency, item.sale);

			final int usd_estimate = WebConfig.instance.in_app_purchase_items.convertToUsdCents(sui.currency, unit_price);

			cart[i] = new IapCartItem(item, qty, unit_price, usd_estimate, description);

			logger.info("init session=" + session + " item=" + cart[i]);

			NewRelic.incrementCounter("Custom/iap/init/item/" + id, qty);

			usd_estimate_total += usd_estimate;
			extra_units += item.units.length;
			extra_rows += item.roster_rows;
		}

		if (extra_units > 0) {

			try {
				final int numRosterRows = UserData.loadRosterRows(session.account_id);
				final int rosterSize = UserData.loadRosterCount(session.account_id);

				final int afterRosterSize = rosterSize + extra_units;
				final int requiredAfterRosterRows = (int) Math.ceil(afterRosterSize / GameConfig.instance.statCosts.roster_slots_per_row);
				final int afterRosterRows = numRosterRows + extra_rows;

				if (afterRosterRows < requiredAfterRosterRows) {
					logger.error("init INSUFFICIENT ROWS session=" + session);
					return Response.status(Status.BAD_REQUEST).entity("not enough roster space").build();
				}
			} catch (SQLException exp) {
				logger.error("init ROSTER LOAD FAIL session=" + session + ": " + exp);
				return Response.serverError().entity("unable to load roster").build();
			}
		}

		final long txn_id = IapUtil.persistCartTransaction(WebConfig.instance.rdsDatasource, cart, sui.currency, session.account_id, session.getSessionKey());

		if (txn_id <= 0) {
			logger.error("init PERSIST FAIL session=" + session);
			return Response.serverError().entity("unable to persist cart transaction").build();
		}

		SteamTxnResponseData steam_rsp = IapUtil.doSteamPurchase(sui, language, cart, txn_id, overlay);

		if (steam_rsp == null || !steam_rsp.ok) {

			if (!GameConfig.instance.STEAM_TXN_FORCE_FINALIZE) {
				final String rsp_msg = steam_rsp != null ? steam_rsp.message() : "<NO RESPONSE>";
				if (steam_rsp != null && steam_rsp.severe()) {
					logger.error("init " + session + " orderid=" + txn_id + " FAILED INIT: " + rsp_msg);
				} else {
					logger.warn("init " + session + " orderid=" + txn_id + " FAILED INIT: " + rsp_msg);
				}
				IapUtil.persistCartEnd(WebConfig.instance.rdsDatasource, txn_id, false, true);
				final String msg = steam_rsp != null ? steam_rsp.message() : "No response from steam";
				if (steam_rsp == null || steam_rsp.severe()) {
					logger.error("init FAIL session=" + session + ": " + msg);
				} else {
					logger.warn("init FAIL session=" + session + ": " + msg);
				}

				String errcode = steam_rsp != null ? Integer.toString(steam_rsp.errorcode) : "";
				NewRelic.incrementCounter("Custom/iap/init/fail/steam/" + errcode, 1);
				NewRelic.incrementCounter("Custom/iap/txn/count/init_fail", 1);

				return Response.serverError().entity("Unable to initialize purchase: " + msg).build();
			}

			steam_rsp = new SteamTxnResponseData();
			steam_rsp.orderid = txn_id;
		}

		NewRelic.incrementCounter("Custom/iap/txn/count/init_ok", 1);
		NewRelic.incrementCounter("Custom/iap/usd/init", usd_estimate_total);

		final Map<String, Object> rsp = new HashMap<String, Object>();
		rsp.put("transid", txn_id);
		rsp.put("orderid", steam_rsp.orderid);
		rsp.put("steamurl", steam_rsp.steamurl);

		return Response.ok(JSON.toString(rsp)).build();
	}

}