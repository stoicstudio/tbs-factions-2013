package tbs.srv.data
{
	import engine.core.logging.ILogger;

	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	public class FriendsData extends EventDispatcher
	{
		public var friends : Vector.<FriendData> = new Vector.<FriendData>;
		public var byId : Dictionary = new Dictionary;
		private var logger : ILogger;
		public var initialized : Boolean;

		public function FriendsData(logger : ILogger)
		{
			this.logger = logger;
		}

		public function addFriendData(fd : FriendData, suppressEvent : Boolean = false) : void
		{
			const old : FriendData = byId[fd.id];
			if (old)
			{
				byId[fd.id] = fd;
				const index : int = friends.indexOf(fd);
				friends[index] = fd;

//				logger.debug("addFriend REPLACE " + fd);
				if (!suppressEvent)
				{
					dispatchEvent(new FriendsDataEvent(FriendsDataEvent.CHANGED, fd));
				}
			}
			else
			{
//				logger.debug("addFriend APPEND  " + fd);
				byId[fd.id] = fd;
				friends.push(fd);
			}
		}

		public function updateLocation(gld : GameLocationData) : void
		{
			const old : FriendData = byId[gld.account_id];
			if (old)
			{
				if (old.location != gld.location || !old.online)
				{
					old.location = gld.location;
					old.online = true;
					dispatchEvent(new FriendsDataEvent(FriendsDataEvent.CHANGED, old));
				}
			}
		}

		public function updateOnline(fod : FriendOnlineData) : FriendData
		{
			return setOnline(fod.account_id, fod.online);
		}

		public function setOnline(account_id : int, online : Boolean) : FriendData
		{
			const old : FriendData = byId[account_id];
			if (old)
			{
				if (old.online != online)
				{
					old.online = online;
					dispatchEvent(new FriendsDataEvent(FriendsDataEvent.CHANGED, old));
				}
			}
			return old;
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			// json is a friend array

			const wasInitialized : Boolean = initialized;
			initialized = true;

			for each (var fj : Object in json.friends)
			{
				var fd : FriendData = byId[fj.id];
				if (!fd)
				{
					fd = new FriendData;
				}

				fd.parseJson(fj, logger);

				addFriendData(fd, !wasInitialized);
			}

			if (!wasInitialized)
			{
				dispatchEvent(new FriendsDataEvent(FriendsDataEvent.INIT, null));
			}
		}
	}
}
