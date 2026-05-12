package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.util.ICharacterClassProvider;

public class PurchasableUnitsData implements Convertible {

	public String id;
	public Object[] units;

	public PurchasableUnitsData() {

	}

	public PurchasableUnitsData(Map<String, Object> data, final ICharacterClassProvider provider) {

		id = (String) data.get("id");
		final Object[] uj = (Object[]) data.get("units");
		units = new Object[uj.length];
		for (int i = 0; i < uj.length; ++i) {
			Object srj = uj[i];
			@SuppressWarnings("unchecked")
			Map<String, Object> rm = (Map<String, Object>) srj;
			units[i] = new PurchasableUnitData(rm, provider);
		}

	}

	public PurchasableUnitData get(final String id) {
		for (int i = 0; i < units.length; ++i) {
			final PurchasableUnitData pu = (PurchasableUnitData) units[i];
			if (pu.def.id.equals(id)) {
				return pu;
			}
		}

		return null;
	}

	public String toString() {
		return super.toString();
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("units", units);
		out.add("id", id);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		units = (Object[]) jo.get("units");
		id = (String) jo.get("id");
	}
}