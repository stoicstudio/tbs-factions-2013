package tbs.srv.data
{
	import engine.core.logging.ILogger;

	public class FriendLobbyData
	{
		public var id : int;
		public var members : Vector.<FriendData> = new Vector.<FriendData>;
		public var scene : String;
		public var turn_time : int;

		public function FriendLobbyData()
		{
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			id = json.id;
			scene = json.scene;
			turn_time = json.turn_time;

			for each (var mj : Object in json.members)
			{
				var m : FriendData = new FriendData;
				m.parseJson(mj, logger);
				members.push(m);
			}
		}
	}
}
