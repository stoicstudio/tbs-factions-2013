package game.session.states
{
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.utils.Dictionary;

	import engine.battle.fsm.BattleFinishedData;
	import engine.core.RunMode;
	import engine.core.cmd.CmdExec;
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;
	import engine.entity.def.IEntityListDef;
	import engine.saga.WarOutcome;
	import engine.scene.model.Scene;
	import engine.scene.model.SceneEvent;
	import engine.scene.model.SceneLoader;

	import game.session.GameState;

	public class SceneState extends GameState
	{
		public static const EVENT_CHAT_ENABLED : String = "SceneState.EVENT_CHAT_ENABLED";
		public static const EVENT_CLICKABLES : String = "SceneState.EVENT_CLICKABLES";
		public static const EVENT_BANNER_ENABLED : String = "SceneState.EVENT_BANNER_ENABLED";
		public static const EVENT_HELP_ENABLED : String = "SceneState.EVENT_HELP_ENABLED";
		public static const EVENT_ESCAPE_ENABLED : String = "SceneState.EVENT_ESCAPE_ENABLED";

		public static const EVENT_MATCH_RESOLUTION_SHOW_CONTINUE_BUTTON : String = "SceneState.EVENT_MATCH_RESOLUTION_SHOW_CONTINUE_BUTTON";
		public static const EVENT_WAR_RESOLUTION : String = "SceneState.EVENT_WAR_RESOLUTION";

		public static const inputDataKeys : Array =
			[
			GameStateDataEnum.SCENE_LOADER
			];

		public var loader : SceneLoader;
		public var timer : int; // TODO local_timer_secs
		public var party : IEntityListDef; // TODO local_party
		public var battleHandler : SceneStateBattleHandler;
		public var playerOrder : int;
		public var opponentName : String;
		public var opponentId : int;
		public var battle_bucket : String;
		public var battle_bucket_quota : int;
		public var battle_spawn_tags : String;
		public var battle_deployment : String;
		private var _chatEnabled : Boolean = true;
		private var _allClickablesDisabled : Boolean = false;
		private var _enableClickables : Dictionary = new Dictionary;
		private var _bannerEnabled : Boolean = true;
		private var _helpEnabled : Boolean = true;
		private var _escapeEnabled : Boolean = true;

		public function SceneState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
			shell.add("battle", shellCmdFuncBattle);
		}

		public function isClickableEnabled(id : String) : Boolean
		{
			if (_allClickablesDisabled && !_enableClickables[id])
			{
				return false;
			}
			return true;
		}

		public function get bannerEnabled() : Boolean
		{
			return _bannerEnabled;
		}

		public function set bannerEnabled(value : Boolean) : void
		{
			if (_bannerEnabled != value)
			{
				_bannerEnabled = value;
				dispatchEvent(new Event(EVENT_BANNER_ENABLED));
			}
		}

		public function get helpEnabled() : Boolean
		{
			return _helpEnabled;
		}

		public function set helpEnabled(value : Boolean) : void
		{
			if (_helpEnabled != value)
			{
				_helpEnabled = value;
				dispatchEvent(new Event(EVENT_HELP_ENABLED));
			}
		}

		public function get escapeEnabled() : Boolean
		{
			return _escapeEnabled;
		}

		public function set escapeEnabled(value : Boolean) : void
		{
			if (_escapeEnabled != value)
			{
				_escapeEnabled = value;
				dispatchEvent(new Event(EVENT_ESCAPE_ENABLED));
			}
		}

		public function setClickableEnabled(id : String, value : Boolean) : void
		{
			if (_enableClickables[id] != value)
			{
				_enableClickables[id] = value;
				dispatchEvent(new Event(EVENT_CLICKABLES));
			}
		}

		public function get allClickablesDisabled() : Boolean
		{
			return _allClickablesDisabled;
		}

		public function set allClickablesDisabled(value : Boolean) : void
		{
			if (_allClickablesDisabled == value)
			{
				return;
			}

			_allClickablesDisabled = value;
			dispatchEvent(new Event(EVENT_CLICKABLES));
		}

		public function get chatEnabled() : Boolean
		{
			return _chatEnabled;
		}

		public function set chatEnabled(value : Boolean) : void
		{
			if (_chatEnabled != value)
			{
				_chatEnabled = value;
				dispatchEvent(new Event(EVENT_CHAT_ENABLED));
			}
		}

		override protected function getRequiredInputDataKeys() : Array
		{
			return inputDataKeys;
		}

		override protected function handleEnteredState() : void
		{
			if (!data.hasValue(GameStateDataEnum.SCENE_LOADER))
			{
				throw new IllegalOperationError("data came in without the right stuff");
			}

			loader = data.getValue(GameStateDataEnum.SCENE_LOADER);

			if (!loader.scene)
			{
				throw new IllegalOperationError("Cannot enter scene state without a scene");
			}

			loader.resume();

			party = data.getValue(GameStateDataEnum.LOCAL_PARTY);
			playerOrder = data.getValue(GameStateDataEnum.PLAYER_ORDER);
			opponentName = data.getValue(GameStateDataEnum.OPPONENT_NAME);
			opponentId = data.getValue(GameStateDataEnum.OPPONENT_ID);
			timer = data.getValue(GameStateDataEnum.LOCAL_TIMER_SECS);
			battle_bucket = data.getValue(GameStateDataEnum.BATTLE_BUCKET);
			battle_bucket_quota = data.getValue(GameStateDataEnum.BATTLE_BUCKET_QUOTA);
			battle_spawn_tags = data.getValue(GameStateDataEnum.BATTLE_SPAWN_TAGS);
			battle_deployment = data.getValue(GameStateDataEnum.BATTLE_BUCKET_DEPLOYMENT);

			battleHandler = new SceneStateBattleHandler(this);

			if (data.getValue(GameStateDataEnum.MATCH_RESOLUTION_CONTINUE_ONLY))
			{
				matchResolutionShowContinueButton = true;
			}

			scene.addEventListener(SceneEvent.EXIT, sceneExitHandler);
		}

		protected function sceneExitHandler(event : SceneEvent) : void
		{
			if (config.runMode.town)
			{
				if (data.getValue(GameStateDataEnum.REMATCH))
				{
					config.fsm.transitionTo(VersusFindMatchState, data);
					return;
				}

				const lobby_id : int = data.getValue(GameStateDataEnum.BATTLE_FRIEND_LOBBY_ID);

				if (config.factions && lobby_id == config.factions.lobbyManager.current.options.lobby_id)
				{
					config.factions.lobbyManager.current.ready = false;
					config.fsm.transitionTo(FriendLobbyState, null);
				}
				else
				{
					if (config.saga)
					{
						config.saga.triggerSceneExit(loader.url);
						return;
					}

					// TODO this transition is really only valid in some cases.. certainly not if THIS scene is the town!
					config.fsm.transitionTo(TownLoadState, null);
				}
			}
			else if (config.runMode == RunMode.KIOSK)
			{
				config.context.appInfo.exitGame("SceneState.sceneExitHandler runMode=" + config.runMode);

					//				config.fsm.transitionTo(VersusFindMatchState, data);
			}
			else
			{
				config.fsm.transitionTo(VersusFindMatchState, data);
			}
		}

		public function get scene() : Scene
		{
			return loader.scene;
		}

		override protected function handleCleanup() : void
		{
			scene.exitScene();
			
			scene.removeEventListener(SceneEvent.EXIT, sceneExitHandler);

			super.handleCleanup();
			if (battleHandler)
			{
				battleHandler.cleanup();
				battleHandler = null;
			}

			if (loader)
			{
				if (!data.getValue(GameStateDataEnum.SCENELOADER_PRESERVE))
				{
					// we own the loader, and are authorized to destroy it
					loader.cleanup();
				}
				else
				{
					loader.pause();
				}

				loader = null;
				party = null;
			}
		}

		public function shellCmdFuncBattle(c : CmdExec) : void
		{
			var argv : Array = c.param;

			if (battleHandler && battleHandler.fsm)
			{
				argv = argv.slice(1);
				battleHandler.fsm.shell.execArgv(argv);
			}
			else
			{
				logger.info("Current has no shell handler");
			}
		}

		override public function update(delta : int) : void
		{
			super.update(delta);

			if (phase != StatePhase.ENTERED)
			{
				return;
			}

			if (loader)
			{
				if (loader.scene)
				{
					loader.scene.update(delta);
				}

				// update may have killed the scene
				if (!loader)
				{
					return;
				}

				if (loader.view)
				{
					loader.view.update(delta);
				}
			}

		}

		override public function handleMessage(msg : Object) : Boolean
		{
			if (battleHandler)
			{
				if (battleHandler.fsm)
				{
					return battleHandler.fsm.handleMessage(msg);
				}
			}

			return false;
		}

		public function handleLandscapeClick(name : String) : Boolean
		{
			return false;
		}

		private var _matchResolutionShowContinueButton : Boolean;

		public function get matchResolutionShowContinueButton() : Boolean
		{
			return _matchResolutionShowContinueButton;
		}

		public function set matchResolutionShowContinueButton(value : Boolean) : void
		{
			if (_matchResolutionShowContinueButton != value)
			{
				_matchResolutionShowContinueButton = value;

				dispatchEvent(new Event(EVENT_MATCH_RESOLUTION_SHOW_CONTINUE_BUTTON));
			}
		}

		public var warOutcome : WarOutcome;
		public var warFinished : BattleFinishedData;

		public function showWarResolution(warOutcome : WarOutcome, warFinished : BattleFinishedData) : void
		{
			this.warOutcome = warOutcome;
			this.warFinished = warFinished;
			dispatchEvent(new Event(EVENT_WAR_RESOLUTION));
		}

		public function respawnBattle() : void
		{
			if (battleHandler)
			{
				battleHandler.respawnBattle();
			}
		}
	}
}
