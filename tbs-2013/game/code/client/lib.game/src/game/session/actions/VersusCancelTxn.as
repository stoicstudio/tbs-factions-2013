package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.session.Credentials;
	
	import game.cfg.GameConfig;

	public class VersusCancelTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/vs/cancel";

		public function VersusCancelTxn(credentials : Credentials, match_handle : int, callback : Function, config : GameConfig)
		{
			super(PATH + credentials.urlCred, HttpRequestMethod.POST, {match_handle: match_handle}, callback, config.logger);
		}
	}
}
