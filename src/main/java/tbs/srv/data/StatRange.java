package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class StatRange implements Convertible {
	public String stat;
	public int min;
	public int max;

	public StatRange() {

	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("stat", stat);
		out.add("min", min);
		out.add("max", max);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {
		this.stat = (String) object.get("stat");
		this.min = ((Number) object.get("min")).intValue();
		this.max = ((Number) object.get("max")).intValue();
	}

	public String toString() {
		return "[" + stat + " (" + min + ", " + max + ")]";
	}

	public int lerp(final float t) {
		return min + (int) ((max - min) * t);
	}

	public boolean validate(final int value) {
		return value >= min && value <= max;
	}

	public int clamp(final int value) {
		return Math.max(min, Math.min(max, value));
	}
}