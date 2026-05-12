package engine.session
{

	public class ServerStatusData
	{
		public var session_count : int;
		public var msg : String;

		public function ServerStatusData()
		{
		}

		public function toString() : String
		{
			return "[" + session_count + ", " + msg + "]";
		}

		public static function parse(vars : Object) : ServerStatusData
		{
			var data : ServerStatusData = new ServerStatusData;
			data.session_count = vars.session_count;
			return data;
		}
	}
}
