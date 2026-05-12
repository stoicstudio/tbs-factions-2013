package engine.session
{

	public class ChatMsg
	{
		public var user : int;
		public var username : String;
		public var room : String;
		public var msg : String;

		public function ChatMsg()
		{
		}

		public function toString() : String
		{
			return username + "/" + room + "/" + msg;
		}

		public static function parse(vars : Object) : ChatMsg
		{
			var msg : ChatMsg = new ChatMsg;
			msg.username = vars.username;
			msg.room = vars.room;
			msg.user = vars.user;
			msg.msg = vars.msg;

			return msg;
		}
	}
}
