package tbs.srv.metrics.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.data.ClientConfigData;

public class MetricsSessionStartedData implements Convertible {
	public long userid;
	public String ipaddress;
	public String username;
	public long sessionid;
	public long time;
	public ClientConfigData client_config;

	public MetricsSessionStartedData() {

	}

	public MetricsSessionStartedData(final long userid, final String ipaddress, final String display_name, final long session_key,
			final ClientConfigData client_config) {
		this.userid = userid;
		this.ipaddress = ipaddress;
		this.username = display_name;
		this.sessionid = session_key;
		this.time = System.currentTimeMillis();
		this.client_config = client_config;
	}

	@Override
	public String toString() {
		return "MetricsSessionStartedData [userid=" + userid + ", ipaddress=" + ipaddress + ", username=" + username + ", sessionid=" + sessionid + ", time="
				+ time + ", client_config=" + client_config + "]";
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("userid", userid);
		out.add("ipaddress", ipaddress);
		out.add("display_name", username);
		out.add("sessionid", sessionid);
		out.add("time", time);
		out.add("client_config", client_config);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {
		userid = ((Number) object.get("userid")).longValue();
		ipaddress = (String) object.get("ipaddress");
		username = (String) object.get("display_name");
		sessionid = ((Number) object.get("sessionid")).longValue();
		time = ((Number) object.get("time")).longValue();
		client_config = (ClientConfigData) object.get("client_config");
	}

}
