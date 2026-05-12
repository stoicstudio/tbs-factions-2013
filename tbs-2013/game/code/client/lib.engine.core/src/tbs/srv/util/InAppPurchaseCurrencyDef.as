package tbs.srv.util
{

	public class InAppPurchaseCurrencyDef
	{
		public var id : String;
		public var conversion : Number;

		public function InAppPurchaseCurrencyDef(json : Object)
		{
			this.id = json.id;
			this.conversion = json.conversion;
		}
	}
}
