package tbs.srv.data;

import java.util.Map;

public class TourneyDefList {

	public TourneyDef[] defs;

	@SuppressWarnings("unchecked")
	public TourneyDefList(Object[] data) {

		defs = new TourneyDef[data.length];

		for (int i = 0; i < data.length; ++i) {
			final TourneyDef def = new TourneyDef((Map<String, Object>) data[i]);
			defs[i] = def;
		}
	}

	public TourneyDef find(final String name) {
		for (int i = 0; i < defs.length; ++i) {
			final TourneyDef def = defs[i];
			if (def.name.equals(name)) {
				return def;
			}
		}

		return null;
	}

}