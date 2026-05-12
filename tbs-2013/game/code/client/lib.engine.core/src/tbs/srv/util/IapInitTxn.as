package tbs.srv.util
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;
	import engine.session.Iap;

	public class IapInitTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/iap/init";

		public var iap : Iap;

		public function IapInitTxn(credentials : Credentials, callback : Function, logger : ILogger, iap : Iap, language : String)
		{
			var body : Object =
				{
					overlay: true,
					language: language,
					items: [
					{
							id: iap.item.id,
							qty: 1,
							description: iap.item.name
						}
					]
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
				logger.info("IapInitTxn OK responseCode " + responseCode + " json=" + JSON.stringify(jsonObject));
				iap.setInit(jsonObject.orderid, jsonObject.transid);
				iap.handlePostInit();
			}
			else
			{
				logger.error("IapInitTxn FAIL responseCode " + responseCode);
				iap.setError(response);
			}
		}
	}
}
