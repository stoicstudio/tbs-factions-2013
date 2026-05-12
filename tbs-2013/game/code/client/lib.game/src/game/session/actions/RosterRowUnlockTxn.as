package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;
	
	import game.cfg.AccountInfoDef;

	public class RosterRowUnlockTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/roster/unlock";

		private var ai : AccountInfoDef;

		public function RosterRowUnlockTxn(credentials : Credentials, callback : Function, logger : ILogger, ai : AccountInfoDef)
		{
			this.ai = ai;
			super(PATH + credentials.urlCred, HttpRequestMethod.POST, body, callback, logger);

			resendOnFail = true;
			resendOnFailDelayMs = 1000;
		}

		override protected function handleJsonResponseProcessing() : void
		{
			consumedTxn = true;

			if (success)
			{
				++ai.legend.rosterRowCount;
			}
		}

	}
}
