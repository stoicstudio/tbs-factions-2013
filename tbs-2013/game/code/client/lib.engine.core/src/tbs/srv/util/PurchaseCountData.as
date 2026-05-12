package tbs.srv.util
{
	import engine.core.logging.ILogger;

	public class PurchaseCountData
	{
		public static const schema : Object =
			{
				name: "UnlockData",
				type: "object",
				properties: {
					account_id: {type: "number"},
					item_id: {type: "string"},
					purchase_count: {type: "number"}
				}
			};

		public var account_id : int;
		public var item_id : String;
		public var purchase_count : int;

		public function PurchaseCountData()
		{
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			account_id = json.account_id;
			item_id = json.item_id;
			purchase_count = json.purchase_count;
		}
	}
}
