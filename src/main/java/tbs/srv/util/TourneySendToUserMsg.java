package tbs.srv.util;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class TourneySendToUserMsg implements Convertible {

	public static final String KEY = "TourneySendToUserMsg";

	public long account_id;
	public long request_time;

	@Override
	public String toString() {
		return "TourneySendToUserMsg [account_id=" + account_id + "]";
	}

	public TourneySendToUserMsg() {

	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("account_id", account_id);
		out.add("request_time", request_time);
	}

	@SuppressWarnings("rawtypes")
	@Override
	public void fromJSON(Map object) {
		account_id = ((Number) object.get("account_id")).longValue();
		request_time = ((Number) object.get("request_time")).longValue();
	}

	public TourneySendToUserMsg(final long account_id) {
		super();
		this.account_id = account_id;
		this.request_time = System.currentTimeMillis();
	}

}
