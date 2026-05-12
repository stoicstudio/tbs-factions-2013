package tbs.srv.metrics.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class MetricsChatData implements Convertible {

	public long session_key;
	public String chat_room;
	public String chat_msg;

	public MetricsChatData() {

	}

	@Override
	public String toString() {
		return "MetricsChatData [session_key=" + session_key + ", chat_room=" + chat_room + ", chat_msg=" + chat_msg + "]";
	}

	public MetricsChatData(long session_key, String chat_room, String chat_msg) {
		super();
		this.session_key = session_key;
		this.chat_room = chat_room;
		this.chat_msg = chat_msg;
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("session_key", session_key);
		out.add("chat_room", chat_room);
		out.add("chat_msg", chat_msg);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {
		session_key = ((Number) object.get("session_key")).longValue();
		chat_room = (String) object.get("chat_room");
		chat_msg = (String) object.get("chat_msg");
	}

}
