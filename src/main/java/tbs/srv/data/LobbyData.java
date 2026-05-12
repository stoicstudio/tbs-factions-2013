package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class LobbyData implements Convertible {

	public static enum Type {
		INVITE, UNINVITE, JOIN, DECLINE, EXIT, READY, UNREADY, OPTIONS, PARTY, VARIATION, TERMINATED
	};

	public long lobby_id;
	public long account_id;
	public String account_display_name;
	public String type;

	public LobbyData() {

	}

	public LobbyData(final long lobby_id, final long account_id, final String account_display_name, final Type type) {

		this.lobby_id = lobby_id;
		this.account_id = account_id;
		this.account_display_name = account_display_name;
		this.type = type.name();
	}

	public String toString() {
		return "LobbyData [lobby_id=" + lobby_id + " account_id=" + account_id + " type=" + type + "]";

	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("lobby_id", lobby_id);
		out.add("account_id", account_id);
		if (account_display_name != null) {
			out.add("account_display_name", account_display_name);
		}
		out.add("type", type);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		lobby_id = ((Number) jo.get("lobby_id")).longValue();
		account_id = ((Number) jo.get("account_id")).longValue();
		type = (String) jo.get("type");
		account_display_name = (String) jo.get("account_display_name");
	}

}