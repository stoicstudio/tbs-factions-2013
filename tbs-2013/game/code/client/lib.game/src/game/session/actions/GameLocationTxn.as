package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class GameLocationTxn extends HttpJsonAction
	{
		public function GameLocationTxn(credentials : Credentials, location : String, logger : ILogger)
		{
			super("services/game/location" + credentials.urlCred, HttpRequestMethod.POST, location, null, logger);
			resendOnFail = true;
		}

		override protected function handleJsonResponseProcessing() : void
		{
			consumedTxn = true;
		}

	}
}
