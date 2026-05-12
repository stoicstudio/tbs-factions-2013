package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	public class AuthTxn extends HttpJsonAction
	{
		public var credentials : Credentials;
		public var buildNumber : String;

		public function AuthTxn(credentials : Credentials, client_language : String, callback : Function, logger : ILogger)
		{
			this.credentials = credentials;

			var body : Object =
				{
					username: credentials.vbb_name,
					password: credentials.password,
					child_number: credentials.childNumber,
					steam_id: credentials.steamId,
					steam_auth_ticket: credentials.steamAuthTicket,
					display_name: credentials.displayName,
					client_config: new ClientConfigData(client_language)
				};

			super("services/auth/login/" + credentials.protocolVersion, HttpRequestMethod.POST, body, callback, logger);
		}

		override protected function handleJsonResponseProcessing() : void
		{
			if (jsonObject)
			{
				consumedTxn = true;

				if (!jsonObject.session_key)
				{
					logger.error("AuthAction no sessionKey for " + credentials.vbb_name);
				}

				if (!jsonObject.user_id)
				{
					logger.error("AuthAction no userId for " + credentials.vbb_name);
				}

				credentials.userId = jsonObject.user_id;
				credentials.vbb_name = jsonObject.vbb_name;
				credentials.displayName = jsonObject.display_name;

				// set session key last
				credentials.sessionKey = jsonObject.session_key;

				buildNumber = jsonObject.build_number;

				logger.info("Assigned SessionKey " + credentials.sessionKey);
			}

		}

		public function get steamCredentials() : String
		{
			// TBD
			return jsonObject.steamCredentials;
		}

	}
}
