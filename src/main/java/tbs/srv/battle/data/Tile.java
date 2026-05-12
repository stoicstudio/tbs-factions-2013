package tbs.srv.battle.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class Tile implements Convertible {

	public int x;
	public int y;

	public Tile() {

	}

	public Tile(int x, int y) {
		super();
		this.x = x;
		this.y = y;
	}

	public String toString() {
		return "[" + x + ", " + y + "]";
	}

	public Tile(Number x, Number y) {
		this(x.intValue(), y.intValue());
	}

	public Tile(Map<String, Object> dt) {
		this((Number) dt.get("x"), (Number) dt.get("y"));
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("x", x);
		out.add("y", y);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {
		x = ((Number) object.get("x")).intValue();
		y = ((Number) object.get("y")).intValue();
	}
}