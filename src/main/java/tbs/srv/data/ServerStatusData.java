package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class ServerStatusData implements Convertible {

	public int session_count;

	public ServerStatusData() {

	}

	public ServerStatusData(final int session_count) {
		this.session_count = session_count;
	}

	public String toString() {
		return super.toString();
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("session_count", session_count);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		session_count = ((Number) jo.get("session_count")).intValue();
	}
}