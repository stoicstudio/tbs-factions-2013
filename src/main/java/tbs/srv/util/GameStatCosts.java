package tbs.srv.util;

import java.util.Arrays;
import java.util.Map;

import org.apache.log4j.Logger;

public class GameStatCosts {
	private int[] stats;
	private int[] promotes;
	private int rename;
	private int variation;
	public int roster_row_cost;
	public int max_num_roster_rows;
	public int roster_slots_per_row;

	public GameStatCosts(Map<String, Object> map) {

		final Object[] jstats = (Object[]) map.get("stats");
		final Object[] jpromotes = (Object[]) map.get("promotes");
		rename = ((Number) map.get("rename")).intValue();
		variation = ((Number) map.get("variation")).intValue();
		roster_row_cost = ((Number) map.get("roster_row_cost")).intValue();
		max_num_roster_rows = ((Number) map.get("max_num_roster_rows")).intValue();
		roster_slots_per_row = ((Number) map.get("max_num_roster_rows")).intValue();

		if (jstats == null || jpromotes == null) {
			throw new IllegalArgumentException("Malformed GameStatCosts");
		}

		stats = new int[jstats.length];
		promotes = new int[jpromotes.length];

		for (int i = 0; i < stats.length; ++i) {
			stats[i] = ((Number) jstats[i]).intValue();
		}

		for (int i = 0; i < promotes.length; ++i) {
			promotes[i] = ((Number) jpromotes[i]).intValue();
		}

		Logger.getLogger(getClass().getSimpleName()).info("stats=" + Arrays.toString(stats) + " promotes=" + Arrays.toString(promotes));
	}

	public int getTotalCost(final int rank, final int delta) {
		// rank is base 1
		// everything costs positive renown
		return Math.max(0, stats[rank - 1] * delta);
	}

	public int getPromotionCost(final int fromRank) {
		// rank is base 1
		return promotes[fromRank - 1];
	}

	public int getRenameCost() {
		return rename;
	}

	public int getVariationCost() {
		return variation;
	}

}
