package tbs.srv.util;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

abstract public class ReliableMsg implements Convertible {

	private String reliable_msg_id;
	public String reliable_msg_target;
	public long requeue_time;
	public long timestamp = System.currentTimeMillis();
	public boolean kill;

	public ReliableMsg() {

	}

	public ReliableMsg(final String reliable_msg_id) {
		this.reliable_msg_id = reliable_msg_id;

	}

	public String toString() {
		return getClass().getSimpleName() + " " + getReliableMsgId();
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("reliable_msg_id", getReliableMsgId());
		out.add("reliable_msg_target", reliable_msg_target);
		out.add("timestamp", timestamp);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		reliable_msg_id = (String) jo.get("reliable_msg_id");
		reliable_msg_target = (String) jo.get("reliable_msg_target");
		if (jo.containsKey("timestamp")) {
			timestamp = ((Number) jo.get("timestamp")).longValue();
		}
	}

	public String getReliableMsgId() {
		if (reliable_msg_id == null) {
			reliable_msg_id = constructReliableMsgId();
		}

		return reliable_msg_id;
	}

	abstract protected String constructReliableMsgId();
}