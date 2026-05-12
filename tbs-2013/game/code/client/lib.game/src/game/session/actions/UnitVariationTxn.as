package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.entity.def.IEntityDef;
	import engine.session.Credentials;

	public class UnitVariationTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/roster/unit/variation";

		private var unit : IEntityDef;
		private var variation : int;

		public function UnitVariationTxn(credentials : Credentials, callback : Function, logger : ILogger, unit : IEntityDef, variation : int, lobby_id : int)
		{
			this.unit = unit;
			this.variation = variation;

			super(PATH + credentials.urlCred + "/" + unit.id + "/" + variation + "/" + lobby_id, HttpRequestMethod.POST, body, callback, logger);

			resendOnFail = true;
			resendOnFailDelayMs = 1000;
		}

		override protected function handleJsonResponseProcessing() : void
		{
			consumedTxn = true;

			if (success)
			{
				unit.appearanceIndex = variation;

			}
		}

	}
}
