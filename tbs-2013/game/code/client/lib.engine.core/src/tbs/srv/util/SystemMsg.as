package tbs.srv.util
{
	import engine.core.logging.ILogger;

	public class SystemMsg extends ReliableMsg
	{
		public var msg : String;

		public function SystemMsg()
		{
		}

		override public function parseJson(json : Object, logger : ILogger) : void
		{
			super.parseJson(json, logger);
			msg = json.msg;
		}
	}
}

