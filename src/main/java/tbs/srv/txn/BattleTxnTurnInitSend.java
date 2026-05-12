package tbs.srv.txn;

import java.util.HashMap;
import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON;

public class BattleTxnTurnInitSend {

	public String entity;
	public String team;
	// public EntityData[] entities;
	// public String[] entitiesStrings;
	public long randomSampleCount;
	public long entitiesHash;

	@SuppressWarnings("unchecked")
	public BattleTxnTurnInitSend(String vars) {
		Map<String, Object> jo = (Map<String, Object>) JSON.parse(vars);

		entity = (String) jo.get("entity");
		team = (String) jo.get("team");

		// Object[] entitiesv = (Object[]) jo.get("entities");
		//
		// if (entitiesv != null) {
		// entities = new EntityData[entitiesv.length];
		// for (int i = 0; i < entitiesv.length; ++i) {
		// EntityData ent = new EntityData(entitiesv[i]);
		// entities[i] = ent;
		// }
		// }

		randomSampleCount = ((Number) jo.get("randomSampleCount")).longValue();
		entitiesHash = ((Number) jo.get("entitiesHash")).longValue();
	}

	public static class EntityData {
		String id;
		StatsData stats;

		@SuppressWarnings("unchecked")
		public EntityData(Object vars) {
			Map<String, Object> vm = (Map<String, Object>) vars;

			id = (String) vm.get("id");

			Object[] statsv = (Object[]) vm.get("stats");
			stats = new StatsData(statsv);
		}
	}

	public static class StatsData {
		String[] stats;
		HashMap<String, Long> values = new HashMap<String, Long>();

		@SuppressWarnings("unchecked")
		public StatsData(Object[] vars) {

			stats = new String[vars.length];
			for (int i = 0; i < vars.length; ++i) {
				Map<String, Object> sm = (Map<String, Object>) vars[i];
				String stat = (String) sm.get("stat");
				Long value = (Long) sm.get("value");

				stats[i] = stat;
				values.put(stat, value);
			}
		}

		public int getValue(String stat, int d) {
			Long ii = values.get(stat);
			if (ii != null) {
				return ii.intValue();
			}

			return d;
		}
	}
}
