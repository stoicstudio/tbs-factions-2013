package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class RenameUnitTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/roster/unit/rename";

		public function RenameUnitTxn(credentials : Credentials, callback : Function, logger : ILogger, unitId : String, name : String)
		{
			var body : Object =
				{
					unit_id: unitId,
					name: name
				};

			super(PATH + credentials.urlCred, HttpRequestMethod.POST, body, callback, logger);
		}

		override protected function handleJsonResponseProcessing() : void
		{
			consumedTxn = true;
		}
	}
}
