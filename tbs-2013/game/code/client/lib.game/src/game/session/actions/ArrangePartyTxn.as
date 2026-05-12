package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class ArrangePartyTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/roster/party/arrange";

		public function ArrangePartyTxn(credentials : Credentials, callback : Function, logger : ILogger, partymembers : Vector.<String>, lobby_id : int)
		{
			var body : Object =
				{
					party: []
				};

			for each (var pid : String in partymembers)
			{
				body.party.push(pid);
			}

			if (lobby_id)
			{
				body.lobby = lobby_id;
			}

			super(PATH + credentials.urlCred, HttpRequestMethod.POST, body, callback, logger);

			resendOnFail = true;
			resendOnFailDelayMs = 1000;
		}

		override protected function handleJsonResponseProcessing() : void
		{
			consumedTxn = true;
		}

	}
}
