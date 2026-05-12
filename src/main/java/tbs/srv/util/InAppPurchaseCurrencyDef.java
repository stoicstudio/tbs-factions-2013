package tbs.srv.util;

import java.util.Map;

public class InAppPurchaseCurrencyDef {

	public String id;
	public float conversion;

	public InAppPurchaseCurrencyDef(@SuppressWarnings("rawtypes") Map json) {
		id = (String) json.get("id");
		conversion = ((Number) json.get("conversion")).floatValue();
	}
}
