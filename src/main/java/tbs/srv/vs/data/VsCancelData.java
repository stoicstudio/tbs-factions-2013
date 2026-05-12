package tbs.srv.vs.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class VsCancelData implements Convertible {
	public long user;
	public int match_handle;

	public VsCancelData() {

	}

	public String toString() {
		return "VsCancelData [" + Long.toString(user) + "]";
	}

	public VsCancelData(long user, final int match_handle) {
		this.user = user;
		this.match_handle = match_handle;
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("user", user);
		out.add("match_handle", match_handle);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {
		user = ((Number) object.get("user")).longValue();
		match_handle = ((Number) object.get("match_handle")).intValue();

	}
}