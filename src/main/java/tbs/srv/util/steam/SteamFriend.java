package tbs.srv.util.steam;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class SteamFriend implements Convertible {
	public long steamid;
	public String relationship;
	public long friend_since;

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("steamid", steamid);
		out.add("relationship", relationship);
		out.add("friend_since", friend_since);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {
		steamid = ((Number) object.get("steamid")).longValue();
		relationship = (String) object.get("relationship");
		friend_since = ((Long) object.get("friend_since")).longValue();
	}

	public void fromSteamJSON(@SuppressWarnings("rawtypes") Map object) {
		steamid = Long.parseLong((String) object.get("steamid"));
		relationship = (String) object.get("relationship");
		friend_since = ((Long) object.get("friend_since")).longValue();
	}

}
