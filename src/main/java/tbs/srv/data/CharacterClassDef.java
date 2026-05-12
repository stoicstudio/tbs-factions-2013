package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON;
import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class CharacterClassDef implements Convertible {

	public String id;
	public Object[] statRanges;
	public Object[] actives;
	public Object[] attacks;
	public String passive;
	public String parent;
	public AppearanceDef[] appearances = new AppearanceDef[0];

	public CharacterClassDef() {

	}

	public CharacterClassDef(Map<String, Object> data) {
		fromData(data);
	}

	@SuppressWarnings("unchecked")
	public CharacterClassDef(String data) {
		fromData((Map<String, Object>) JSON.parse(data));
	}

	private void fromData(Map<String, Object> data) {
		id = (String) data.get("id");
		// power = ((Long) data.get("power")).intValue();

		Object[] ss = (Object[]) data.get("stats");
		if (ss != null) {
			statRanges = new Object[ss.length];
			for (int i = 0; i < ss.length; ++i) {
				@SuppressWarnings("unchecked")
				Map<String, Object> so = (Map<String, Object>) ss[i];
				StatRange stat = new StatRange();
				stat.fromJSON(so);

				if (stat.stat.equals(StatType.RANK.name())) {
					stat.min = Math.max(1, stat.min);
					stat.max = Math.max(stat.min, stat.max);
				}

				statRanges[i] = stat;
			}
		}

		actives = (Object[]) data.get("actives");
		attacks = (Object[]) data.get("attacks");
		passive = (String) data.get("passive");
		parent = (String) data.get("parent");

		final Object[] appsv = (Object[]) data.get("appearances");

		if (appsv != null) {

			appearances = new AppearanceDef[appsv.length];

			for (int i = 0; i < appsv.length; ++i) {
				@SuppressWarnings("rawtypes")
				final Map appv = (Map) appsv[i];

				final AppearanceDef app = new AppearanceDef();
				appearances[i] = app;
				app.unlock_id = (String) appv.get("unlock_id");
				app.acquire_id = (String) appv.get("acquire_id");
			}
		}
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("id", id);

		if (statRanges != null && statRanges.length > 0) {
			out.add("stats", statRanges);
		}

		if (actives != null) {
			out.add("actives", actives);
		}
		if (passive != null) {
			out.add("passive", passive);
		}
		if (attacks != null) {
			out.add("attacks", attacks);
		}
		if (parent != null) {
			out.add("parent", parent);
		}
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {

		id = (String) object.get("id");
		actives = (Object[]) object.get("actives");
		attacks = (Object[]) object.get("attacks");
		passive = (String) object.get("passive");
		statRanges = (Object[]) object.get("stats");
		parent = (String) object.get("parent");
	}

	public StatRange getStatRangeByName(final String name) {
		for (int i = 0; i < statRanges.length; ++i) {
			final StatRange stat = (StatRange) statRanges[i];
			if (stat.stat.equals(name)) {
				return stat;
			}
		}

		return null;
	}

	public AppearanceDef getAppearanceDef(final int variation) {
		if (variation <= 0 || variation >= appearances.length)
		{
			return null;
		}
		return appearances[variation];
	}

}
