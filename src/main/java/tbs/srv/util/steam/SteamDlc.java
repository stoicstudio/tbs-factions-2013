package tbs.srv.util.steam;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashSet;
import java.util.Set;

import org.apache.log4j.Logger;

import tbs.srv.db.DbHelper;
import tbs.srv.util.GameConfig;
import tbs.srv.util.RenownReason;
import tbs.srv.web.svc.iap.IapUtil;

public class SteamDlc {
	private static final Logger logger = Logger.getLogger(SteamDlc.class.getSimpleName());

	public static Set<Integer> getProcessedDlc(final long account_id) {

		HashSet<Integer> dlcs = new HashSet<Integer>();

		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			ps = con.prepareStatement("SELECT dlc_appid from steam_dlc where account_id=?");
			ps.setLong(1, account_id);

			final ResultSet rs = ps.executeQuery();
			while (rs.next()) {
				dlcs.add(rs.getInt(1));
			}
			rs.close();
			ps.close();

		} catch (SQLException e) {
			logger.error("getProcessedDlc " + account_id + ": " + e);
			e.printStackTrace();

		} finally {
			DbHelper.cleanup(con, ps);
		}

		return dlcs;
	}

	public static void processDlc(final long account_id, final int dlc_appid) {

		final String iap = GameConfig.instance.in_app_purchase_items.steam_dlc_items.get(dlc_appid);
		if (iap == null) {
			logger.error("invalid dlc " + dlc_appid);
			return;
		}

		logger.info("processDlc " + account_id + " " + dlc_appid + " " + iap);

		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			ps = con.prepareStatement("INSERT INTO steam_dlc (account_id, dlc_appid, dlc_iap, dlc_time) VALUES (?,?,?,UNIX_TIMESTAMP()*1000)");
			ps.setLong(1, account_id);
			ps.setInt(2, dlc_appid);
			ps.setString(3, iap);
			ps.executeUpdate();
			ps.close();
			con.close();
		} catch (SQLException e) {
			logger.error("processDlc " + account_id + ": " + e);
			e.printStackTrace();
			return;
		} finally {
			DbHelper.cleanup(con, ps);
		}

		// persisted, now grant

		IapUtil.applySuccessfulItemPurchase(RenownReason.DLC, Integer.toString(dlc_appid), account_id, iap, 1);
	}

}
