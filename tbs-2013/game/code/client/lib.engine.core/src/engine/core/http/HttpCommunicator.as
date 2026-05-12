package engine.core.http
{

	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	import engine.core.logging.ILogger;

	public class HttpCommunicator extends EventDispatcher
	{
		private var m_logger : ILogger;
		private var m_hostUrl : String;
		private var txnProcessedCallback : Function;
		private var txnPollCallback : Function;
		private var _pollTimeMs : int = DEFAULT_POLL_TIME;
		private var _connected : Boolean;

		private static const DEFAULT_POLL_TIME : int = 3000;

		public var errorState : HttpErrorState;

		public function HttpCommunicator(logger : ILogger, hostUrl : String, txnProcessedCallback : Function, txnPollCallback : Function)
		{
			m_logger = logger;
			m_hostUrl = hostUrl;
			this.txnProcessedCallback = txnProcessedCallback;
			this.txnPollCallback = txnPollCallback;
			errorState = new HttpErrorState(logger);

			logger.info("HttpCommunicator hostUrl=" + hostUrl);
		}

		public function request(url : String, method : HttpRequestMethod, body : Object, responseCallback : Function) : HttpRequest
		{
			if (!method)
			{
				throw new ArgumentError("fail method");
			}

			return new HttpRequest(m_hostUrl + url, method, body,
				function(data : *, ok : Boolean, status : int) : void
				{
					if (status == 0 || (status >= 401 && status != 500))
					{
						errorState.noticeError();
					}
					else
					{
						errorState.noticeOk();
					}
					responseCallback(data, ok, status);
				}, m_logger);

		}

		final public function requestGet(url : String, body : Object, responseCallback : Function) : HttpRequest
		{
			return request(m_hostUrl + url, HttpRequestMethod.GET, body, responseCallback);
		}

		final public function requestPost(url : String, body : Object, responseCallback : Function) : HttpRequest
		{
			return request(m_hostUrl + url, HttpRequestMethod.POST, body, responseCallback);
		}

		public function get logger() : ILogger
		{
			return m_logger;
		}

		public function get hostUrl() : String
		{
			return m_hostUrl;
		}

		public function set hostUrl(value : String) : void
		{
			m_hostUrl = value;
		}

		public function onHttpTxnResponseProcessed(txn : HttpAction) : void
		{
			if (!_connected && !txn.isMaintenance)
			{
				// silently discard these
				return;
			}

			if (txnProcessedCallback != null)
			{
				txnProcessedCallback(txn);
			}

			checkPoll();

			dispatchEvent(new HttpTxnResponseProcessedEvent(txn));
		}

		private function get pollTimeMs() : int
		{
			return _pollTimeMs;
		}

		private function set pollTimeMs(value : int) : void
		{
			if (_pollTimeMs == value)
			{
				return;
			}

			_pollTimeMs = value;

//			logger.debug("HttpCommunicator.pollTimeMs=" + value);
			checkPoll();
		}

		private var txnFetch : HttpJsonAction;

		private function checkPoll() : void
		{
			if (txnFetch && !txnFetch.sent)
			{
				txnFetch.abort();
				txnFetch = null;
			}

			if (!_connected || _pollTimeMs <= 0)
			{
				return;
			}

			if (txnPollCallback != null)
			{
				txnFetch = txnPollCallback();

				if (txnFetch)
				{
					txnFetch.send(this, fetchHandler, _pollTimeMs);
				}
			}
		}

		private function fetchHandler(txn : HttpJsonAction) : void
		{
			checkPoll();

		}

		public function get connected() : Boolean
		{
			return _connected;
		}

		public function set connected(value : Boolean) : void
		{
			if (_connected == value)
			{
				return;
			}

			_connected = value;

			checkPoll();
		}

		private var polltimes : Dictionary = new Dictionary;

		public function setPollTimeRequirement(id : Object, ms : int) : void
		{
			polltimes[id] = ms;
			resetPollTime();
		}

		public function removePollTimeRequirement(id : Object) : void
		{
			delete polltimes[id];
			resetPollTime();
		}

		private function resetPollTime() : void
		{
			var min : int = DEFAULT_POLL_TIME;

			for each (var ms : int in polltimes)
			{
				if (ms > 0 && ms < min)
				{
					min = ms;
				}
			}

			pollTimeMs = min;

		}

	}
}
