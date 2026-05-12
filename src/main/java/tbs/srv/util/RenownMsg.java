package tbs.srv.util;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

public class RenownMsg extends ReliableMsg {

	public long user;
	public int total;

	public RenownMsg() {

	}

	public RenownMsg(long user, int total) {
		super();
		this.user = user;
		this.total = total;
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);
		out.add("user_id", user);
		out.add("total", total);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		super.fromJSON(jo);
		user = ((Number) jo.get("user_id")).longValue();
		total = ((Number) jo.get("total")).intValue();
	}

	protected String constructReliableMsgId() {
		return "renown_" + user + "_" + timestamp + "_" + total;
	}
}