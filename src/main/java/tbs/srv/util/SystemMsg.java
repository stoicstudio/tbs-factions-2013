package tbs.srv.util;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

public class SystemMsg extends ReliableMsg {

	public String msg;

	public SystemMsg() {

	}

	public SystemMsg(final String msg) {
		super();
		this.msg = msg;
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);
		out.add("msg", msg);
		// String encoded;
		// try {
		// encoded = URLEncoder.encode(msg, "UTF-8");
		// out.add("msg", encoded);
		// } catch (UnsupportedEncodingException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {
		super.fromJSON(object);
		msg = (String) object.get("msg");
		// try {
		// msg = URLDecoder.decode(msg, "UTF-8");
		// } catch (UnsupportedEncodingException e) {
		// // TODO Auto-generated catch block
		// e.printStackTrace();
		// }
	}

	protected String constructReliableMsgId() {
		return "system_" + timestamp;
	}
}