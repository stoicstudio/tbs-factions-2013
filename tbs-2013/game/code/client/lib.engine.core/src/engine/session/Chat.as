package engine.session
{
	import flash.events.EventDispatcher;

	import engine.core.logging.ILogger;

	import tbs.srv.data.FriendsData;

	public class Chat extends EventDispatcher
	{
		public static const GLOBAL_ROOM : String = "global";
		public static const FRIEND_NOTIFICATION_ROOM : String = "friend_notification";
		public static const LOBBY_ROOM_PREFIX : String = "lobby";

		public var session : Session;
		public var rooms : Vector.<String> = new Vector.<String>;
		private var logger : ILogger;
		private var send : ChatSendTxn;
		private var sent : int;
		private static const SENT_POLL_MS : int = 500;

		private var friends : FriendsData;

		public var globalMsgs : Array = new Array;

		public function Chat(session : Session, friends : FriendsData, logger : ILogger)
		{
			this.session = session;
			this.logger = logger;
			this.friends = friends;
		}

		public function enterRoom(room : String) : void
		{
			rooms.push(room);
		}

		public function exitRoom(room : String) : void
		{
			var index : int = rooms.indexOf(room);
			if (index >= 0)
			{
				rooms.splice(index, 1);
			}
		}

		public function sendMessage(room : String, msg : String) : void
		{
			// listen more quickly when the user has outstanding messages, to reduce the appearance of lag
			++sent;
			session.communicator.setPollTimeRequirement(this, SENT_POLL_MS);
			send = new ChatSendTxn(room, msg, session.credentials, chatSendHandler, logger);
			send.send(session.communicator);
		}

		public function handleChatMsg(msg : ChatMsg) : void
		{
			logger.info("Chat received: " + msg);

			addGlobalMsg(msg);

			dispatchEvent(new ChatEvent(msg));

			--sent;
			if (sent <= 0)
			{
				session.communicator.removePollTimeRequirement(this);
			}

			if (msg.user == session.credentials.userId)
			{

			}
			else
			{
				friends.setOnline(msg.user, true);
			}
		}

		private function addGlobalMsg(msg : Object) : void
		{
			if (msg.room == GLOBAL_ROOM)
			{
				globalMsgs.push(msg);

				const GLOBAL_MSG_LIMIT : int = 100;
				if (globalMsgs.length > GLOBAL_MSG_LIMIT)
				{
					globalMsgs.splice(0, globalMsgs.length - GLOBAL_MSG_LIMIT);
				}
			}
		}

		public function handleChatRoomMsg(msg : ChatRoomMsg) : void
		{
			logger.info("ChatRoomMsg received: " + msg);

			addGlobalMsg(msg);

			dispatchEvent(new ChatRoomEvent(msg));
		}

		private function chatSendHandler(txn : ChatSendTxn) : void
		{
			send = null;
			if (!txn.success)
			{
				logger.info("Chat Send failed, resending...");
				txn.resend(session.communicator, 1000);
			}
		}
	}
}
