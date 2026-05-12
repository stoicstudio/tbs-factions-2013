package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class GameLocationData implements Convertible {

	public long account_id;
	public String location;

	public GameLocationData() {

	}

	public String toString() {
		return super.toString();
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("account_id", account_id);
		out.add("location", location);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		account_id = ((Number) jo.get("account_id")).longValue();
		location = (String) jo.get("location");
	}
}