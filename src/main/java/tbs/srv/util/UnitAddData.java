package tbs.srv.util;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.data.EntityDef;

public class UnitAddData implements Convertible {

	public long account_id;
	public EntityDef unit;

	public UnitAddData() {

	}

	@Override
	public String toString() {
		return "UnitAddData [account_id=" + account_id + ", unit=" + unit + "]";
	}

	public UnitAddData(long account_id, final EntityDef unit) {
		super();
		this.account_id = account_id;
		this.unit = unit;

		if (unit == null) {
			throw new IllegalArgumentException("No unit!");
		}
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("account_id", account_id);
		out.add("unit", unit);

	}

	@SuppressWarnings({ "rawtypes", "unchecked" })
	@Override
	public void fromJSON(Map object) {
		account_id = ((Number) object.get("account_id")).longValue();
		final Object o = object.get("unit");
		if (o instanceof EntityDef) {
			unit = (EntityDef) o;
		} else {
			unit = new EntityDef((Map<String, Object>) o, GameConfig.instance);
		}
	}

}
