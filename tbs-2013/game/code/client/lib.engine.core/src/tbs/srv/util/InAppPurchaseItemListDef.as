package tbs.srv.util
{
	import flash.utils.Dictionary;

	import engine.ability.def.AbilityDefFactory;
	import engine.core.locale.Locale;
	import engine.core.logging.ILogger;
	import engine.entity.def.EntityClassDefList;
	import engine.entity.def.EntityDefVars;
	import engine.entity.def.IEntityDef;

	public class InAppPurchaseItemListDef implements IIapItemListDef
	{
		private var items : Dictionary = new Dictionary;
		private var currencies : Dictionary = new Dictionary;
		private var _mkt : IapMkt;
		private var units : Dictionary = new Dictionary;
		private var logger : ILogger;

		public function InAppPurchaseItemListDef(json : Object, locale : Locale, logger : ILogger, abf : AbilityDefFactory, cls : EntityClassDefList)
		{
			this.logger = logger;

			for each (var iv : Object in json.items)
			{
				const item : InAppPurchaseItemDef = new InAppPurchaseItemDef(iv, locale);
				items[item.id] = item;
			}

			for each (var cv : Object in json.currencies)
			{
				const cd : InAppPurchaseCurrencyDef = new InAppPurchaseCurrencyDef(cv);
				currencies[cd.id] = cd;
			}

			for each (var puv : Object in json.units)
			{
				const e : IEntityDef = new EntityDefVars(locale).fromJson(puv, logger, abf, cls, true);
				units[e.id] = e;
			}

			_mkt = new IapMkt(json.marketplace, locale);
		}

		public function get mkt() : IapMkt
		{
			return _mkt;
		}

		public function getUnit(id : String) : IEntityDef
		{
			return units[id];
		}

		public function getItem(id : String) : InAppPurchaseItemDef
		{
			return items[id];
		}

		public function getPrice(usd_cents : int, cid : String, sale : Boolean) : int
		{
			if (cid == "USD")
			{
				return usd_cents;
			}

			const cd : InAppPurchaseCurrencyDef = currencies[cid];
			if (!cd)
			{
				logger.error("Unsupported currency: " + cid);
				return -1;
			}

			const converted : Number = usd_cents / cd.conversion;
//			if (sale)
//			{
//				const rounded : int = 100 * (Math.ceil(converted / 100) as int);
//				const psycho : int = rounded - 1;
//				return psycho;
//			}

			return converted;
		}

		public function getItemPrice(item : InAppPurchaseItemDef, cid : String, sale : Boolean) : int
		{
			return getPrice(item.usd_cents, cid, sale);
		}

		public function findItemsByUnlock(unlock_id : String) : Vector.<InAppPurchaseItemDef>
		{
			const r : Vector.<InAppPurchaseItemDef> = new Vector.<InAppPurchaseItemDef>;
			for each (var item : InAppPurchaseItemDef in items)
			{
				if (item.unlocks.indexOf(unlock_id) >= 0)
				{
					r.push(item);
				}
			}
			return r;
		}
	}
}
