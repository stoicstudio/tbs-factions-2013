package tbs.srv.battle;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;

import org.eclipse.jetty.util.ajax.JSON;

import tbs.srv.battle.data.BattleReplayData;
import tbs.srv.battle.data.base.BaseBattleData;
import tbs.srv.db.DbHelper;
import tbs.srv.util.GameConfig;

public class BattleReplay {

	public static BattleReplayData getReplay(final GameConfig config, final String battle_id) {

		ArrayList<BaseBattleData> msgs = new ArrayList<BaseBattleData>();

		Connection con = null;
		PreparedStatement ps = null;
		try {

			con = config.rdsDatasource.getConnection();
			{
				ps = con.prepareStatement("SELECT battle_msg FROM battle_msg WHERE battle_id=? ORDER BY `key`");

				final ResultSet rs = ps.executeQuery();

				while (rs.next()) {
					final String msg = rs.getString("battle_msg");
					final BaseBattleData data = (BaseBattleData) JSON.parse(msg);
					msgs.add(data);
				}
			}

		} catch (SQLException e) {
			e.printStackTrace();
			return null;
		} finally {
			DbHelper.cleanup(con, ps);
		}

		final BattleReplayData rpd = new BattleReplayData();
		rpd.battle_id = battle_id;
		rpd.battle_msgs = msgs.toArray();
		return rpd;
	}
}
