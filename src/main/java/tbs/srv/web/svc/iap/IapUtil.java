package tbs.srv.web.svc.iap;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;

import javax.sql.DataSource;

import org.apache.log4j.Logger;

import tbs.srv.data.EntityDef;
import tbs.srv.db.DbHelper;
import tbs.srv.db.models.UserData;
import tbs.srv.util.GameConfig;
import tbs.srv.util.InAppPurchaseItemDef;
import tbs.srv.util.RenownReason;
import tbs.srv.util.steam.Steam;
import tbs.srv.util.steam.Steam.ISteamMicroTxn.SteamTxnItemData;
import tbs.srv.util.steam.Steam.ISteamMicroTxn.SteamTxnResponseData;
import tbs.srv.util.steam.Steam.ISteamMicroTxn.SteamUserInfo;
import tbs.srv.web.WebConfig;

public class IapUtil {

	public static final Logger logger = Logger.getLogger(IapUtil.class.getSimpleName());

	public static class SteamPurchaseResult {
		public String steamurl;
	}

	public static SteamTxnResponseData doSteamPurchase(final SteamUserInfo sui, final String language, final IapCartItem[] cart, final long txn_id,
			final boolean clientsession) {
		SteamTxnItemData[] steam_items = new SteamTxnItemData[cart.length];

		for (int i = 0; i < cart.length; ++i) {
			steam_items[i] = new SteamTxnItemData(cart[i].item.id_hash, cart[i].qty);
			steam_items[i].amount = cart[i].unit_price * cart[i].qty;
			steam_items[i].category = cart[i].item.category;
			steam_items[i].description = cart[i].description;
		}

		SteamTxnResponseData rsp = null;

		final long TIMEOUT = 2000;
		final long start = System.currentTimeMillis();
		int count = 0;
		while (rsp == null) {
			++count;
			rsp = Steam.ISteamMicroTxn.initTxn(txn_id, sui.steamid, cart.length, language, sui.currency, clientsession, sui.ipaddress, steam_items);
			final long delta = System.currentTimeMillis() - start;

			if (delta > TIMEOUT) {
				break;
			}

			// ugh, just try again
		}

		logger.info("doSteamPurchase sui=" + sui + " txn=" + txn_id + ", count=" + count + " elapsed=" + (System.currentTimeMillis() - start));

		final boolean sandbox = GameConfig.instance.STEAM_MICRO_TXN_SANDBOX;
		persistSteamTxnResponse(WebConfig.instance.rdsDatasource, txn_id, sui.steamid, rsp, sandbox);

		return rsp;

	}

