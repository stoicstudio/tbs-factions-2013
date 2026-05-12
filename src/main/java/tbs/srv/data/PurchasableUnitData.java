package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.util.ICharacterClassProvider;

public class PurchasableUnitData implements Convertible {

	public EntityDef def;
	public int limit;
	public int cost;
	public String comment;

	public PurchasableUnitData() {

	}

	public PurchasableUnitData(final EntityDef def, final int limit, final int cost, final String comment) {
		this.def = def;
		this.limit = limit;
		this.cost = cost;
		this.comment = comment;
	}

	public PurchasableUnitData(Map<String, Object> data, final ICharacterClassProvider provider) {

		@SuppressWarnings("unchecked")
		final Map<String, Object> defm = (Map<String, Object>) data.get("def");
		def = new EntityDef(defm, provider);
		limit = ((Number) data.get("limit")).intValue();
		cost = ((Number) data.get("cost")).intValue();
		comment = (String) data.get("comment");
	}

	public String toString() {
		return super.toString();
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("def", def);
		out.add("limit", limit);
		out.add("cost", cost);
		if (comment != null) {
			out.add("comment", comment);
		}
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		def = (EntityDef) jo.get("def");
		limit = ((Number) jo.get("limit")).intValue();
		cost = ((Number) jo.get("cost")).intValue();
		comment = (String) jo.get("comment");
	}
}