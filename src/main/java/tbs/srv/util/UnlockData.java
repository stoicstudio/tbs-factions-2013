package tbs.srv.util;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class UnlockData implements Convertible {

	public long account_id;
	public String unlock_id;
	public long unlock_time;
	public long unlock_duration;

	public UnlockData() {

	}

	public UnlockData(ResultSet rs) throws SQLException {

		account_id = rs.getLong("account_id");
		unlock_id = rs.getString("unlock_id");
		unlock_time = rs.getLong("unlock_time");
		unlock_duration = rs.getLong("unlock_duration");
	}

	public UnlockData(long account_id, String unlock_id, long unlock_time, long unlock_duration) {
		super();
		this.account_id = account_id;
		this.unlock_id = unlock_id;
		this.unlock_time = unlock_time;
		this.unlock_duration = unlock_duration;
	}

	@Override
	public String toString() {
		return "UnlockData [account_id=" + account_id + ", unlock_id=" + unlock_id + ", unlock_time=" + unlock_time + ", unlock_duration=" + unlock_duration
				+ "]";
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("account_id", account_id);
		out.add("unlock_id", unlock_id);
		out.add("unlock_time", unlock_time);
		out.add("unlock_duration", unlock_duration);

	}

	@SuppressWarnings("rawtypes")
	@Override
	public void fromJSON(Map object) {
		account_id = ((Number) object.get("account_id")).longValue();
		unlock_id = (String) object.get("unlock_id");
		unlock_time = ((Number) object.get("unlock_time")).longValue();
		unlock_duration = ((Number) object.get("unlock_duration")).longValue();
	}

}
