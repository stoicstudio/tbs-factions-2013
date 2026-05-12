package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	import tbs.srv.data.LobbyOptionsData;

	public class LobbyInviteTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/lobby/invite";

		public function LobbyInviteTxn(credentials : Credentials, logger : ILogger, options : LobbyOptionsData)
		{
			super(PATH + credentials.urlCred, HttpRequestMethod.POST, JSON.stringify(options), null, logger);
			this.resendOnFail = true;
		}

	}
}
