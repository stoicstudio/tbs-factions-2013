package tbs.srv.db.models;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class SessionExpiryData implements Convertible {

	public Long session_key;
	public Long account_id;

	public SessionExpiryData() {

	}

	public SessionExpiryData(Long session_key, Long account_id) {
		super();
		this.session_key = session_key;
		this.account_id = account_id;
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("session_key", session_key);
		out.add("account_id", account_id);

	}

	@SuppressWarnings("rawtypes")
	@Override
	public void fromJSON(Map object) {
		session_key = (Long) object.get("session_key");
		account_id = (Long) object.get("account_id");

	}

}
