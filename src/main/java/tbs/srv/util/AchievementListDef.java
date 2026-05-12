package tbs.srv.util;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;

public class AchievementListDef {
	public final static Logger logger = Logger.getLogger(AchievementListDef.class.getSimpleName());

	protected List<AchievementListItemDef> items = new ArrayList<AchievementListItemDef>();
	protected Map<String, AchievementListItemDef> id2Item = new HashMap<String, AchievementListItemDef>();

	public AchievementListDef(@SuppressWarnings("rawtypes") Map json) {

		Object[] achievements = (Object[]) json.get("achievements");

		for (Object so : achievements) {
			@SuppressWarnings("rawtypes")
			final AchievementListItemDef item = new AchievementListItemDef((Map) so);

			addItem(item);
		}
	}

	public String toString() {
		return "AchievementListDef [count=" + items.size() + "]";
	}

	private void addItem(AchievementListItemDef item) {

		items.add(item);
		id2Item.put(item.id, item);

	}

	public AchievementListItemDef getItem(String val) {
		return id2Item.get(val);
	}

	public int numItems() {
		return items.size();
	}

	public AchievementListItemDef getItem(int index) {
		if (index >= 0 && index < numItems()) {
			return items.get(index);
		}
		return null;
	}
}
