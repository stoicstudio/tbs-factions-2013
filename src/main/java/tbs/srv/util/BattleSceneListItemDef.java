package tbs.srv.util;

import java.util.Map;

public class BattleSceneListItemDef {
	public String id;
	public float weight;
	public boolean test;

	public BattleSceneListItemDef(@SuppressWarnings("rawtypes") Map json) {
		id = (String) json.get("id");
		weight = ((Number) json.get("weight")).floatValue();
		if (json.containsKey("test")) {
			test = (Boolean) json.get("test");
		}
	}
}
