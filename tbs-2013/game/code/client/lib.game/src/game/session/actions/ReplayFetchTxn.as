package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.session.Credentials;
	
	import game.cfg.GameConfig;

	public class ReplayFetchTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/battle/replay";

		public function ReplayFetchTxn(credentials : Credentials, battle_id : String, callback : Function, config : GameConfig)
		{
			var body : Object = {};

			body.battle_id = battle_id;

			super(PATH + credentials.urlCred, HttpRequestMethod.POST, body, callback, config.logger);

			resendOnFail = true;
			resendOnFailDelayMs = 1000;
		}
	}
}
