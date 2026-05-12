package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class ResetStatsTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/roster/unit/stats/reset";

		public function ResetStatsTxn(credentials : Credentials, callback : Function, logger : ILogger, unitId : String)
		{
			var body : Object =
				{
					unit_id: unitId
			}

			super(PATH + credentials.urlCred, HttpRequestMethod.POST, body, callback, logger);
		}

	}
}
