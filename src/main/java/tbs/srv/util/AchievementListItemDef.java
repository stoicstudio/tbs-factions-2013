package tbs.srv.util;

import java.util.Map;

public class AchievementListItemDef {
	public String id;
	public AchievementType type;
	public int count;
	public String iconurl;
	public int renownrewardamount;

	public AchievementListItemDef(@SuppressWarnings("rawtypes") Map json) {
		id = (String) json.get("id");
		type = AchievementType.valueOf((String) json.get("type"));
		count = ((Number) json.get("count")).intValue();
		iconurl = (String) json.get("iconurl");
		renownrewardamount = ((Number) json.get("renownrewardamount")).intValue();
	}

	public String toString() {
		return "AchievementListItemDef " + id;
	}
}
