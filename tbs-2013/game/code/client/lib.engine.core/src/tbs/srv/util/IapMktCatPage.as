package tbs.srv.util
{
	import engine.core.locale.Locale;
	import engine.core.locale.LocaleCategory;

	public class IapMktCatPage
	{
		public var id : String;
		public var title : String = "";
		public var items : Vector.<String> = new Vector.<String>;
		public var menus : Vector.<String> = new Vector.<String>;

		public function IapMktCatPage(json : Object, locale : Locale) : void
		{
			this.id = json.id;
			if (this.id)
			{
				this.title = locale.translate(LocaleCategory.IAP, this.id + "_label");
			}

			for each (var item : String in json.items)
			{
				items.push(item);
			}

			for each (var menu : String in json.menus)
			{
				menus.push(menu);
			}
		}
	}
}
