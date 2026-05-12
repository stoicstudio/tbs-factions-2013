package tbs.srv.util
{
	import engine.core.locale.Locale;
	import engine.session.Iap;

	public class IapMkt
	{
		public var categories : Vector.<IapMktCat> = new Vector.<IapMktCat>;
		public var boosts : Vector.<String> = new Vector.<String>;
		public var special : String;

		public function IapMkt(json : Object, locale : Locale) : void
		{

			for each (var catv : Object in json.categories)
			{
				const cat : IapMktCat = new IapMktCat(catv, locale);
				categories.push(cat);
			}

			for each (var boost : String in json.boosts)
			{
				boosts.push(boost);
			}

			special = json.special;
		}

		public function findPageForItem(id : String) : IapMktCatPage
		{
			for each (var cat : IapMktCat in categories)
			{
				const page : IapMktCatPage = cat.findPageForItem(id);
				if (page)
				{
					return page;
				}
			}
			return null;
		}
	}
}
