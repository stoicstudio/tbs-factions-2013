package tbs.srv.chat;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class ChatMsg implements Convertible {

	public long user;
	public String room;
	public String username;
	public String msg;

	public ChatMsg() {

	}

	@Override
	public String toString() {
		return "ChatMsg [" + user + "/" + room + "/" + username + "/" + msg + "]";
	}

	public ChatMsg(long user, String room, String username, String message) {
		this.username = username;
		this.room = room;
		this.user = user;
		this.msg = message;
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("user", user);
		out.add("msg", msg);
		out.add("room", room);
		out.add("username", username);
	}

	@SuppressWarnings("rawtypes")
	@Override
	public void fromJSON(Map object) {

		user = ((Number) object.get("user")).longValue();
		room = (String) object.get("room");
		username = (String) object.get("username");
		msg = (String) object.get("msg");
	}
}