package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class Stat implements Convertible {
	public String stat;
	private int value;
	private boolean dirty;

	public Stat() {

	}

	public Stat(final String stat, final int value) {
		this.stat = stat;
		this.value = value;
		this.dirty = true;
	}

	public void set(final int value) {
		if (this.value != value) {
			this.value = value;
			dirty = true;
		}
	}

	public Stat clone() {
		Stat s = new Stat(stat, value);
		s.clearDirty();
		return s;
	}

	public int get() {
		return value;
	}

	public boolean isDirty() {
		return dirty;
	}

	public void clearDirty() {
		dirty = false;
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("stat", stat);
		out.add("value", value);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {
		this.stat = (String) object.get("stat");
		this.value = ((Number) object.get("value")).intValue();
	}

	public String toString() {
		return "[" + stat + "=" + value + "]";
	}
}