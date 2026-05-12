package tbs.srv.battle.data.client;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Map;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON;
import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.battle.data.Tile;
import tbs.srv.battle.data.base.BaseBattleTurnData;
import tbs.srv.db.DbHelper;
import tbs.srv.util.GameConfig;

public class BattleActionData extends BaseBattleTurnData {

	private static final Logger logger = Logger.getLogger(BattleActionData.class.getSimpleName());

	public String action;
	public int level;
	public Object[] tiles;
	public Object[] target_ids;
	public int executed_id;
	public boolean terminator;

	public BattleActionData() {

	}

	protected String constructReliableMsgId() {
		return battleId + "/" + user + "/" + turn;
	}

	public String toString() {
		return super.toString() + " " + action + "/" + level + " " + Arrays.toString(target_ids) + " " + Arrays.toString(tiles);
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);
		out.add("tiles", tiles);
		out.add("action", action);
		out.add("level", level);
		out.add("target_ids", target_ids);
		out.add("executed_id", executed_id);
		if (terminator) {
			out.add("terminator", terminator);
		}
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		super.fromJSON(jo);
		tiles = (Object[]) jo.get("tiles");
		target_ids = (Object[]) jo.get("target_ids");
		action = (String) jo.get("action");
		level = ((Number) jo.get("level")).intValue();
		executed_id = ((Number) jo.get("executed_id")).intValue();
		final Boolean bterminator = (Boolean) jo.get("terminator");
		terminator = bterminator != null ? bterminator.booleanValue() : false;

		validateTilesJson();
	}

	public void validateTilesJson() {

		if (tiles == null) {
			tiles = new Object[0];
		}

		for (int i = 0; i < tiles.length; ++i) {
			Object to = tiles[i];

			// convert to actual tiles
			if (to instanceof Map) {
				@SuppressWarnings("unchecked")
				Tile tile = new Tile((Map<String, Object>) to);
				tiles[i] = tile;
			}
		}
	}

	public Tile getTile(int index) {
		return (Tile) tiles[index];
	}

	public String getTargetId(int index) {
		return (String) target_ids[index];
	}

	public void save(GameConfig config) {

		Connection con = null;
		PreparedStatement ps = null;
		try {

			con = config.rdsDatasource.getConnection();

			final String sql = "INSERT INTO battle_action " //
					+ " (battle_id, battle_msg_num, battle_turn, account_id, entity_id, battle_tiles, battle_target_ids, battle_action, battle_action_level, battle_action_executed_id, ordinal, terminator) VALUES " //
					+ " (?,?,?,?,?,?,?,?,?,?,?,?)";

			ps = con.prepareStatement(sql);
			int index = 0;
			ps.setString(++index, battleId);
			ps.setInt(++index, 0);
			ps.setInt(++index, turn);
			ps.setLong(++index, user);
			ps.setString(++index, entity);
			ps.setString(++index, (tiles != null && tiles.length > 0) ? JSON.toString(tiles) : null);
			ps.setString(++index, (target_ids != null && target_ids.length > 0) ? JSON.toString(target_ids) : null);
			ps.setString(++index, action);
			ps.setInt(++index, level);
			ps.setInt(++index, executed_id);
			ps.setInt(++index, ordinal);
			ps.setBoolean(++index, terminator);

			ps.executeUpdate();
		} catch (SQLException e) {
			logger.error("save :" + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}
}