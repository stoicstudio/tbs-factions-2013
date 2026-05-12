package game.session.states
{
	import flash.events.Event;

	import engine.core.RunMode;
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;

	import game.cfg.GameConfig;
	import game.session.GameState;
	import game.session.actions.VsType;
	import game.session.states.tutorial.TutorialStartState;
	import game.session.states.tutorial.TutorialTownLoadState;

	public class FactionsState extends GameState
	{
		public function FactionsState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			if (!credentials.valid || !credentials.displayName || !credentials.userId || !credentials.sessionKey)
			{
				logger.info("FactionsState not logged in, going back to auth");
				data.setValue(GameStateDataEnum.AUTH_REQUIRE, true);
				config.fsm.transitionTo(PreAuthState, data);
				return;
			}

			config.addEventListener(GameConfig.EVENT_FACTIONS, factionsHandler);
			config.loadFactions();
		}

		private function factionsHandler(event : Event) : void
		{
			if (!config.runMode.town || config.runMode == RunMode.KIOSK)
			{
				data.setValue(GameStateDataEnum.BATTLE_TIMER_SECS, 45);
				data.setValue(GameStateDataEnum.VERSUS_TYPE, VsType.QUICK);

				config.fsm.transitionTo(VersusFindMatchState, data);
				return;
			}

			if (!config.fsm.session.credentials.offline)
			{
				if (config.options.startInVersus)
				{
					const timer : int = config.options.overrideTurnLengthSecs >= 0 ? config.options.overrideTurnLengthSecs : 30;
					data.setValue(GameStateDataEnum.BATTLE_TIMER_SECS, timer);
					data.setValue(GameStateDataEnum.FORCE_OPPONENT_ID, config.options.versusForceOpponentId);
					data.setValue(GameStateDataEnum.VERSUS_TOURNEY_ID, config.options.versusForceTourneyId);
					data.setValue(GameStateDataEnum.VERSUS_TYPE, VsType.RANKED);
					config.fsm.transitionTo(VersusFindMatchState, data);
					return;
				}
			}

			if (config.options.testTutorial)
			{
				TutorialStartState.staticSetup(config);
				config.fsm.transitionTo(TutorialTownLoadState, data);
				return;
			}

			if (!config.accountInfo.completed_tutorial)
			{
				if (!config.fsm.credentials.offline)
				{
					config.fsm.transitionTo(TutorialStartState, data);
					return;
				}
			}

			phase = StatePhase.COMPLETED;
		}

	}
}
