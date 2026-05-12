package tbs.srv.util
{
	import engine.core.logging.ILogger;

	public class ReliableMsg
	{
		public var reliable_msg_id : int;
		public var reliable_msg_target : String;
		public var timestamp : Number;

		public function ReliableMsg()
		{
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			reliable_msg_id = json.reliable_msg_id;
			reliable_msg_target = json.reliable_msg_target;
			timestamp = json.timestamp;
		}
	}
}
