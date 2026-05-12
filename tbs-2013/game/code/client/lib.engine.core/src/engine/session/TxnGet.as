package engine.session
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;

	public class TxnGet extends HttpJsonAction
	{
		public static const PATH : String = "services/game";

		public function TxnGet(cred : Credentials, callback : Function, logger : ILogger)
		{
			super(PATH + cred.urlCred, HttpRequestMethod.GET, null, callback, logger);
		}

	}
}
