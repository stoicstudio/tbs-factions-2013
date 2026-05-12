package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class TutorialCompletedTxn extends HttpJsonAction
	{
		public function TutorialCompletedTxn(credentials : Credentials, callback : Function, logger : ILogger)
		{
			super("services/account/tutorial" + credentials.urlCred, HttpRequestMethod.POST, null, callback, logger);
		}

		override protected function handleJsonResponseProcessing() : void
		{
			consumedTxn = true;
		}

	}
}
