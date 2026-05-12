package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	import game.gui.IGuiDialog;
	import game.session.GameState;

	import tbs.srv.battle.data.client.BattleCreateData;

	public class StartState extends GameState
	{
		public function StartState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			if (config.steamworks.enabled && !config.steamworks.initialized)
			{
				const dialog : IGuiDialog = config.gameGuiContext.createDialog();
				dialog.openDialog("Steam Error", "Steam was unable to initialize The Banner Saga.\nTry each of the following:\n1. Restart Steam\n2. Re-install The Banner Saga\n3.Re-install Steam", "Ok",
					steamFailHandler);
				phase = StatePhase.FAILED;
				return;
			}

			if (config.options.overrideSteamId)
			{
				credentials.steamId = config.options.overrideSteamId;
				credentials.displayName = "∏" + config.options.overrideSteamId;
			}
			else
			{
				credentials.steamId = config.steamworks.SteamUser_GetSteamID();

				config.client_language = config.steamworks.SteamApps_GetCurrentGameLanguage();

				if (!credentials.steamId)
				{
					logger.info("StartState.handleEnteredState $$ NO STEAM ID");
				}
				else
				{
					const accountId : int = config.steamworks.SteamID_GetAccountId(credentials.steamId);
					logger.info("StartState.handleEnteredState $$ STEAM ID=" + credentials.steamId + ", account " + accountId);
					credentials.displayName = config.steamworks.SteamFriends_GetPersonaName();
				}
			}

			if (config.options.startInCombat)
			{
				logger.info("StartState.handleEnteredState $$ starting in combat");
				const bcd : BattleCreateData = new BattleCreateData;
				bcd.scene = config.options.startInCombat;

				data.setValue(GameStateDataEnum.BATTLE_CREATE_DATA, bcd);
				data.setValue(GameStateDataEnum.SCENE_URL, config.options.startInCombat);
				data.setValue(GameStateDataEnum.LOCAL_PARTY, config.legend.party.getEntityListDef());
				data.setValue(GameStateDataEnum.LOCAL_TIMER_SECS, 0);

				config.fsm.transitionTo(SceneLoadState, data);
				return;
			}

			logger.info("StartState.handleEnteredState $$ showing login screen and completing");

			data.setValue(GameStateDataEnum.AUTOLOGIN, true);
			phase = StatePhase.COMPLETED;
		}

		private function steamFailHandler(b : String) : void
		{
			config.context.appInfo.exitGame("Steam could not initialize");
		}

	}
}
