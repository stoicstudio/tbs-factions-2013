package tbs.srv.data
{
	import engine.core.logging.ILogger;

	public class LobbyOptionsData extends LobbyData
	{
		public var timer : int = 30;
		public var scene : String = null;
		public var display_name : String;
		public var msg : String = "LobbyOptionsData.msg DEFAULT";

		public function LobbyOptionsData()
		{
		}

		override public function parseJson(json : Object, logger : ILogger) : void
		{
			super.parseJson(json, logger);
			timer = json.timer;
			scene = json.scene;
			display_name = json.display_name;
			msg = json.msg;

		}
	}
}
