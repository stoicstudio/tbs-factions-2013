package tbs.srv.util;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class ModifyRenownData implements Convertible {

	public long user;
	public boolean reset;
	public int delta;
	public RenownReason reason;
	public String note;

	@Override
	public String toString() {
		return "ModifyRenownData [user=" + user + ", reset=" + reset + ", delta=" + delta + ", reason=" + reason + ", note=" + note + "]";
	}

	public ModifyRenownData() {

	}

	public ModifyRenownData(long user, final boolean reset, int delta, RenownReason reason, String note) {
		super();
		this.user = user;
		this.reset = reset;
		this.delta = delta;
		this.reason = reason;
		this.note = note;
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("user", user);
		out.add("reset", reset);
		out.add("delta", delta);
		out.add("reason", reason.name());
		out.add("note", note);

	}

	@SuppressWarnings("rawtypes")
	@Override
	public void fromJSON(Map object) {
		user = ((Number) object.get("user")).longValue();
		reset = ((Boolean) object.get("reset")).booleanValue();
		delta = ((Number) object.get("delta")).intValue();
		reason = RenownReason.valueOf((String) object.get("reason"));
		note = (String) object.get("note");
	}

}
