package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.entity.def.PartyDefVars;
	import engine.session.Credentials;
	
	import game.cfg.GameConfig;

	public class VersusStartMatchTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/vs/start";

		public function VersusStartMatchTxn(credentials : Credentials, opponentId : int, sceneId : String, match_handle : int, timer : int, tourney_id : int, type : VsType, callback : Function, config : GameConfig)
		{
			var body : Object = {};

			body.party = PartyDefVars.save(config.legend.party).ids;
			body.timer = timer;

			if (config.runMode.autologin)
			{
				body.priority = 100;
			}

			if (opponentId != 0)
			{
				body.forcematch = opponentId;
			}

			if (sceneId)
			{
				body.scene = sceneId;
			}

			body.vs_type = type.name;

			body.match_handle = match_handle;
			body.tourney_id = tourney_id;

			super(PATH + credentials.urlCred, HttpRequestMethod.POST, body, callback, config.logger);

			resendOnFail = true;
			resendOnFailDelayMs = 1000;
		}
	}
}
