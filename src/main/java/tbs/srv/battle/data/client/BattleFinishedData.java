package tbs.srv.battle.data.client;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.battle.data.base.BaseBattleData;

public class BattleFinishedData extends BaseBattleData {

	public String victoriousTeam;

	public BattleRewardData[] rewards = new BattleRewardData[0];
	public int total_renown = 0;

	public void incrementAward(final int party, final BattleRenownAwardType type, final int delta) {

		rewards[party].incrementAward(type, delta);
	}

	public void addAchievement(final int party_index, final String achievement_id, final int value) {
		rewards[party_index].addAchievement(achievement_id, value);
	}

	public BattleFinishedData() {

	}

	public BattleFinishedData(long user, String battleId, final int numParties) {
		super(null, user, battleId);

		this.rewards = new BattleRewardData[numParties];

		for (int i = 0; i < rewards.length; ++i) {
			this.rewards[i] = new BattleRewardData();
		}
	}

	public void compute() {

		total_renown = 0;
		for (BattleRewardData value : rewards) {
			value.compute();
			total_renown += value.total_renown;
		}
	}

	protected String constructReliableMsgId() {
		return battleId + "_finished_" + user;
	}

	public String toString() {
		return super.toString();
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);

		out.add("victoriousTeam", victoriousTeam);
		out.add("total_renown", total_renown);
		out.add("rewards", rewards);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		super.fromJSON(jo);

		victoriousTeam = (String) jo.get("victoriousTeam");
		total_renown = ((Number) jo.get("total_renown")).intValue();
		final Object[] ro = (Object[]) jo.get("rewards");
		rewards = new BattleRewardData[ro.length];
		System.arraycopy(ro, 0, rewards, 0, ro.length);
	}

	public int getPartyRenown(int index) {
		return rewards[index].total_renown;
	}
}