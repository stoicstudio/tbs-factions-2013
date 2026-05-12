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

public class BattleMoveData extends BaseBattleTurnData {

	private static final Logger logger = Logger.getLogger(BattleMoveData.class.getSimpleName());

	public Object[] tiles;

	public BattleMoveData() {

	}

	protected String constructReliableMsgId() {
		return battleId + "_move_" + user + "_" + turn;
	}

	@Override
	public String toString() {
		return super.toString() + " tiles=" + Arrays.toString(tiles);
	}

	public Tile getLastTile() {
		if (tiles != null && tiles.length > 0) {
			return (Tile) tiles[tiles.length - 1];
		}

		return null;
	}

	public Tile getTile(int index) {
		return (Tile) tiles[index];
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);
		out.add("tiles", tiles);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		super.fromJSON(jo);
		tiles = (Object[]) jo.get("tiles");
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

	public void save(GameConfig config) {

		Connection con = null;
		PreparedStatement ps = null;
		try {

			con = config.rdsDatasource.getConnection();

			final String sql = "INSERT INTO battle_move " //
					+ " (battle_id, battle_msg_num, battle_turn, account_id, entity_id, battle_tiles, battle_tile_end_x, battle_tile_end_y, battle_num_steps, ordinal) VALUES " //
					+ " (?,?,?,?,?,?,?,?,?,?)";

			ps = con.prepareStatement(sql);
			int index = 0;
			ps.setString(++index, battleId);
			ps.setInt(++index, 0);
			ps.setInt(++index, turn);
			ps.setLong(++index, user);
			ps.setString(++index, entity);
			ps.setString(++index, JSON.toString(tiles));
			ps.setInt(++index, getLastTile().x);
			ps.setInt(++index, getLastTile().y);
			ps.setInt(++index, tiles.length);
			ps.setInt(++index, ordinal);

			ps.executeUpdate();
		} catch (SQLException e) {
			logger.error("save :" + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}
}