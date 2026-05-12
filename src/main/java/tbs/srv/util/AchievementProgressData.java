package tbs.srv.util;

import java.util.Arrays;
import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class AchievementProgressData implements Convertible {

	public long account_id;
	public long session_key;
	public AchievementType achievement_type;
	public int delta;
	public int total; // the total progress after the change
	public Object[] acquired; // array of achievement ids acquired by this change
	public String handle; // battle_id.uniquenumber
	public String battle_id;

	public AchievementProgressData() {

	}

	public String toString() {

		return "AchievementProgressData[account_id = " + account_id + ", session_id = " + session_key + ", achievement_type = " + achievement_type.name()
				+ ", delta = " + delta + ", total = " + total + ", acquired = " + Arrays.toString(acquired) + ", handle = " + handle + "]";
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());

		out.add("account_id", account_id);
		out.add("session_key", session_key);
		out.add("achievement_type", achievement_type.name());
		out.add("delta", delta);
		out.add("total", total);
		out.add("acquired", acquired);
		out.add("handle", handle);
		out.add("battle_id", battle_id);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {

		account_id = ((Number) object.get("account_id")).longValue();
		session_key = ((Number) object.get("session_key")).longValue();
		achievement_type = AchievementType.valueOf((String) object.get("achievement_type"));
		delta = ((Number) object.get("delta")).intValue();
		total = ((Number) object.get("total")).intValue();
		acquired = (Object[]) object.get("acquired");

		handle = object.get("handle").toString();
		battle_id = (String) object.get("battle_id");

	}

}
