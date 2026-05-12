package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class PurchaseStatsTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/roster/unit/stats/purchase";

		public function PurchaseStatsTxn(credentials : Credentials, callback : Function, logger : ILogger, unitId : String, stats : Array, deltas : Array)
		{
			var body : Object =
				{
					unit_id: unitId,
					stats: stats,
					deltas: deltas
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
