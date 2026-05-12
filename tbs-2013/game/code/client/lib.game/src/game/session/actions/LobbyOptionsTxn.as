package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	import tbs.srv.data.LobbyOptionsData;

	public class LobbyOptionsTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/lobby/options";

		public function LobbyOptionsTxn(credentials : Credentials, logger : ILogger, options : LobbyOptionsData)
		{
			super(PATH + credentials.urlCred, HttpRequestMethod.POST, JSON.stringify(options), null, logger);
			this.resendOnFail = true;
		}

	}
}
