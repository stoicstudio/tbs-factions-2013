package engine.session
{
	import flash.events.EventDispatcher;

	import engine.core.logging.ILogger;

	public class AlertManager extends EventDispatcher
	{
		public var alerts : Vector.<Alert> = new Vector.<Alert>;
		public var logger : ILogger;
		private var _enabled : Boolean = true;

		public function AlertManager(logger : ILogger)
		{
			this.logger = logger;
		}

		public function get enabled() : Boolean
		{
			return _enabled;
		}

		public function set enabled(value : Boolean) : void
		{
			if (_enabled == value)
			{
				return
			}
			_enabled = value;

			dispatchEvent(new AlertEvent(AlertEvent.ALERTS_ENABLED, null));
		}

		public function addAlert(alert : Alert) : void
		{
			alerts.push(alert);
			alert.addEventListener(AlertEvent.ALERT_RESPONSE, alertResponseHandler);
			dispatchEvent(new AlertEvent(AlertEvent.ALERT_ADDED, alert));
		}

		public function removeAlert(alert : Alert) : void
		{
			const index : int = alerts.indexOf(alert);
			if (index >= 0)
			{
				alerts.splice(index, 1);
				alert.removeEventListener(AlertEvent.ALERT_RESPONSE, alertResponseHandler);

				dispatchEvent(new AlertEvent(AlertEvent.ALERT_REMOVED, alert));
			}
		}

		private function alertResponseHandler(event : AlertEvent) : void
		{
			dispatchEvent(new AlertEvent(event.type, event.alert));

			if (event.alert.removeOnResponse)
			{
				if (event.alert.response)
				{
					removeAlert(event.alert);
				}
			}
		}

		public function getAlertByStyle(style : AlertStyleType) : Alert
		{
			for each (var a : Alert in alerts)
			{
				if (a.style == style)
				{
					return a;
				}
			}

			return null;
		}
	}
}
