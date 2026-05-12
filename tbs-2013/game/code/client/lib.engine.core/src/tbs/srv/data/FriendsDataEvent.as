package tbs.srv.data
{
	import flash.events.Event;

	public class FriendsDataEvent extends Event
	{
		public static const CHANGED : String = "FriendsDataEvent.CHANGED";
		public static const INIT : String = "FriendsDataEvent.INIT";

		public var friend : FriendData;

		public function FriendsDataEvent(type : String, fd : FriendData)
		{
			super(type);
			this.friend = fd;
		}
	}
}
