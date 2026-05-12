package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class FriendsData implements Convertible {

	public Object[] friends;

	public FriendsData() {

	}

	public String toString() {
		return super.toString();
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("friends", friends);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		friends = (Object[]) jo.get("friends");
	}
}