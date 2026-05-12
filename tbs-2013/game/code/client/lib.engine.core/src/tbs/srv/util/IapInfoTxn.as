package tbs.srv.util
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class IapInfoTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/iap/info";

		public function IapInfoTxn(credentials : Credentials, callback : Function, logger : ILogger, msg : String)
		{
			super(PATH + credentials.urlCred, HttpRequestMethod.POST, msg, callback, logger);
			resendOnFail = true;
		}

		override protected function handleJsonResponseProcessing() : void
		{
			consumedTxn = true;
		}
	}
}
