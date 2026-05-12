package tbs.srv.util
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;
	import engine.session.Iap;

	public class IapFinalizeTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/iap/finalize";

		public var iap : Iap;

		public function IapFinalizeTxn(credentials : Credentials, callback : Function, logger : ILogger, iap : Iap)
		{
			var body : Object =
				{
					orderid: iap.orderid
				};

			this.iap = iap;
			super(PATH + credentials.urlCred, HttpRequestMethod.POST, body, callback, logger);

			resendOnFail = false;
		}

		override protected function handleJsonResponseProcessing() : void
		{
			consumedTxn = true;

			if (responseCode == 200)
			{
				iap.setComplete();
			}
			else
			{
				iap.setError(response);
			}
		}
	}
}
