package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;

	import flash.events.Event;

	import game.session.GameState;

	public class PreAuthState extends GameState
	{
		public function PreAuthState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{

			if (gameFsm.config.options.alwaysOffline)
			{
				phase = StatePhase.COMPLETED;
				return;
			}

			credentials.addEventListener(Credentials.EVENT_COMMITTED, credentialsChangeEvent);
			gameFsm.logout();

			if (credentials.steamId)
			{
				credentials.steamAuthTicketHandle = 1;
				credentials.steamAuthTicket = null;

				if (config.options.overrideSteamId)
				{
					credentials.steamAuthTicket = "override-authticket";
					credentials.commit();
				}
				else
				{
					credentials.steamAuthTicketHandle = config.steamworks.SteamUser_GetAuthSessionTicketHandle();

					if (credentials.steamAuthTicketHandle)
					{
						credentials.steamAuthTicket = config.steamworks.SteamUser_GetAuthSessionTicket(credentials.steamAuthTicketHandle);

						logger.info("PreAuthState.handleEnteredState STEAM TICKET=" + credentials.steamAuthTicketHandle + "/" + credentials.steamAuthTicket);

						if (credentials.steamAuthTicket)
						{
							credentials.commit();
							return;
						}
					}
				}
			}

			if (config.runMode.autologin)
			{
				// is this random enough?
				credentials.vbb_name = "kiosk";
				credentials.password = "kiosk";

				if (Math.random() > 0.5)
				{
					credentials.displayName = config.gameGuiContext.randomMaleName;
				}
				else
				{
					credentials.displayName = config.gameGuiContext.randomFemaleName;
				}

				credentials.commit();
				return;
			}

			data.setValue(GameStateDataEnum.SHOW_LOGIN_SCREEN, true);
		}

		override protected function handleCleanup() : void
		{
			credentials.removeEventListener(Credentials.EVENT_COMMITTED, credentialsChangeEvent);
		}

		protected function credentialsChangeEvent(event : Event) : void
		{
			if (credentials.valid)
			{
				phase = StatePhase.COMPLETED;
			}
		}
	}
}
