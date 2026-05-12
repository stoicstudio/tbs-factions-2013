package tbs.srv.util;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;

import org.apache.log4j.Logger;

public class SteamDlcDef {

	public final static Logger logger = Logger.getLogger(SteamDlcDef.class.getSimpleName());

	public HashMap<Integer, String> steam_dlc_items = new HashMap<Integer, String>();
	public HashSet<Integer> steam_dlc_appids = new HashSet<Integer>();

	public SteamDlcDef(@SuppressWarnings("rawtypes") Map json) {

		final Object[] itemvs = (Object[]) json.get("dlcs");

		for (Object so : itemvs) {
			@SuppressWarnings("unchecked")
			final Map<String, Object> item = (Map<String, Object>) so;
			final int appid = ((Number) item.get("appid")).intValue();
			final String iapid = (String) item.get("iap");

			steam_dlc_items.put(appid, iapid);
			steam_dlc_appids.add(appid);
		}
	}

}
