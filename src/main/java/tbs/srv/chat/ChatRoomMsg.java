package tbs.srv.chat;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class ChatRoomMsg implements Convertible {

	public String room;
	public String display_name;
	public boolean entered;
	public boolean exited;

	public ChatRoomMsg() {

	}

	public ChatRoomMsg(final String room, final String display_name, final boolean entered, final boolean exited) {
		this.room = room;
		this.display_name = display_name;
		this.entered = entered;
		this.exited = exited;
	}

	public String toString() {
		return "ChatRoomMsg [room=" + room + ", display_name=" + display_name + ", entered=" + entered + ", exited=" + exited + "]";
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("room", room);
		out.add("display_name", display_name);
		out.add("entered", entered);
		out.add("exited", exited);
	}

	@SuppressWarnings("rawtypes")
	@Override
	public void fromJSON(Map object) {

		room = (String) object.get("room");
		display_name = (String) object.get("display_name");
		entered = (Boolean) object.get("entered");
		exited = (Boolean) object.get("exited");
	}
}