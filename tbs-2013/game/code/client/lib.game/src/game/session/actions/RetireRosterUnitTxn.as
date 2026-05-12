package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class RetireRosterUnitTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/roster/unit/retire";

		public function RetireRosterUnitTxn(credentials : Credentials, callback : Function, logger : ILogger, unit_id : String)
		{
			var body : Object =
				{
					unit_id: unit_id
				};

			super(PATH + credentials.urlCred, HttpRequestMethod.POST, body, callback, logger);

			resendOnFail = true;
		}

		override protected function handleJsonResponseProcessing() : void
		{
			consumedTxn = true;
		}
	}
}
