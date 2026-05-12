package game.session.states
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.errors.IllegalOperationError;

	import engine.battle.board.model.BattleBoard;
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;
	import engine.core.util.StringUtil;
	import engine.entity.def.IEntityAppearanceDef;
	import engine.entity.def.IEntityDef;
	import engine.entity.def.IEntityListDef;
	import engine.landscape.travel.model.Travel;
	import engine.resource.AnimClipResource;
	import engine.resource.BitmapResource;
	import engine.resource.MovieClipResource;
	import engine.resource.Resource;
	import engine.resource.ResourceManager;
	import engine.resource.ResourceMonitor;
	import engine.saga.SpeakEvent;
	import engine.saga.convo.Convo;
	import engine.scene.SceneContext;
	import engine.scene.model.SceneLoader;

	import game.gui.GuiIcon;
	import game.gui.GuiIconLayoutType;
	import game.gui.IGuiSpeechBubble;
	import game.session.GameState;

	import tbs.srv.battle.data.BattlePartyData;
	import tbs.srv.battle.data.client.BattleCreateData;

	public class SceneLoadState extends GameState
	{
		private var sceneLoader : SceneLoader;
		private var monitor : ResourceMonitor;

		public static const inputDataKeys : Array =
			[
			GameStateDataEnum.SCENE_URL
			];

		public function SceneLoadState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
			data.setValue(GameStateDataEnum.SCENE_IS_TOWN, false);
			data.setValue(GameStateDataEnum.SCENELOADER_PRESERVE, null);
			monitor = new ResourceMonitor(config.logger, resourceMonitorChangedHandler);
		}

		override protected function getRequiredInputDataKeys() : Array
		{
			return inputDataKeys;
		}

		private function resourceMonitorChangedHandler(rhs : ResourceMonitor) : void
		{
			percentLoaded = monitor.percent;
			checkReady();
		}

		override protected function handleEnteredState() : void
		{
			loading = true;
			config.resman.addMonitor(monitor);

			var context : SceneContext =
				new SceneContext(
				gameFsm.config.resman,
				gameFsm.config.guiresman,
				gameFsm.config.logger,
				gameFsm.config.abilityFactory,
				gameFsm.config.classes,
				gameFsm.config.assets.battle,
				gameFsm.config.soundSystem.driver,
				gameFsm.session,
				gameFsm.config.context.locale,
				gameFsm.config.eater,
				gameFsm.chat,
				gameFsm,
				gameFsm.config.animDispatcher,
				gameFsm.config.triggers,
				gameFsm.config.sceneControllerConfig,
				gameFsm.config.keybinder,
				gameFsm.config.saga,
				gameFsm.config.spawnables,
				speechBubbler,
				convoPortraitGenerator
				);

			context.staticSoundController = gameFsm.config.soundSystem.controller;

			var opponentId : int = data.getValue(GameStateDataEnum.OPPONENT_ID);
			var opponentName : String = data.getValue(GameStateDataEnum.OPPONENT_NAME);
			var localBattleOrder : int = data.getValue(GameStateDataEnum.PLAYER_ORDER);
			var opponentOrder : int = localBattleOrder == 0 ? 1 : 0;
			var opponentPartyDef : IEntityListDef = data.getValue(GameStateDataEnum.OPPONENT_PARTY);

			var convo : Convo = data.getValue(GameStateDataEnum.CONVO);
			var happeningId : String = data.getValue(GameStateDataEnum.HAPPENING_ID);
			var battle_bucket : String = data.getValue(GameStateDataEnum.BATTLE_BUCKET);
			var battle_bucket_quota : int = data.getValue(GameStateDataEnum.BATTLE_BUCKET_QUOTA);
			var battle_bucket_deployment : String = data.getValue(GameStateDataEnum.BATTLE_BUCKET_DEPLOYMENT);

			var isOnline : Boolean = opponentName ? true : false;

			var url : String = data.getValue(GameStateDataEnum.SCENE_URL);

			if (!url)
			{
				throw new IllegalOperationError("Why no URL for SceneLoadState?");
			}

			const bcd : BattleCreateData = data.getValue(GameStateDataEnum.BATTLE_CREATE_DATA);
			var opponent : BattlePartyData = null;
			if (isOnline)
			{
				opponent = bcd ? bcd.parties[opponentOrder] : null;
			}

			sceneLoader = new SceneLoader(
				url,
				context,
				sceneLoaderComplete,
				setupLocalPartyCallback,
				opponent,
				bcd,
				localBattleOrder,
				isOnline,
				convo,
				happeningId,
				battle_bucket,
				battle_bucket_quota,
				battle_bucket_deployment
				);

			sceneLoader.load(null);
			checkReady();
		}

		override protected function handleCleanup() : void
		{
			super.handleCleanup();

			if (monitor)
			{
				config.resman.removeMonitor(monitor);
				monitor.cleanup();
			}

			if (sceneLoader)
			{
				sceneLoader.completeCallback = null;
				sceneLoader = null;
			}
		}

		private function sceneLoaderComplete(rhs : SceneLoader) : void
		{
			if (rhs != sceneLoader)
			{
				return;
			}

			if (!sceneLoader.ok)
			{
				config.context.logger.error("SceneLoadState failed to load scene " + sceneLoader.url);
				monitor.abort();
				phase = StatePhase.FAILED;
				return;
			}

			checkReady();
		}

		protected function checkReady() : void
		{
			if (sceneLoader && monitor.empty && sceneLoader.ok)
			{
				var travel : Travel = sceneLoader.scene.landscape ? sceneLoader.scene.landscape.travel : null;
				if (travel)
				{
					if (data.hasValue(GameStateDataEnum.TRAVEL_POSITION))
					{
						var position : Number = data.getValue(GameStateDataEnum.TRAVEL_POSITION);
						travel.gotoPosition(position);
					}
					else
					{
						var location : String = data.getValue(GameStateDataEnum.TRAVEL_LOCATION);
						travel.gotoLocation(location);
					}
				}

				loading = false;
				data.setValue(GameStateDataEnum.SCENE_LOADER, sceneLoader);
				config.resman.removeMonitor(monitor);
				phase = StatePhase.COMPLETED;
			}
		}

		public function speechBubbler(event : SpeakEvent) : MovieClip
		{
			var r : MovieClipResource = config.guiresman.getResource("travel.swf/gui.speak_left", MovieClipResource) as MovieClipResource;
			if (r.ok)
			{
				var mc : MovieClip = r.movieClip;
				var sp : IGuiSpeechBubble = mc as IGuiSpeechBubble;
				sp.init(config.gameGuiContext, event.speaker, event.msg, event.timeout);
				return mc;
			}
			return null;
		}

		public function convoPortraitGenerator(ent : IEntityDef, facing : Boolean) : Sprite
		{
			var rm : ResourceManager = config.resman;
			var app : IEntityAppearanceDef = ent.appearance;
			var r : Resource;

			var url : String;

			if (facing)
			{
				url = app.portraitUrl;
			}
			else
			{
				url = app.backPortraitUrl;
			}

			if (!url)
			{
				logger.error("convoPortraitGenerator: no portrait for " + ent.id + " facing=" + facing);
				return null;
			}

			if (StringUtil.endsWith(url, ".clip"))
			{
				r = rm.getResource(url, AnimClipResource, null);
			}
			else if (StringUtil.endsWith(url, ".png"))
			{
				r = rm.getResource(url, BitmapResource, null);
			}
			else
			{
				logger.error("convoPortraitGenerator: no handler for type " + url);
				return null;
			}

			return new GuiIcon(r, GuiIconLayoutType.ACTUAL);
		}

		private function setupLocalPartyCallback(b : BattleBoard) : void
		{
			if (!b)
			{
				return;
			}
			
			var localBattleOrder : int = data.getValue(GameStateDataEnum.PLAYER_ORDER);
			var timer : int = data.getValue(GameStateDataEnum.LOCAL_TIMER_SECS);

			if (localBattleOrder == 0)
			{
				if (b.numParties == 0)
				{
					var name : String = config.fsm.credentials.displayName;
					var team : String = config.fsm.credentials.userId.toString();
					var id : String = team;
					var deployment : String = b.def.getDeploymentAreaIdByIndex(localBattleOrder);
					b.createLocalParty(name, id, team, deployment, timer);
				}
			}
		}
	}
}
