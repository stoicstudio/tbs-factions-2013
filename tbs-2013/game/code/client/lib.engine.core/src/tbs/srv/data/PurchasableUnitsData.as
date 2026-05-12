package tbs.srv.data
{
	import engine.core.logging.ILogger;

	public class PurchasableUnitsData
	{
		public static const schema : Object =
			{
				name: "PurchasableUnitsData",
				type: "object",
				properties: {
					id: {type: "string"},
					units: {type: "array", item: PurchasableUnitData.schema},
					"class": {type: "string", optional: true}
				}
			};

		public var id : String;
		public var units : Vector.<PurchasableUnitData> = new Vector.<PurchasableUnitData>;

		public function PurchasableUnitsData()
		{
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			id = json.id;
			for each (var puv : Object in json.units)
			{
				var pud : PurchasableUnitData = new PurchasableUnitData;
				pud.parseJson(puv, logger);
				units.push(pud);
			}
		}
	}
}
