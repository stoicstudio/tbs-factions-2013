package tbs.srv.util
{
	import engine.core.locale.Locale;
	import engine.core.locale.LocaleCategory;
	import engine.def.BooleanVars;

	public class InAppPurchaseItemDef
	{
		// display
		public var id : String;
		public var name : String;
		public var category : String;
		public var label : String;
		public var icon : String = "auto";

		// costs
		public var usd_cents : int;
		public var enabled : Boolean;
		public var days : int;
		public var sale : Boolean;
		public var sale_usd_cents : int;
		public var limit : int;

		// purchase results
		public var renown : int;
		public var unlocks : Array = [];
		public var units : Array = [];
		public var roster_rows : int;

		public function InAppPurchaseItemDef(json : Object, locale : Locale)
		{
			this.id = json.id;
			this.usd_cents = json.usd_cents;
			this.enabled = json.enabled;
			this.category = json.category;
			this.renown = json.renown;

			this.sale = BooleanVars.parse(json.sale);

			this.sale_usd_cents = json.sale_usd_cents;

			if (json.unlocks != undefined)
			{
				this.unlocks = json.unlocks;
			}

			if (json.units != undefined)
			{
				this.units = json.units;
			}

			limit = json.limit;

			roster_rows = json.roster_rows;

			if (json.icon != undefined)
			{
				this.icon = json.icon;
			}

			this.days = days;

			this.name = locale.translate(LocaleCategory.IAP, this.id);
			this.label = locale.translate(LocaleCategory.IAP, this.id + "_label");
		}
	}
}
