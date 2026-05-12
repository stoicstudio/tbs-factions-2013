package tbs.srv.util
{
	import engine.core.logging.ILogger;

	public class UnitAddData
	{
		public var account_id : int;
		public var unitv : Object;

		public function UnitAddData()
		{
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			account_id = json.account_id;
			unitv = json.unit; // parsed but untranslated json object
		}
	}
}
