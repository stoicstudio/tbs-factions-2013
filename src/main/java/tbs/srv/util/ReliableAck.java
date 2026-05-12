package tbs.srv.util;

import java.util.Arrays;
import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class ReliableAck implements Convertible {

	public Object[] reliable_msg_ids;
	public String reliable_msg_target;
	public long depool_time;

	public ReliableAck() {

	}

	public ReliableAck(final String target, final Object... ids) {
		this.reliable_msg_target = target;
		this.reliable_msg_ids = ids;
	}

	public String toString() {

		return getClass().getSimpleName() + " target=" + reliable_msg_target + " ids=" + Arrays.toString(reliable_msg_ids);
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("reliable_msg_ids", reliable_msg_ids);
		out.add("reliable_msg_target", reliable_msg_target);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		reliable_msg_ids = (Object[]) jo.get("reliable_msg_ids");
		reliable_msg_target = (String) jo.get("reliable_msg_target");
	}
}