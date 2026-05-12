package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class TourneyJoinTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/tourney/join";

		public var tourney_id : int;

		public function TourneyJoinTxn(credentials : Credentials, callback : Function, logger : ILogger, tourney_id : int)
		{
			this.tourney_id = tourney_id;

			const body : Object =
				{
					tourney_id: tourney_id
				};

			super(PATH + credentials.urlCred, HttpRequestMethod.POST, body, callback, logger);

			this.resendOnFail = true;
		}

		override protected function handleJsonResponseProcessing() : void
		{
			consumedTxn = true;
			if (success)
			{

			}
		}
	}
}
