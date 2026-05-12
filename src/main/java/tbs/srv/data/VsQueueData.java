package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class VsQueueData implements Convertible {

	public String type;
	public long account_id;
	public Object[] powers;
	public Object[] counts;

	public VsQueueData() {

	}

	public VsQueueData(String type, long account_id, Object[] powers, Object[] counts) {
		this.account_id = account_id;
		this.type = type;
		this.powers = powers;
		this.counts = counts;
	}

	public String toString() {
		return "VsQueueData " + type;
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("type", type);
		out.add("account_id", account_id);
		out.add("powers", powers);
		out.add("counts", counts);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		type = (String) jo.get("type");
		account_id = ((Number) jo.get("account_id")).longValue();
		powers = (Object[]) jo.get("powers");
		counts = (Object[]) jo.get("counts");
	}
}