package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	import tbs.srv.data.LeaderboardsData;

	public class LeaderboardsTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/game/leaderboards";

		public var boards_data : LeaderboardsData;

		public function LeaderboardsTxn(credentials : Credentials, callback : Function, logger : ILogger, tourney_id : int, board_ids : Array)
		{
			const body : Object =
				{
					tourney_id: tourney_id,
					board_ids: board_ids
				};

			super(PATH + credentials.urlCred, HttpRequestMethod.POST, body, callback, logger);

			this.resendOnFail = true;
		}

		override protected function handleJsonResponseProcessing() : void
		{
			consumedTxn = true;
			if (success && jsonObject)
			{
				boards_data = new LeaderboardsData;
				boards_data.parseJson(jsonObject, logger);
			}
		}
	}
}
