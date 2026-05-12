package engine.session
{
	import engine.core.logging.ILogger;

	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class Credentials extends EventDispatcher
	{
		public static const EVENT_COMMITTED : String = "Credentials.EVENT_COMMITTED";
		public static const EVENT_VALIDATION : String = "Credentials.EVENT_VALIDATION";
		public static const EVENT_SESSION : String = "Credentials.EVENT_SESSION";

		private var _vbb_name : String
		private var _gameServerUrl : String;
		public var offline : Boolean;
		private var _valid : Boolean;
		private var _sessionKey : String;
		public var logger : ILogger;
		public var userId : int;
		public var password : String;
		public var steamId : String;
		public var steamAuthTicketHandle : int;
		public var steamAuthTicket : String;
		public var childNumber : int;
		public var displayName : String;

		public var protocolVersion : int;

		public function Credentials(vbb_name : String, childNumber : int, url : String, protocolVersion : int, logger : ILogger)
		{
			this.protocolVersion = protocolVersion;
			this._vbb_name = vbb_name;
			this._gameServerUrl = url;
			this.logger = logger;
			this.childNumber = childNumber;
		}

		public function commit() : void
		{
			validate();
			if (valid)
			{
				dispatchEvent(new Event(EVENT_COMMITTED));
			}
		}

		public function validate() : void
		{
			valid = checkValidity();
		}

		public function checkValidity() : Boolean
		{
			if (_gameServerUrl)
			{
				if (_vbb_name && password)
				{
					return true;
				}

				if (steamId && steamAuthTicket)
				{
					return true;
				}
				
				if (sessionKey && userId)
				{
					return true;
				}
			}

			return false;
		}

		public function get valid() : Boolean
		{
			return _valid;
		}

		public function set valid(value : Boolean) : void
		{
			if (_valid != value)
			{
				_valid = value;
				dispatchEvent(new Event(EVENT_VALIDATION));
			}
		}

		public function get vbb_name() : String
		{
			return _vbb_name;
		}

		public function set vbb_name(value : String) : void
		{
			_vbb_name = value;
			validate();
		}

		public function get gameServerUrl() : String
		{
			return _gameServerUrl;
		}

		public function set gameServerUrl(value : String) : void
		{
			_gameServerUrl = value;
			validate();
		}

		public function get sessionKey() : String
		{
			return _sessionKey;
		}

		public function set sessionKey(value : String) : void
		{
			if (_sessionKey == value)
			{
				return;
			}

			_sessionKey = value;

			logger.info("Credentials.sessionKey " + userId + " " + vbb_name + " " + displayName + " " + sessionKey);

			validate();
			
			dispatchEvent(new Event(EVENT_SESSION));
		}

		public function get urlCred() : String
		{
			return "/" + sessionKey;
		}

	}
}
