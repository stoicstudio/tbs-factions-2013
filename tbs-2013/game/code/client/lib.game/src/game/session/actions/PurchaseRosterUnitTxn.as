package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class PurchaseRosterUnitTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/roster/unit/hire";

		public function PurchaseRosterUnitTxn(credentials : Credentials, callback : Function, logger : ILogger, purchasable_unit_id : String, new_unit_id : String, new_unit_name : String)
		{
			var body : Object =
				{
					purchasable_unit_id: purchasable_unit_id,
					new_unit_id: new_unit_id,
					new_unit_name : new_unit_name
			}

			super(PATH + credentials.urlCred, HttpRequestMethod.POST, body, callback, logger);

			resendOnFail = true;
		}

		override protected function handleJsonResponseProcessing() : void
		{
			consumedTxn = true;
		}
	}
}
