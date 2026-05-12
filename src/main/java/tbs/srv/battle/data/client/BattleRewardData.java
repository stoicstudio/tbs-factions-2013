package tbs.srv.battle.data.client;

import java.util.HashMap;
import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class BattleRewardData implements Convertible {
	public Map<String, Integer> awards = new HashMap<String, Integer>();
	public Map<String, Integer> achievements = new HashMap<String, Integer>();
	public int total_renown;
	public int total_achievement_renown;

	public void incrementAward(final BattleRenownAwardType type, final int delta) {
		final String n = type.name();
		Integer a = 0;
		if (awards.containsKey(n)) {
			a = awards.get(n);
		}
		a = a + delta;
		awards.put(type.name(), a);
	}

	public void addAchievement(final String achievement_id, final int value) {
		achievements.put(achievement_id, value);
	}

	public int getAward(final BattleRenownAwardType type) {
		final String n = type.name();
		if (awards.containsKey(n)) {
			return awards.get(n);
		}
		return 0;
	}

	public void compute() {

		total_achievement_renown = 0;
		total_renown = 0;

		for (Integer value : awards.values()) {
			total_renown += value;
		}

		for (Integer value : achievements.values()) {
			total_achievement_renown += value;
			total_renown += value;
		}
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("awards", awards);
		out.add("achievements", achievements);
		out.add("total_renown", total_renown);
		out.add("total_achievement_renown", total_achievement_renown);

	}

	@SuppressWarnings("unchecked")
	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {

		total_renown = ((Number) jo.get("total_renown")).intValue();
		total_achievement_renown = ((Number) jo.get("total_achievement_renown")).intValue();

		awards = (Map<String, Integer>) jo.get("awards");
		achievements = (Map<String, Integer>) jo.get("achievements");

	}
}