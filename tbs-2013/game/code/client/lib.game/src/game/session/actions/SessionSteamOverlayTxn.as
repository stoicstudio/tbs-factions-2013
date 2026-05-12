package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class SessionSteamOverlayTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/session/steam/overlay";

		public function SessionSteamOverlayTxn(credentials : Credentials, callback : Function, logger : ILogger, overlay : Boolean)
		{
			super(PATH + credentials.urlCred + "/" + overlay, HttpRequestMethod.POST, null, callback, logger);

			this.resendOnFail = true;
		}

		override protected function handleJsonResponseProcessing() : void
		{
			consumedTxn = true;
		}
	}
}
