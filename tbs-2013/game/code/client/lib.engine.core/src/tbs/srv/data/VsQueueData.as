package tbs.srv.data
{
	import engine.core.logging.ILogger;

	public class VsQueueData
	{
		public var account_id : int;
		public var type : String;
		public var powers : Array;
		public var counts : Array;

		public function VsQueueData()
		{
		}

		public function toString() : String
		{
			return "VsQueueData: [type=" + type + "]";
		}

		public function parseJson(json : Object, logger : ILogger) : VsQueueData
		{
			account_id = json.account_id;
			type = json.type;
			powers = json.powers;
			counts = json.counts;
			return this;
		}
	}
}
