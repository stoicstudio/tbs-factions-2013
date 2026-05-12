package tbs.srv.util
{
	import engine.core.logging.ILogger;

	public class CurrencyData
	{
		public var currency : String;

		public function CurrencyData()
		{
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			currency = json.currency;
		}
	}
}
