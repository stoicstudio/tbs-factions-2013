package tbs.srv.vs.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.util.VsType;

public class VsFindData implements Convertible {
	public long user;
	public long session_key;
	public String display_name;
	public Object[] partyIds;
	public long forcematch;
	public String scene;
	public int match_handle;
	public int timer;
	public VsType type;
	public int tourney_id;

	public VsFindData() {

	}

	@Override
	public String toString() {
		return "VsFindData [" + //
				user + "/" + session_key + "/" + display_name + "/h=" + match_handle + " f=" + forcematch + "/t=" + tourney_id + "/s=" + scene + //
				"/y=" + type + "]";
	}

	public VsFindData(final long session_key, long user, final String display_name, Object[] partyIds, long forcematch, String scene, final int timer,
			final VsType type, final int match_handle, final int tourney_id) {
		this.session_key = session_key;
		this.display_name = display_name;
		this.user = user;
		this.partyIds = partyIds;
		this.forcematch = forcematch;
		this.scene = scene;
		this.timer = timer;
		this.match_handle = match_handle;
		this.type = type;
		this.tourney_id = tourney_id;
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("session_key", session_key);
		out.add("user", user);
		out.add("display_name", display_name);
		out.add("partyIds", partyIds);
		out.add("forcematch", forcematch);
		out.add("scene", scene);
		out.add("timer", timer);
		out.add("match_handle", match_handle);
		out.add("type", type.name());
		out.add("tourney_id", tourney_id);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {

		session_key = ((Number) object.get("session_key")).longValue();
		user = ((Number) object.get("user")).longValue();
		display_name = (String) object.get("display_name");
		forcematch = ((Number) object.get("forcematch")).longValue();
		scene = (String) object.get("scene");
		partyIds = (Object[]) object.get("partyIds");
		match_handle = ((Number) object.get("match_handle")).intValue();
		timer = ((Number) object.get("timer")).intValue();
		type = VsType.valueOf((String) object.get("type"));
		tourney_id = ((Number) object.get("tourney_id")).intValue();
	}
}