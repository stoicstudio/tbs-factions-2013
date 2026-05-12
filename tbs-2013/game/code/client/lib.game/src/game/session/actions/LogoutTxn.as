package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class LogoutTxn extends HttpJsonAction
	{
		public function LogoutTxn(credentials : Credentials, callback : Function, logger : ILogger)
		{
			logger.info("LogoutTxn " + credentials.urlCred);

			var body : Object =
				{
					steam_id: credentials.steamId,
					steam_ticket: credentials.steamAuthTicket
				};

			super("services/auth/logout" + credentials.urlCred, HttpRequestMethod.POST, body, callback, logger);
		}

	}
}
