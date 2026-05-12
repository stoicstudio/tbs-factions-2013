package tbs.srv.battle.data.client;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.battle.data.Tile;
import tbs.srv.battle.data.base.BaseBattleData;

public class BattleDeployData extends BaseBattleData {

	Object[] tiles;

	public BattleDeployData() {

	}

	public BattleDeployData(long user, String battleId, Tile[] tiles) {
		super(null, user, battleId);
		this.tiles = tiles;
	}

	protected String constructReliableMsgId() {
		return battleId + "_deploy_" + user;
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
}