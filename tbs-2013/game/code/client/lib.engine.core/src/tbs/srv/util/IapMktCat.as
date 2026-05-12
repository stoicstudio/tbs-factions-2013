package tbs.srv.util
{
	import engine.core.locale.Locale;
	import engine.core.locale.LocaleCategory;

	public class IapMktCat
	{
		public var id : String;
		public var title : String = "";
		public var pages : Vector.<IapMktCatPage> = new Vector.<IapMktCatPage>;

		public function IapMktCat(json : Object, locale : Locale) : void
		{
			this.id = json.id;
			if (!this.id)
			{
				throw new ArgumentError("id is required to be nonempty");
			}

			if (this.id)
			{
				this.title = locale.translate(LocaleCategory.IAP, this.id);
			}

			for each (var pagev : Object in json.pages)
			{
				const page : IapMktCatPage = new IapMktCatPage(pagev, locale);
				pages.push(page);
			}
		}

		public function findPageForItem(id : String) : IapMktCatPage
		{
			for each (var page : IapMktCatPage in pages)
			{
				if (page.items.indexOf(id) >= 0)
				{
					return page;
				}
			}

			return null;
		}
	}
}
