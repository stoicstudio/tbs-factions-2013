package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class PromoteUnitTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/roster/unit/promote";

		public function PromoteUnitTxn(credentials : Credentials, callback : Function, logger : ILogger, unitId : String, classId : String, name : String)
		{
			var body : Object =
				{
					unit_id: unitId,
					class_id: classId,
					name: name
			}

			super(PATH + credentials.urlCred, HttpRequestMethod.POST, body, callback, logger);
			resendOnFail = true;
		}

	}
}
