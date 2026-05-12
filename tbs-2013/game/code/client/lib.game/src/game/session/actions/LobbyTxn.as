package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class LobbyTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/lobby/";

		public function LobbyTxn(credentials : Credentials, logger : ILogger, op : String, arg : int)
		{
			super(PATH + op + credentials.urlCred, HttpRequestMethod.POST, arg.toString(), null, logger);
			this.resendOnFail = true;
		}
	}
}
