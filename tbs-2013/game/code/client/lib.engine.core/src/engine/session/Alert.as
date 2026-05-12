package engine.session
{
	import flash.events.EventDispatcher;

	public class Alert extends EventDispatcher
	{
		public static const RESPONSE_OK : String = "OK";
		public static const RESPONSE_CANCEL : String = "CANCEL";
		public static const RESPONSE_EXIT : String = "EXIT";

		public var sender_display_name : String;
		public var sender_id : int;
		public var msg : String;
		public var arrival : int;
		public var _response : String;
		public var data : *;
		public var okMsg : String;
		public var okColor : *;
		public var cancelMsg : String;
		public var orientation : AlertOrientationType;
		public var style : AlertStyleType;
		public var removeOnResponse : Boolean = true;

		public function Alert()
		{
		}

		public static function create(sender_id : int, sender_display_name : String, msg : String, okMsg : String, cancelMsg : String, orientation : AlertOrientationType, style : AlertStyleType, data : *) : Alert
		{
			const a : Alert = new Alert;
			a.sender_id = sender_id;
			a.data = data;
			a.sender_display_name = sender_display_name;
			a.msg = msg;
			a.cancelMsg = cancelMsg;
			a.okMsg = okMsg;
			a.orientation = orientation;
			a.style = style;
			return a;
		}

		public function get response() : String
		{
			return _response;
		}

		public function set response(value : String) : void
		{
			if (_response == value)
			{
				//return;
			}

			_response = value;

			notifyChanged();
			dispatchEvent(new AlertEvent(AlertEvent.ALERT_RESPONSE, this));
		}

		public function notifyChanged() : void
		{
			dispatchEvent(new AlertEvent(AlertEvent.ALERT_CHANGED, this));
		}
	}
}
