package tbs.srv.util;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;

public class BattleSceneListDef {

	public final static Logger logger = Logger.getLogger(BattleSceneListDef.class.getSimpleName());

	public List<BattleSceneListItemDef> tests = new ArrayList<BattleSceneListItemDef>();
	public List<BattleSceneListItemDef> items = new ArrayList<BattleSceneListItemDef>();
	public float totalWeight = 0;

	public BattleSceneListDef(@SuppressWarnings("rawtypes") Map json) {

		Object[] scenes = (Object[]) json.get("scenes");

		for (Object so : scenes) {
			@SuppressWarnings("rawtypes")
			final BattleSceneListItemDef item = new BattleSceneListItemDef((Map) so);
			addItem(item);
		}
	}

	public String toString() {
		return "BattleSceneListDef [count=" + items.size() + ", weight=" + totalWeight + ", tests=" + tests.size() + "]";
	}

	private void addItem(BattleSceneListItemDef item) {
		if (!item.test) {
			items.add(item);
			totalWeight += item.weight;
		} else {
			tests.add(item);
		}
	}

	public BattleSceneListItemDef getRandom() {

		float r = (float) (Math.random() * totalWeight);
		float w = 0;
		BattleSceneListItemDef result = null;

		for (int i = 0; i < items.size(); ++i) {
			final BattleSceneListItemDef item = items.get(i);
			if (r > w && item.weight != 0 && !item.test) {
				result = item;
			} else {
				break;
			}
			w += item.weight;
		}

		return result;
	}
}
