package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class FriendOnlineData implements Convertible {

	public long account_id;
	public boolean online;

	public FriendOnlineData(final long account_id, final boolean online) {

		this.account_id = account_id;
		this.online = online;
	}

	public FriendOnlineData() {

	}

	public String toString() {
		return "FriendOnlineData [account_id=" + account_id + " online=" + online + "]";
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("account_id", account_id);
		out.add("online", online);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		account_id = ((Number) jo.get("account_id")).longValue();
		online = (Boolean) jo.get("online");
	}
}