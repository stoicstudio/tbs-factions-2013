package tbs.srv.web.svc.iap.finalize;

import java.util.Map;

import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON;

import com.newrelic.api.agent.NewRelic;

import tbs.srv.db.models.SessionData;
import tbs.srv.util.GameConfig;
import tbs.srv.util.steam.Steam;
import tbs.srv.web.WebConfig;
import tbs.srv.web.svc.iap.IapUtil;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class IapFinalizeSvc {

	public static final Logger logger = Logger.getLogger(IapFinalizeSvc.class.getSimpleName());

	@Path("/{sessionKey}")
	@POST
	public Response finalize(String body, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		@SuppressWarnings("unchecked")
		final Map<String, Object> json = (Map<String, Object>) JSON.parse(body);
		final int orderid = ((Number) json.get("orderid")).intValue();

		logger.debug("finalize " + session + " orderid=" + orderid);

		final Steam.ISteamMicroTxn.SteamUserInfo sui = session.getSteamUserInfo(WebConfig.instance.rdsDatasource);

		if (sui == null) {
			NewRelic.incrementCounter("Custom/iap/txn/count/final_fail", 1);
			NewRelic.incrementCounter("Custom/iap/final/fail/no_sui", 1);
			logger.error("finalize " + session + " orderid=" + orderid + " NO STEAMUSERINFO");
			return Response.serverError().entity("finalize no steam userinfo").build();
		}

		if (!sui.isOk()) {
			if (!GameConfig.instance.STEAM_TXN_FORCE_FINALIZE) {
				NewRelic.incrementCounter("Custom/iap/txn/count/final_fail", 1);
				NewRelic.incrementCounter("Custom/iap/final/fail/bad_sui", 1);
				logger.error("finalize " + session + " orderid=" + orderid + " sui=" + sui + " INVALID STEAMUSERINFO");
				return Response.serverError().entity("finalize invalid steam user info").build();
			}

			sui.fakeIt();
		}

		IapUtil.persistSteamTxnClientApproved(GameConfig.instance.rdsDatasource, orderid);

		boolean ok = false;
		final long TIMEOUT = 5000;
		final long start = System.currentTimeMillis();
		int count = 0;
		int[] out_errorcode = new int[1];
		String[] out_errordesc = new String[1];
		while (!ok) {
			++count;
			ok = Steam.ISteamMicroTxn.finalizeTxn(sui.steamid, orderid, out_errorcode, out_errordesc);
			final long delta = System.currentTimeMillis() - start;
			if (delta > TIMEOUT) {
				break;
			}
			// ugh, just try again
		}

		logger.info("finalize count=" + count + " elapsed=" + (System.currentTimeMillis() - start));

		if (!ok) {
			NewRelic.incrementCounter("Custom/iap/txn/count/final_fail", 1);
			NewRelic.incrementCounter("Custom/iap/final/fail/steam/" + out_errorcode[0], 1);

			logger.error("finalize " + session + " orderid=" + orderid + " FAILED FINALIZE");
			IapUtil.persistSteamTxnFinalize(GameConfig.instance.rdsDatasource, orderid, false);
			IapUtil.persistCartEnd(GameConfig.instance.rdsDatasource, orderid, false, true);
			return Response.serverError().entity("finalize failed").build();
		} else {

			logger.info("finalize " + session + " orderid=" + orderid + " OK, handling successful purchase");
			IapUtil.persistSteamTxnFinalize(GameConfig.instance.rdsDatasource, orderid, true);
			IapUtil.persistCartEnd(GameConfig.instance.rdsDatasource, orderid, true, false);
			final int usd_estimate_total = IapUtil.handleSucessfulPurchase(WebConfig.instance.rdsDatasource, session.account_id, orderid);

			NewRelic.incrementCounter("Custom/iap/txn/count/final_ok", 1);
			NewRelic.incrementCounter("Custom/iap/usd/final", usd_estimate_total);

			return Response.ok().build();
		}
	}

}