	public static void persistSteamTxnResponse(final DataSource ds, final long txn_id, final long steam_id, final SteamTxnResponseData rsp,
			final boolean sandbox) {
		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = ds.getConnection();
			{
				if (rsp != null) {

					if (rsp.ok) {
						ps = con.prepareStatement("INSERT INTO iap_steam (txn_id, steam_txn_id, steam_id, init_ok, sandbox) VALUES (?,?,?,1,?)");
						int index = 0;
						ps.setLong(++index, txn_id);
						ps.setLong(++index, rsp.transid);
						ps.setLong(++index, steam_id);
						ps.setBoolean(++index, sandbox);
						ps.executeUpdate();
						ps.close();
					} else {
						if (rsp.severe()) {
							 logger.error("persistSteamTxnResponse " + txn_id + ": " + rsp.message());
						}

						ps = con.prepareStatement("INSERT INTO iap_steam (txn_id, steam_txn_id, steam_id, init_fail, errorcode, errordesc, sandbox) VALUES (?,?,?,1,?,?,?)");
						int index = 0;
						ps.setLong(++index, txn_id);
						ps.setLong(++index, rsp.transid);
						ps.setLong(++index, steam_id);
						ps.setInt(++index, rsp.errorcode);
						ps.setString(++index, rsp.errordesc);
						ps.setBoolean(++index, sandbox);
						ps.executeUpdate();
						ps.close();
					}
				} else {
					// logger.error("persistSteamTxnResponse " + txn_id + ": NO RESPONSE");
					ps = con.prepareStatement("INSERT INTO iap_steam (txn_id, steam_id, init_fail, sandbox) VALUES (?,?,1,?)");
					int index = 0;
					ps.setLong(++index, txn_id);
					ps.setLong(++index, steam_id);
					ps.setBoolean(++index, sandbox);
					ps.executeUpdate();
					ps.close();
				}
			}

		} catch (SQLException e) {
			logger.error("persistSteamTxnResponse: " + txn_id + " " + e);
			e.printStackTrace();

		} finally {
			DbHelper.cleanup(con, ps);
		}

	}

	public static void persistSteamTxnFinalize(final DataSource ds, final long txn_id, final boolean ok) {
		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = ds.getConnection();

			ps = con.prepareStatement("UPDATE iap_steam SET finalize_ok=?, finalize_fail=? WHERE txn_id=?");
			int index = 0;
			ps.setBoolean(++index, ok);
			ps.setBoolean(++index, !ok);
			ps.setLong(++index, txn_id);
			ps.executeUpdate();
			ps.close();

		} catch (SQLException e) {
			logger.error("persistSteamTxnFinalize: " + txn_id + " " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}

	}

	public static void persistSteamTxnClientApproved(final DataSource ds, final long txn_id) {
		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = ds.getConnection();

			ps = con.prepareStatement("UPDATE iap_steam SET client_approved=1 WHERE txn_id=?");
			int index = 0;
			ps.setLong(++index, txn_id);
			ps.executeUpdate();
			ps.close();

		} catch (SQLException e) {
			logger.error("persistSteamTxnClientApproved: " + txn_id + " " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}

	}

	public static void persistCartEnd(final DataSource ds, final long txn_id, final boolean success, final boolean failed) {
		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = ds.getConnection();

			ps = con.prepareStatement("UPDATE iap_txn SET txn_end_time=?, success=?, failed=? WHERE txn_id=?");
			int index = 0;
			ps.setLong(++index, System.currentTimeMillis());
			ps.setBoolean(++index, success);
			ps.setBoolean(++index, failed);
			ps.setLong(++index, txn_id);

			ps.executeUpdate();

		} catch (SQLException e) {
			logger.error("persistCartEnd: " + txn_id + " " + e);
			e.printStackTrace();

		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

	public static long persistCartTransaction(DataSource ds, IapCartItem[] cart, final String currency, final long account_id, final long session_key) {

		int total_price = 0;
		int total_usd_estimate = 0;

		for (IapCartItem item : cart) {
			logger.debug("IapInitSvs.persistCartTransaction " + account_id + "/" + session_key + " " + item);
			total_price += item.unit_price;
			total_usd_estimate += item.usd_estimate;
		}

		long txn_id = 0;

		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = ds.getConnection();
			{
				ps = con.prepareStatement("INSERT INTO iap_txn (total_price,currency,total_usd_estimate,total_count,session_key,account_id,txn_init_time) VALUES (?,?,?,?,?,?,?)");

				int index = 0;
				ps.setInt(++index, total_price);
				ps.setString(++index, currency);
				ps.setInt(++index, total_usd_estimate);
				ps.setInt(++index, cart.length);
				ps.setLong(++index, session_key);
				ps.setLong(++index, account_id);
				ps.setLong(++index, System.currentTimeMillis());
				ps.executeUpdate();
				ps.close();
			}

			{
				ps = con.prepareStatement("SELECT LAST_INSERT_ID()");
				final ResultSet rs = ps.executeQuery();

				if (rs.next()) {
					txn_id = rs.getLong(1);
				} else {
					logger.error("Failed to create a txn");
					return 0;
				}
				ps.close();
			}

			if (txn_id >= GameConfig.instance.iapTxnIdRange.max) {
				logger.error("Exceeded IAP_TXN_ID_MAX, canceling txn: " + txn_id);
				ps = con.prepareStatement("DELETE FROM iap_txn WHERE txn_id=?");
				ps.setLong(1, txn_id);
				ps.executeUpdate();
				ps.close();
				return 0;
			}

			int cart_index = 0;
			for (IapCartItem item : cart) {

				ps = con.prepareStatement("INSERT INTO iap_cart (txn_id,cart_index,item_id,item_id_hash,qty,unit_price,usd_estimate,sale,normal_usd_cents) VALUES (?,?,?,?,?,?,?,?,?)");
				int index = 0;
				ps.setLong(++index, txn_id);
				ps.setInt(++index, cart_index++);
				ps.setString(++index, item.item.id);
				ps.setInt(++index, item.item.id_hash);
				ps.setInt(++index, item.qty);
				ps.setInt(++index, item.unit_price);

				ps.setInt(++index, item.usd_estimate);
				ps.setBoolean(++index, item.item.sale);
				ps.setInt(++index, item.item.usd_cents);

				ps.executeUpdate();
				ps.close();
			}

		} catch (SQLException e) {
			e.printStackTrace();
			txn_id = 0;
		} finally {
			DbHelper.cleanup(con, ps);
		}

		return txn_id;
	}

	private static class CartItem {
		public String item_id;
		public int qty;
		public int purchase_count;
	};

	public static int handleSucessfulPurchase(final DataSource ds, final long account_id, final long orderid) {

		logger.info("handleSucessfulPurchase " + account_id + " " + orderid);

		final ArrayList<CartItem> cart = new ArrayList<CartItem>();

		int usd_estimate_total = 0;
		
		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = ds.getConnection();
			ps = con.prepareStatement("SELECT iap_cart.usd_estimate, iap_cart.item_id, iap_cart.qty, iap.purchase_count FROM iap_cart LEFT JOIN iap ON iap_cart.item_id = iap.item_id AND iap.account_id=? WHERE iap_cart.txn_id=?");
			ps.setLong(1, account_id);
			ps.setLong(2, orderid);

			final ResultSet rs = ps.executeQuery();
			while (rs.next()) {
				final CartItem ci = new CartItem();
				ci.item_id = rs.getString("item_id");
				ci.qty = rs.getInt("qty");
				ci.purchase_count = rs.getInt("purchase_count");
				usd_estimate_total += rs.getInt("usd_estimate");
				cart.add(ci);
			}
			ps.close();

			for (CartItem ci : cart) {
				ps = con.prepareStatement("REPLACE INTO iap (account_id, item_id, purchase_count) VALUES (?,?,?)");
				ps.setLong(1, account_id);
				ps.setString(2, ci.item_id);
				ps.setInt(3, ci.purchase_count + ci.qty);
				ps.executeUpdate();
				ps.close();
			}

		} catch (SQLException e) {
			logger.error("handleSucessfulPurchase " + account_id + " " + orderid + " FAILED: " + e);
			e.printStackTrace();

		} finally {
			DbHelper.cleanup(con, ps);
		}

		for (CartItem ci : cart) {
			// TODO: update the client purchase list or leave it up to the client?
			applySuccessfulItemPurchase(orderid, account_id, ci.item_id, ci.qty);
		}
		
		return usd_estimate_total;
	}

	public static void applySuccessfulItemPurchase(final long orderid, final long account_id, final String item_id, final int qty) {
		applySuccessfulItemPurchase(RenownReason.IAP, Long.toString(orderid), account_id, item_id, qty);
	}

	public static void applySuccessfulItemPurchase(final RenownReason renownReason, final String renownNote, final long account_id, final String item_id,
			final int qty) {

		logger.info("applySuccessfulItemPurchase reason=" + renownReason + ", note=" + renownNote + ", account_id=" + account_id + ", item_id=" + item_id
				+ ", qty=" + qty);

		final InAppPurchaseItemDef item = GameConfig.instance.in_app_purchase_items.getItem(item_id);

		int cur_roster_rows;
		try {
			cur_roster_rows = UserData.loadRosterRows(account_id);
		} catch (SQLException e) {
			logger.error("failed to load " + account_id + " roster rows, defaulting to " + GameConfig.instance.statCosts.max_num_roster_rows);
			cur_roster_rows = GameConfig.instance.statCosts.max_num_roster_rows;
		}

		int new_roster_rows = cur_roster_rows;

		for (int i = 0; i < qty; ++i) {

			if (item.renown > 0) {
				GameConfig.instance.renown.modifyRenown(account_id, item.renown, renownReason, renownNote);
			}

			for (Object unlockv : item.unlocks) {
				final String unlock_id = (String) unlockv;
				final long dur = 1000L * item.days * 24 * 60 * 60;
				GameConfig.instance.unlock.unlock(account_id, unlock_id, dur);
			}

			for (Object unitidv : item.units) {
				final String unit_id = (String) unitidv;
				final EntityDef unit = GameConfig.instance.in_app_purchase_items.getUnit(unit_id);
				if (unit == null) {
					logger.error("Invalid purchase " + item_id + " unit id " + unit_id);
				} else {
					GameConfig.instance.unitAdd.addUnit(account_id, unit);
				}
			}

			if (item.roster_rows > 0) {
				new_roster_rows += item.roster_rows;
			}

			for (String sub_iap : item.iaps) {
				applySuccessfulItemPurchase(renownReason, renownNote, account_id, sub_iap, 1);
			}
		}

		if (new_roster_rows > cur_roster_rows) {

			if (new_roster_rows > cur_roster_rows) {
				try {
					UserData.saveRosterRows(account_id, new_roster_rows);
				} catch (SQLException e) {
					logger.error("Failed to save " + account_id + " roster rows " + new_roster_rows);
				}
			}
		}
	}
}
