package tbs.srv.util;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;

import org.apache.log4j.Logger;

import tbs.srv.data.EntityDef;

public class InAppPurchaseItemListDef {

	public final static Logger logger = Logger.getLogger(InAppPurchaseItemListDef.class.getSimpleName());
	public HashMap<String, InAppPurchaseItemDef> items = new HashMap<String, InAppPurchaseItemDef>();
	public HashMap<String, InAppPurchaseCurrencyDef> currencies = new HashMap<String, InAppPurchaseCurrencyDef>();
	public HashMap<String, EntityDef> units = new HashMap<String, EntityDef>();

	public HashMap<Integer, String> steam_dlc_items = new HashMap<Integer, String>();
	public HashSet<Integer> steam_dlc_appids = new HashSet<Integer>();

	public InAppPurchaseItemListDef(@SuppressWarnings("rawtypes") Map json) {

		{
			final Object[] itemvs = (Object[]) json.get("items");

			for (Object so : itemvs) {
				@SuppressWarnings("rawtypes")
				final InAppPurchaseItemDef item = new InAppPurchaseItemDef((Map) so);
				addItem(item);
			}
		}

		{
			final Object[] currencyvs = (Object[]) json.get("currencies");

			for (Object so : currencyvs) {
				@SuppressWarnings("rawtypes")
				final InAppPurchaseCurrencyDef currency = new InAppPurchaseCurrencyDef((Map) so);
				currencies.put(currency.id, currency);
			}
		}

		{
			final Object[] unitvs = (Object[]) json.get("units");

			for (Object unitv : unitvs) {
				@SuppressWarnings("unchecked")
				final EntityDef unit = new EntityDef((Map<String, Object>) unitv, GameConfig.instance);
				units.put(unit.id, unit);
			}
		}

		{
			final Object[] itemvs = (Object[]) json.get("steam_dlcs");

			for (Object so : itemvs) {
				@SuppressWarnings("unchecked")
				final Map<String, Object> item = (Map<String, Object>) so;
				final int appid = ((Number) item.get("appid")).intValue();
				final String iapid = (String) item.get("iap");

				steam_dlc_items.put(appid, iapid);
				steam_dlc_appids.add(appid);

				if (!items.containsKey(iapid)) {
					throw new IllegalArgumentException("Invalid DLC " + appid + " iap " + iapid);
				}
			}
		}

	}

	public String toString() {
		return "InAppPurchaseItemDef [count=" + items.size() + "]";
	}

	private void addItem(InAppPurchaseItemDef item) {
		items.put(item.id, item);
	}

	public InAppPurchaseItemDef getItem(final String id) {
		return items.get(id);
	}

	public EntityDef getUnit(final String id) {
		return units.get(id);
	}

	public int getPrice(final InAppPurchaseItemDef item, final String currency, final boolean sale) {

		final int usd_cents = sale ? item.sale_usd_cents : item.usd_cents;
		if ("USD".equals(currency)) {
			return usd_cents;
		}

		final InAppPurchaseCurrencyDef cd = currencies.get(currency);
		if (cd == null) {
			logger.error("Unsupported currency: " + currency);
			return -1;
		}

		final float converted = usd_cents / cd.conversion;
		// if (sale) {
		// final int rounded = 100 * (int) Math.ceil(converted / 100);
		// final int psycho = rounded - 1; // buck-99 etc
		// return psycho;
		// }

		return (int) converted;
	}

	public int convertToUsdCents(final String currency, final int amount) {
		if ("USD".equals(currency)) {
			return amount;
		}

		final InAppPurchaseCurrencyDef cd = currencies.get(currency);
		if (cd == null) {
			logger.error("Unsupported currency: " + currency);
			return -1;
		}

		final float converted = amount * cd.conversion;
		return (int) converted;
	}
}
