package tbs.srv.util;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class SteamUserLoadMsg implements Convertible {

	public static final String KEY = "SteamUserLoadMsg";

	public long account_id;
	public long session_key;
	public long steam_id;
	public String language;

	@Override
	public String toString() {
		return "SteamUserLoadMsg [account_id=" + account_id + ", steam_id=" + steam_id + ", language=" + language + ", session=" + session_key + "]";
	}

	public SteamUserLoadMsg() {

	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("account_id", account_id);
		out.add("steam_id", steam_id);
		out.add("language", language);
		out.add("session_key", session_key);
	}

	@SuppressWarnings("rawtypes")
	@Override
	public void fromJSON(Map object) {
		account_id = ((Number) object.get("account_id")).longValue();
		steam_id = ((Number) object.get("steam_id")).longValue();
		language = (String) object.get("language");
		session_key = ((Number) object.get("session_key")).longValue();
	}

	public SteamUserLoadMsg(final long account_id, final long session_key, final long steam_id, final String language) {
		super();
		this.account_id = account_id;
		this.steam_id = steam_id;
		this.language = language;
		this.session_key = session_key;
	}

}
