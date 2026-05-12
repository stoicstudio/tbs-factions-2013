package tbs.srv.util
{
	import engine.core.logging.ILogger;

	import tbs.srv.util.ReliableMsg;

	public class RenownMsg extends ReliableMsg
	{
		public var user : int;
		public var total : int;

		public function RenownMsg()
		{
		}

		override public function parseJson(json : Object, logger : ILogger) : void
		{
			super.parseJson(json, logger);
			user = json.user;
			total = json.total;
		}
	}
}
