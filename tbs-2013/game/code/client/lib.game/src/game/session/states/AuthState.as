package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;
	
	import game.session.GameState;
	import game.session.actions.AuthTxn;

	public class AuthState extends GameState
	{
		private var action : AuthTxn;

		public function AuthState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleCleanup() : void
		{
			if (action)
			{
				action.abort();
				action = null;
			}
		}

		override protected function handleEnteredState() : void
		{
			credentials.offline = false;
			communicator.connected = false;

			if (gameFsm.config.options.alwaysOffline)
			{
				phase = StatePhase.COMPLETED;
				return;
			}
			
			action = new AuthTxn(credentials, config.client_language, authCallbackHandler, config.logger);
			logger.info("AuthState AUTHENTICATING " + communicator.hostUrl + ", " + credentials.vbb_name + ": " + credentials.childNumber + " steam=" + credentials.steamId);
			action.send(communicator);
		}

		private static const LOCAL_BUILD_NUMBER : String = "locally";

		private function authCallbackHandler(action : AuthTxn) : void
		{
			//logger.debug("AuthState authCallbackHandler " + action);

			if (action != this.action)
			{
				//logger.debug("AuthState authCallbackHandler ignoring old action response");
				// this is an old action response, just ignore it
				return;
			}

			const auth_require : Boolean = data.getValue(GameStateDataEnum.AUTH_REQUIRE);

			if (action && action.success && action.jsonObject)
			{
				config.systemMessage.msg = action.jsonObject.system_msg;
				communicator.connected = true;

				if (action.buildNumber != config.context.appInfo.buildVersion)
				{
					logger.info("Server build number is " + action.buildNumber + ", but ours is " + config.context.appInfo.buildVersion + ", seeking confirmation");
					if (config.context.appInfo.buildVersion != LOCAL_BUILD_NUMBER && action.buildNumber != LOCAL_BUILD_NUMBER)
					{
						this.action = null;
						data.setValue(GameStateDataEnum.BUILD_NUMBER, action.buildNumber);

						if (auth_require)
						{
							gameFsm.transitionTo(AuthBuildMismatchState, data);
						}
						else
						{
							phase = StatePhase.COMPLETED;
						}
						return;
					}
				}

				if (!credentials.valid || !credentials.displayName || !credentials.userId || !credentials.sessionKey)
				{
					logger.error("Invalid credentials: " + credentials);
					data.setValue(GameStateDataEnum.SERVER_MESSAGE, "Invalid Credentials");
					phase = StatePhase.FAILED;
					return;
				}

				phase = StatePhase.COMPLETED;
			}
			else if (action.canRetry)
			{
				if (auth_require)
				{
					action.resend(communicator, 5000);
				}
				else
				{
					phase = StatePhase.COMPLETED;
				}
			}
			else
			{
				this.action.abort();
				this.action = null;
				data.setValue(GameStateDataEnum.SERVER_MESSAGE, action.message);
				if (auth_require)
				{
					phase = StatePhase.FAILED;
				}
				else
				{
					phase = StatePhase.COMPLETED;
				}
			}
		}

	}
}
