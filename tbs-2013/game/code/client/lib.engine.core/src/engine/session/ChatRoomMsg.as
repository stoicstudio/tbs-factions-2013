package engine.session
{
	import engine.core.logging.ILogger;

	public class ChatRoomMsg
	{
		public var display_name : String;
		public var room : String;
		public var entered : Boolean;
		public var exited : Boolean;

		public function ChatRoomMsg()
		{
		}

		public function toString() : String
		{
			return "ChatRoomMsg [" + display_name + " " + room + " " + (entered ? "entered" : (exited ? "exited" : "???")) + "]";
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			display_name = json.display_name;
			room = json.room;
			entered = json.entered;
			exited = json.exited;
		}
	}
}
