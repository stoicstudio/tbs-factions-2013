package engine.core.http
{
	import engine.core.logging.ILogger;

	import flash.errors.IllegalOperationError;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;

	/**
	 * A wrapper for sending/receiving a request/response through an ICommunicator
	 * @author johnwatson
	 *
	 */
	public class HttpAction
	{
		protected var m_url : String;
		private var m_callback : Function;
		private var _overrideCallback : Function;
		private var m_sent : Boolean;
		private var m_response : String;
		private var m_received : Boolean;
		private var m_sendTime : int;
		private var m_responseLatency : int;
		public var logger : ILogger;
		public var success : Boolean;
		public var responseCode : int;
		public var method : HttpRequestMethod;
		public var body : Object;
		private var aborted : Boolean;
		private var _communicator : HttpCommunicator;
		private var _timer : Timer;
		private static const ALLOW_OFFLINE_MOCK : Boolean = true;
		public var delay : int;
		public var txnName : String;
		public var delayStartTime : int;
		protected var resendOnFail : Boolean;
		protected var resendOnFailDelayMs : int = 2000;
		protected var consumedTxn : Boolean;

		/**
		 *
		 * @param url a URL that will be understood by the ICommunicator.  Depending on the ICommunicator, this could be a full or partial url
		 * @param callback called after the response has been received and the result processed
		 *
		 */
		public function HttpAction(url : String, method : HttpRequestMethod, body : Object, callback : Function, logger : ILogger)
		{
			m_url = url;
			m_callback = callback;
			this.logger = logger;
			this.method = method;
			this.body = body;
			txnName = getQualifiedClassName(this);
			txnName = txnName.substr(txnName.lastIndexOf(":") + 1, txnName.length);
		}

		public function resend(hc : HttpCommunicator, delay : int) : void
		{
			m_sent = false;
			success = false;
			responseCode = 0;
			aborted = false;
			m_response = null;
			m_received = false;
			m_responseLatency = 0;

			if (_timer)
			{
				_timer.removeEventListener(TimerEvent.TIMER_COMPLETE, timerCompleteHandler);
				_timer.stop();
				_timer = null;
			}

			send(hc, _overrideCallback, delay);
		}

		/**
		 * @param overrideCallback use this callback instead of the one provided in the constructor, if any
		 *
		 */
		public function send(hc : HttpCommunicator, overrideCallback : Function = null, delay : int = 0) : void
		{
			if (m_sent)
			{
				throw new IllegalOperationError("Return to sender");
			}

			if (overrideCallback != null)
			{
				_overrideCallback = overrideCallback;
			}

			_communicator = hc;

			this.delay = delay;
			if (delay > 0)
			{
				//	logger.debug("HttpAction DELAY " + delay + " " + this);
				delayStartTime = getTimer();
				_timer = new Timer(delay, 1);
				_timer.addEventListener(TimerEvent.TIMER_COMPLETE, timerCompleteHandler);
				_timer.start();
				return;
			}

			doSend();
		}

		public function get delayRemainingTime() : int
		{
			if (delay > 0)
			{
				var elapsed : int = getTimer() - delayStartTime;
				return delay - elapsed;
			}
			return 0;
		}

		private function doSend() : void
		{
			m_sendTime = getTimer();
			m_sent = true;

			//logger.debug("HttpAction SEND " + this);

			if (_communicator)
			{
				var h : HttpRequest = _communicator.request(url, method, body, onResponseReceived);
			}
			else
			{
				if (ALLOW_OFFLINE_MOCK)
				{
					// otherwise, offline it!			
					var paths : Array = url.split("/");
					offlineProcessRequest(paths);
				}
				else
				{
					success = false;
					logger.error("No communicator -- can't send " + this);
					issueCallback();
				}
			}
		}

		public function forceTimerTimeout() : void
		{
			timerCompleteHandler(null);
		}

		private function timerCompleteHandler(event : TimerEvent) : void
		{
			if (_timer)
			{
				_timer = null;
				doSend();
			}
		}

		public function abort() : void
		{
			resendOnFail = false;
			aborted = true;
			m_callback = null;
			if (_timer)
			{
				_timer.stop();
				_timer = null;
			}
		}

		protected function handleAbort() : void
		{

		}

		public function get url() : String
		{
			return m_url;
		}

		public function get response() : String
		{
			if (!m_received)
			{
				throw new IllegalOperationError("No response yet");
			}
			return m_response;
		}

		/**
		 *
		 * @return the time duration between the send and response time, or the elapsed latency so far if the response has not yet been received
		 *
		 */
		public function get latency() : int
		{
			if (!m_received)
			{
				return getTimer() - m_sendTime;
			}

			return m_responseLatency;
		}

		public function get received() : Boolean
		{
			return m_received;
		}

		public function get sent() : Boolean
		{
			return m_sent;
		}

		public function get shouldProcessResponse() : Boolean
		{
			return responseCode != 404;
		}

		public function get debugResponseString() : String
		{
			return m_response ? m_response.substring(0, 500).split("\n").join("") : null;
		}

		protected function onResponseReceived(response : String, ok : Boolean, status : int) : void
		{
			if (aborted)
			{
				logger.debug("Ignoring aborted response for " + this + " " + status + ": " + response);
				return;
			}

			m_response = response;

			if (!ok)
			{
				var msg : String = txnName + " onResponseReceived ERROR url=" + url + " ok=" + ok + " status=" + status + " response=" + debugResponseString;
				logger.info(msg);
			}
			else
			{
				//logger.debug("HttpAction onResponseReceived " + url + " ok=" + ok + " status=" + status + " response=" + debugResponseString);
			}

			if (m_received)
			{
				throw new IllegalOperationError("Redundant response");
			}

			m_responseLatency = getTimer() - m_sendTime;
			m_response = response;
			m_received = true;
			this.success = ok;
			this.responseCode = status;

			if (shouldProcessResponse)
			{
				handleResponseProcessing();
			}

			if (communicator && (!consumedTxn || isMaintenance))
			{
				communicator.onHttpTxnResponseProcessed(this);
			}

			if (null != _overrideCallback)
			{
				_overrideCallback(this);
			}
			else
			{
				issueCallback();
			}

			if (received && !success)
			{
				if (resendOnFail)
				{
					if (canRetry)
					{
						logger.error("Failed to " + this + " with code " + responseCode + ", retrying");
						resend(communicator, resendOnFailDelayMs);
					}
					else
					{
						logger.error("Failed to " + this + " with code " + responseCode + ", WILL NOT RETRY");
					}
				}
			}
		}

		public function issueCallback() : void
		{
			if (!m_received)
			{
				throw new IllegalOperationError("Cannot issue a callback prior to a response!");
			}

			if (null != m_callback)
			{
				m_callback(this);
			}
		}

		/**
		 * Subclasses of CommunicatorAction should override this to provide special handling and interpretation of responses
		 *
		 */
		protected function handleResponseProcessing() : void
		{
		}

		protected function offlineProcessRequest(path : Array) : void
		{
			setOfflineResponse(null, 404);
		}

		// offline stuff

		private var _offlineResponse : String;
		private var _offlineResponseStatus : int;
		public var offlineTimer : Timer;

		public function setOfflineResponse(r : Object, offlineResponseStatus : int) : void
		{
			var s : String = null;

			if (r is String)
			{
				s = r as String;
			}
			else if (r)
			{
				s = JSON.stringify(r);
			}

			_offlineResponse = s;
			this._offlineResponseStatus = offlineResponseStatus;
			offlineTimer = new Timer(100, 1);
			offlineTimer.addEventListener(TimerEvent.TIMER_COMPLETE, offlineTimerHandler);
			offlineTimer.start();
		}

		protected function offlineTimerHandler(event : TimerEvent) : void
		{
			var offlineOk : Boolean = (_offlineResponseStatus >= 200 && _offlineResponseStatus < 300);
			onResponseReceived(_offlineResponse, offlineOk, _offlineResponseStatus);
			offlineTimer = null;
		}

		public function get offlineResponse() : String
		{
			return _offlineResponse;
		}

		public function get overrideCallback() : Function
		{
			return _overrideCallback;
		}

		public function set overrideCallback(value : Function) : void
		{
			_overrideCallback = value;
		}

		public function get communicator() : HttpCommunicator
		{
			return _communicator;
		}

		public function set communicator(value : HttpCommunicator) : void
		{
			_communicator = value;
		}

		public function get canRetry() : Boolean
		{
			if (received && !success && !isMaintenance)
			{
				return responseCode == 0 || responseCode == 404 || responseCode >= 500;
			}

			return false;
		}

		public function get isMaintenance() : Boolean
		{
			if (responseCode == 503)
			{
				// hacky, but i don't think Heroku offers anything more than this
				return response.indexOf("Offline for Maintenance") >= 0 || response.indexOf("game_rebooting") >= 0;
			}

			return false;
		}
	}
}
