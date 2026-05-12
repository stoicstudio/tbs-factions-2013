package tbs.srv.util;

import java.util.Map;

public class InAppPurchaseItemDef {

	public String id;
	public int id_hash;
	public int usd_cents;
	public boolean enabled;
	public String category;
	public boolean sale;
	public int sale_usd_cents;

	public int renown;
	public Object[] unlocks = new Object[0];
	public Object[] units = new Object[0];
	public int roster_rows = 0;

	public int days = 0;

	public String[] iaps = new String[0];

	public static final int MAX_ID_LEN = 32;

	public String toString() {
		return id;
	}

	public InAppPurchaseItemDef(@SuppressWarnings("rawtypes") Map json) {
		id = (String) json.get("id");
		if (id.length() > MAX_ID_LEN) {
			throw new IllegalArgumentException("Id too long: " + id);
		}

		id_hash = Math.abs(id.hashCode());
		usd_cents = ((Number) json.get("usd_cents")).intValue();

		if (json.containsKey("enabled")) {
			enabled = ((Boolean) json.get("enabled"));
		}

		category = (String) json.get("category");

		if (json.containsKey("renown")) {
			renown = ((Number) json.get("renown")).intValue();
		}

		if (json.containsKey("unlocks")) {
			unlocks = (Object[]) json.get("unlocks");
		}

		if (json.containsKey("units")) {
			units = (Object[]) json.get("units");
		}

		if (json.containsKey("days")) {
			days = ((Number) json.get("days")).intValue();
		}

		if (json.containsKey("roster_rows")) {
			roster_rows = ((Number) json.get("roster_rows")).intValue();
		}

		if (json.containsKey("sale")) {
			sale = ((Boolean) json.get("sale")).booleanValue();
		}

		if (json.containsKey("sale_usd_cents")) {
			sale_usd_cents = ((Number) json.get("sale_usd_cents")).intValue();
		}

		if (json.containsKey("iaps")) {
			final Object[] iapj = (Object[]) json.get("iaps");
			iaps = new String[iapj.length];
			System.arraycopy(iapj, 0, iaps, 0, iapj.length);
		}
	}
}
