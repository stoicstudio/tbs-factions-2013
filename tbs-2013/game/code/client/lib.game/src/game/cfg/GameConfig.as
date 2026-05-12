package game.cfg
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	
	import engine.achievement.AchievementListDef;
	import engine.achievement.AchievementListDefVars;
	import engine.anim.def.AnimClipDef;
	import engine.anim.view.AnimClipSprite;
	import engine.anim.view.AnimController;
	import engine.battle.SceneListDef;
	import engine.battle.SceneListDefVars;
	import engine.battle.SceneListItemDef;
	import engine.battle.ability.def.BattleAbilityDefFactory;
	import engine.battle.ability.def.BattleAbilityDefFactoryVars;
	import engine.battle.ability.effect.op.def.IdEffectOpRegistry;
	import engine.battle.ability.effect.op.model.Op_WaitForActionComplete;
	import engine.battle.board.def.BattleBoardTriggerDefManager;
	import engine.battle.board.def.BattleBoardTriggerDefWrangler;
	import engine.core.RunMode;
	import engine.core.cmd.CmdExec;
	import engine.core.cmd.ShellCmdManager;
	import engine.core.fsm.StateData;
	import engine.core.locale.Locale;
	import engine.core.locale.LocaleCategory;
	import engine.core.locale.LocaleWrangler;
	import engine.core.logging.ILogger;
	import engine.core.logging.Logger;
	import engine.core.pref.PrefBag;
	import engine.core.util.EngineCoreContext;
	import engine.core.util.Enum;
	import engine.def.BooleanVars;
	import engine.entity.def.EntityClassDefList;
	import engine.entity.def.EntityClassDefWrangler;
	import engine.entity.def.IEntityListDef;
	import engine.entity.def.Legend;
	import engine.gui.GuiButtonState;
	import engine.gui.GuiEventEater;
	import engine.gui.IGuiEventEater;
	import engine.resource.AssetIndex;
	import engine.resource.MovieClipResource;
	import engine.resource.ResourceManager;
	import engine.resource.def.DefWrangler;
	import engine.resource.def.DefWranglerWrangler;
	import engine.saga.Saga;
	import engine.saga.SagaDefLoader;
	import engine.scene.SceneControllerConfig;
	import engine.session.Alert;
	import engine.session.AlertManager;
	import engine.session.AlertOrientationType;
	import engine.session.AlertStyleType;
	import engine.session.NewsDef;
	import engine.session.NewsDefVars;
	import engine.sound.IFevPreloader;
	import engine.sound.config.FmodSoundSystem;
	import engine.sound.config.ISoundSystem;
	import engine.steamworks.ISteamworks;
	
	import game.entity.GameStatCosts;
	import game.entity.GameStatCostsWrangler;
	import game.gui.GameGuiContext;
	import game.gui.GuiAlertManager;
	import game.gui.IGuiDialog;
	import game.saga.GameSaga;
	import game.session.GameFsm;
	import game.session.actions.SessionSteamOverlayTxn;
	import game.session.states.AssembleHeroesState;
	import game.session.states.GameStateDataEnum;
	import game.session.states.SceneLoadState;
	import game.session.states.VideoQueueState;
	import game.session.states.VideoTutorial1State;
	import game.session.states.VideoTutorial2State;
	import game.session.states.tutorial.TutorialEndState;
	import game.view.GamePageManagerAdapter;
	import game.view.IDialogLayer;
	import game.view.TutorialLayer;
	import game.view.TutorialTooltipAlign;
	import game.view.TutorialTooltipAnchor;
	
	import tbs.srv.data.FriendsData;

	public class GameConfig extends EventDispatcher
	{
		public static const PROTOCOL_VERSION : int = 11;
		public static const ASSETS_VERSION : int = 6;

		public static const EVENT_ACCOUNT_INFO : String = "GameConfig.EVENT_ACCOUNT_INFO";
		public static const EVENT_FACTIONS : String = "GameConfig.EVENT_FACTIONS";
		public static const EVENT_SAGA : String = "GameConfig.EVENT_SAGA";

		public var abilityFactory : BattleAbilityDefFactoryVars;
		public var context : EngineCoreContext;

		public var animDispatcher : EventDispatcher = new EventDispatcher;

		public var resman : ResourceManager;
		public var guiresman : ResourceManager;

		public var assets : GameAssetsDef;

		public var fsm : GameFsm;

		public var runMode : RunMode;

		public var username : String;

		private var _accountInfo : AccountInfoDef;

		private var assetIndex : AssetIndex;

		public var options : GameOptions = new GameOptions;

		private var readyCallback : Function;
		public var soundSystem : ISoundSystem;
		public var gameGuiContext : GameGuiContext;

		public var statCosts : GameStatCosts;
		private var soundDriverClazz : Class;
		private var _classes : EntityClassDefList;
		private var _triggers : BattleBoardTriggerDefManager;
		private var localeWrangler : LocaleWrangler;
		private var dialogLayer : IDialogLayer;
		private var assetsConfigWrangler : DefWrangler;
		public var eater : IGuiEventEater;
		public var keybinder : GameKeyBinder;
		private var _buildRelease : String = "dev";

		public var spawnables : IEntityListDef;

		public var serverHostsQa : String;
		public var serverHostsLive : String;

		//public var loaderHelpers : Dictionary = new Dictionary;

		private static const PREFS_VERSION : int = 2;
		public var globalPrefs : PrefBag;

		public var shell : ShellCmdManager;

		public var steamworks : ISteamworks;

		public var systemMessage : SystemMessageManager;

		public var purchasableUnits : PurchasableUnits;

		public var namegen : NameGenerator;
		public var friends : FriendsData;
		public var ambienceDef : GameAmbienceDef;
		public var sceneListDef : SceneListDef;
		public var achievementListDef : AchievementListDef;

		public var alerts : AlertManager;
		public var guiAlerts : GuiAlertManager;

		public var client_language : String = "en";

		public var tutorialLayer : TutorialLayer;

		public var battleHudConfig : BattleHudConfig = new BattleHudConfig;
		public var sceneControllerConfig : SceneControllerConfig = new SceneControllerConfig;

		public var saga : Saga;
		public var factions : FactionsConfig;

		public static const PREF_NEWS_READ_DATE : String = "news_date";
		public static const PREF_USERNAME : String = "username";
		public static const PREF_BATTLE_FIRST_TIME : String = "battle_first_time";
		public static const PREF_STRAND_TUTORIAL_PULSE : String = "strand_tutorial_pulse";
		public static const PREF_PASSWORD : String = "password";
		public static const PREF_SERVERNAME : String = "servername";
		public static const PREF_SHOW_PERF : String = "show_perf";
		public static const PREF_GUIDEPOST_COMPLETE_ : String = "guidepost_complete_";
		public static const PREF_LAST_DAILY_LOGIN_STREAK : String = "last_daily_login_streak";
		public static const PREF_OPTION_SFX : String = "option_sfx";
		public static const PREF_OPTION_MUSIC : String = "option_music";
		public static const PREF_OPTION_CHAT : String = "option_chat";
		public static const PREF_OPTION_FULLSCREEN : String = "option_fullscreen";

		public static function getGuidepostCompletePref(guidepost : String) : String
		{
			return PREF_GUIDEPOST_COMPLETE_ + guidepost;
		}

		private var _gameServerUrl : String;
		private static const COMBAT_ASSETS_DEF_URL : String = "common/battle/battle_assets.json.z";
		private static const STAT_COSTS_URL : String = "common/character/stat_costs.json.z";
		private static const CHARACTER_CLASS_DEFS_URL : String = "common/character/character_classes.json.z";
		private static const PROP_CLASS_DEFS_URL : String = "common/battle/prop/prop_classes.json.z";
		private static const TRIGGER_CLASS_DEFS_URL : String = "common/battle/trigger/trigger_defs.json.z";
		private static const STARTING_ROSTER_URL : String = "common/character/starting_roster.json.z";
		private static const LOCALE_URL : String = "common/locale/en.json.z";
		private static const ASSETS_CONFIG_URL : String = "common/assets_config.json.z";
		private static const STATIC_SOUND_LIBRARY_URL : String = "common/sound/sound_assets.json.z";
		private static const AMBIENCE_URL : String = "common/sound/sound_ambience.json.z";
		private static const SCENE_LIST_URL : String = "common/battle/battle_scene_list.json.z";
		private static const ACHIEVEMENT_DEFS_URL : String = "common/achievement/achievement_defs.json.z";

		public function GameConfig(context : EngineCoreContext, fsmClazz : Class, soundDriverClazz : Class, readyCallback : Function, dialogLayer : IDialogLayer, gameNumber : int)
		{
			context.logger.info("Build:");
			context.logger.info("        Version: " + context.appInfo.buildVersion);
			context.logger.info("             Id: " + context.appInfo.buildId);
			context.logger.info("Capabilities:");
			context.logger.info("      isDebugger: " + Capabilities.isDebugger);
			context.logger.info("        language: " + Capabilities.language);
			context.logger.info("    manufacturer: " + Capabilities.manufacturer);
			context.logger.info("              os: " + Capabilities.os);
			context.logger.info("pixelAspectRatio: " + Capabilities.pixelAspectRatio + ", dpi: " + Capabilities.screenDPI);
			context.logger.info("      playerType: " + Capabilities.playerType);
			context.logger.info("      resolution: " + Capabilities.screenResolutionX + " x " + Capabilities.screenResolutionY);
			context.logger.info(" touchscreenType: " + Capabilities.touchscreenType);
			context.logger.info("         version: " + Capabilities.version);

			IdEffectOpRegistry.register();

			this.context = context;
			this.readyCallback = readyCallback;
			this.soundDriverClazz = soundDriverClazz;
			this.dialogLayer = dialogLayer;
			this.eater = new GuiEventEater;
			this.alerts = new AlertManager(context.logger);

			// this causes hosts to get setup
			buildRelease = context.appInfo.buildRelease;

			shell = new ShellCmdManager(logger);

			keybinder = new GameKeyBinder(this, gameNumber);

			addShellCmds();

			// go ahead and create a dummy account info that will get replaced later
			accountInfo = new AccountInfoDef(this);

			globalPrefs = new PrefBag("global_" + gameNumber, PREFS_VERSION, logger,
				[
				{key: PREF_USERNAME, value: ""},
				{key: PREF_PASSWORD, value: ""},
				{key: PREF_SERVERNAME, value: ""},
				{key: PREF_SHOW_PERF, value: false},
				{key: PREF_STRAND_TUTORIAL_PULSE, value: true},
				{key: "pg_help_pulse", value: true},
				{key: "pg_roster_first_time", value: true},
				{key: "pg_ability_first_time", value: true},
				{key: PREF_BATTLE_FIRST_TIME, value: true},
				{key: PREF_BATTLE_FIRST_TIME, value: true},
				{key: PREF_OPTION_SFX, value: true},
				{key: PREF_OPTION_MUSIC, value: true},
				{key: PREF_OPTION_FULLSCREEN, value: true},
				{key: PREF_OPTION_CHAT, value: true},
				]
				);
		}

		public function startLoading() : void
		{
			if (!gameServerUrl)
			{
				if (runMode != RunMode.DEVELOPER)
				{
					gameServerUrl = serverHostsLive;
				}
			}

			if (gameServerUrl && gameServerUrl.charAt(gameServerUrl.length - 1) != "/")
			{
				gameServerUrl += "/";
			}

			if (!username)
			{
				username = globalPrefs.getPref(PREF_USERNAME);

				if (!username)
				{
					username = new Date().time.toString(16);
				}
			}

			context.logger.info("CONFIG runMode=" + runMode);
			context.logger.info("CONFIG assets=" + options.assetPath);
			context.logger.info("CONFIG gui=" + options.guiPath);
			context.logger.info("CONFIG server=" + gameServerUrl);

			resman = new ResourceManager(assetIndex, options.assetPath, context.logger);
			guiresman = new ResourceManager(assetIndex, options.guiPath, context.logger);

			// preload the loading screen
			guiresman.getResource("loading.swf/assets.loading", MovieClipResource);

			assetsConfigWrangler = new DefWrangler(ASSETS_CONFIG_URL, logger, resman, assetsConfigWranglerReadyHandler);
			assetsConfigWrangler.load();

			tutorialLayer.addEventListener(TutorialLayer.READY, tutorialLayerReadyHandler);
			tutorialLayer.load(guiresman);

			var urlr : URLRequest = new URLRequest("http://stoicstudio.com/deploy/dev/" + context.appInfo.buildVersion + "/news.json");
			//var urlr : URLRequest = new URLRequest("http://stoicstudio.com/deploy/dev/" + context.appInfo.buildVersion + "/news.json");
			newsLoader = new URLLoader(urlr);
			newsLoader.addEventListener(Event.COMPLETE, newsCompleteHandler);
			newsLoader.addEventListener(IOErrorEvent.IO_ERROR, newsErrorHandler);
			newsLoader.load(urlr);
		}

		private var newsLoader : URLLoader;
		public var news : NewsDef;

		private function newsCompleteHandler(event : Event) : void
		{
			var json : Object = JSON.parse(newsLoader.data);
			news = new NewsDefVars().fromJson(json, logger);
		}

		private function newsErrorHandler(event : IOErrorEvent) : void
		{
			logger.error("newsErrorHandler: " + event);

			news = new NewsDef;
		}

		public function loadFactions() : void
		{
			if (saga)
			{
				saga.cleanup();
				saga = null;
				dispatchEvent(new Event(EVENT_SAGA));
			}

			if (factions)
			{
				factions.cleanup();
			}

			factions = new FactionsConfig(this, factionsReadyCallback);
			factions.load();
		}

		private function factionsReadyCallback() : void
		{
			soundSystem.ambienceId = "ambience_long";
			dispatchEvent(new Event(EVENT_FACTIONS));
		}

		private var loadingSaga : SagaDefLoader;
		private var sagaHappening : String;

		public function loadSaga(url : String, happening : String) : void
		{
			sagaHappening = happening;
			if (factions)
			{
				factions.cleanup();
				factions = null;
				dispatchEvent(new Event(EVENT_FACTIONS));
			}

			options.newMusic = true;

			if (saga)
			{
				sceneListDef.purgeSku(saga.def.id);
				// restore?
				_classes = null;
				saga.cleanup();
				shell.removeShell("saga");
				saga = null;
			}

			loadingSaga = new SagaDefLoader(url, sagaDefReadyCallback, resman, context.logger, context.locale, classes, abilityFactory, soundSystem);
		}

		private function sagaDefReadyCallback(sl : SagaDefLoader) : void
		{

			logger.debug("GameConfig.sagaDefReadyCallback START");

			if (sl != loadingSaga)
			{
				return;
			}

			loadingSaga = null;

			if (!sl.sagaDef)
			{
				context.appInfo.terminateError("Failed to load saga, quitting");
				return;
			}

			saga = new GameSaga(this, sl.sagaDef, resman);
			saga.load(sagaLoadedHandler);
		}

		private function sagaLoadedHandler(rhs : Saga) : void
		{
			if (rhs != saga)
			{
				return;
			}

			spawnables = saga.def.cast;

			logger.debug("GameConfig.sagaLoadedHandler SKU MERGE");
			sceneListDef.mergeSku(saga.def.id, saga.def.scenes);
			logger.debug("GameConfig.sagaLoadedHandler SKU MERGED");

			saga.def.classes.parent = classes;
			_classes = saga.def.classes;

			dispatchEvent(new Event(EVENT_SAGA));

			shell.addShell("saga", saga.shell);

			logger.debug("GameConfig.sagaLoadedHandler END, STARTING");

			saga.start(sagaHappening);
		}

		private function tutorialLayerReadyHandler(event : Event) : void
		{
			checkReady();
		}

		public function cleanup() : void
		{
			if (saga)
			{
				saga.cleanup();
				saga = null;
			}
			
			if (factions)
			{
				factions.cleanup();
				factions = null;
			}
			if (fsm && fsm.current)
			{
				fsm.stopFsm(false);
			}
		}

		public static function massageResourcePath(appUrlRoot : String, logger : ILogger, path : String) : String
		{
			if (path == null)
			{
				path = "";
			}

			if (path)
			{
				try
				{
					path = transformUrl(appUrlRoot, path);
				}
				catch (e : Error)
				{
					logger.error("Failed to transform path " + path + ": " + e.getStackTrace());
				}
			}

			return path;

		}

		private function assetsConfigWranglerReadyHandler(wrangler : DefWrangler) : void
		{
			if (!wrangler.vars)
			{
				context.appInfo.terminateError("assetsConfigWranglerReadyHandler unable to load");
				return;
			}
			var assets_version : int = wrangler.vars.assets_version;

			if (assets_version != ASSETS_VERSION)
			{
				context.appInfo.terminateError("ASSETS_VERSION expected " + ASSETS_VERSION + ", but found " + assets_version + ".  Your client is incompatible with the assets.");
				return;
			}

			logger.info("GameConfig.assetsConfigWranglerReadyHandler");

			LocaleCategory;
			GuiButtonState;

//			LocaleCategory.ABILITY;
//			LocaleCategory.ACHIEVEMENT;
//			LocaleCategory.ENTITY;
//			LocaleCategory.GUI;
//			LocaleCategory.IAP;
//			LocaleCategory.TAUNT;
//			LocaleCategory.TUTORIAL;			

			localeWrangler = new LocaleWrangler(LOCALE_URL, context.logger, resman, localeWranglerReadyHandler, LocaleCategory, false);
			localeWrangler.load();
		}

		private var wranglers : DefWranglerWrangler;

		private function localeWranglerReadyHandler(wrangler : DefWrangler) : void
		{
			logger.info("GameConfig.localeWranglerReadyHandler");

			if (!localeWrangler.locale)
			{
				context.logger.error("LocaleWrangler failed to load locale, generating silenced stub");
				context.locale = new Locale(new Logger("/dev/null"));
			}
			else
			{
				context.locale = localeWrangler.locale;
			}

			systemMessage = new SystemMessageManager(context.locale);

			purchasableUnits = new PurchasableUnits(this);
			friends = new FriendsData(logger);

			abilityFactory = new BattleAbilityDefFactoryVars(resman, logger, context.locale.getLocalizer(LocaleCategory.ABILITY), abilityCompleteHandler);

			wranglers = new DefWranglerWrangler("game", resman, logger);

			wranglers.add(new GameStatCostsWrangler(STAT_COSTS_URL, logger, resman, null));

			soundSetup();

			wranglers.add(new EntityClassDefWrangler(CHARACTER_CLASS_DEFS_URL, logger, resman, context.locale, null));
			wranglers.add(new EntityClassDefWrangler(PROP_CLASS_DEFS_URL, logger, resman, context.locale, null));

			wranglers.wrangle(STARTING_ROSTER_URL);
			wranglers.wrangle(AMBIENCE_URL);
			wranglers.wrangle(SCENE_LIST_URL);
			wranglers.wrangle(ACHIEVEMENT_DEFS_URL);

			wranglers.add(new BattleBoardTriggerDefWrangler(TRIGGER_CLASS_DEFS_URL, logger, resman, null));

			namegen = new NameGenerator(resman, namegenCompleteHandler);

			assets = new GameAssetsDef(COMBAT_ASSETS_DEF_URL, this, combatAssetsCompleteHandler);
			if (assets.ready)
			{
				checkReady();
			}

			namegen.load();

			wranglers.addEventListener(Event.COMPLETE, wranglersHandler);
			wranglers.load();
		}

		private function wranglersHandler(event : Event) : void
		{
			checkReady();
		}

		private function namegenCompleteHandler(ng : NameGenerator) : void
		{
			checkReady();
		}

		private function soundSetup() : void
		{
			var sc : FmodSoundSystem = new FmodSoundSystem(resman, STATIC_SOUND_LIBRARY_URL, soundDriverClazz, soundConfigReady, context.logger);
			sc.enabled = options.soundEnabled;
			soundSystem = sc;
			sc.init(options.fmodProfile);
		}

		private var fevPreloader : IFevPreloader;
		private function soundConfigReady() : void
		{
			if (options.fmodPort)
			{
				soundSystem.driver.netEventSystem_Init(options.fmodPort);
			}
			fevPreloader = soundSystem.driver.fevPreloader;
			fevPreloader.addFev("common/fmod/world.fev");
			fevPreloader.addFev("common/fmod/test.fev");
			fevPreloader.addFev("common/fmod/reverb.fev");
			fevPreloader.addFev("common/fmod/character.fev");

			fevPreloader.load(fevPreloaderCompleteHandler);
			checkReady();
		}

		private function fevPreloaderCompleteHandler(fevPreloader : IFevPreloader) : void
		{
			soundSystem.driver.reverbAmbientPreset("default");
			(soundSystem as FmodSoundSystem).createSoundController(soundConfigControllerReady);
			checkReady();
		}

		private function soundConfigControllerReady(config : FmodSoundSystem) : void
		{
			checkReady();
		}

		private function guiContextHandler(rhs : GameGuiContext) : void
		{
			checkReady();
		}

		private function checkGuiContextReady() : Boolean
		{
			if (gameGuiContext)
			{
				return true;
			}

			if (soundSystem && soundSystem.ready && soundSystem.controller)
			{
				if (assets && assets.ready)
				{
					if (resman && guiresman && dialogLayer)
					{
						var dr : MovieClipResource = guiresman.getResource(assets.dialog, MovieClipResource) as MovieClipResource;

						gameGuiContext = new GameGuiContext(logger, resman, soundSystem.controller, accountInfo, dr, dialogLayer, this);

						gameGuiContext.load(guiContextHandler);
						return true;
					}
				}
			}

			return false;
		}

		private var ready : Boolean;

		private static const READY_DEBUG : Boolean = true;

		private function waitingOn(tag : String, msg : Object) : Boolean
		{
			if (READY_DEBUG)
			{
				logger.debug("GameConfig WAITING on " + tag + ": " + msg);
			}
			return true;
		}

		private function checkReady() : void
		{
			if (context.appInfo.terminating)
			{
				return;
			}

			if (ready)
			{
				return;
			}

			checkGuiContextReady();

			var waiting : Boolean;

//			for each (var defLoaderHelper : DefWrangler in loaderHelpers)
//			{
//				if (!defLoaderHelper.complete)
//				{
//					waiting = waitingOn("defLoaderHelper", defLoaderHelper);
//				}
//			}

			if (!(wranglers && wranglers.ready))
			{
				waiting = waitingOn("wranglers", wranglers);
			}

			if (factions && !factions.ready)
			{
				waiting = waitingOn("factions", factions);
			}

			if (!(namegen && namegen.ready))
			{
				waiting = waitingOn("namegen", namegen);
			}

			if (!(assets && assets.ready))
			{
				waiting = waitingOn("assets", assets);
			}

			if (!(abilityFactory && abilityFactory.ready))
			{
				waiting = waitingOn("abilityFactory", abilityFactory);
			}

			if (!(soundSystem && soundSystem.driver && fevPreloader && fevPreloader.complete))
			{
				waiting = waitingOn("soundConfig", soundSystem);

			}

			if (!(gameGuiContext && gameGuiContext.ready))
			{
				waiting = waitingOn("gameGuiContext", gameGuiContext);
			}

			if (!tutorialLayer.ready)
			{
				waiting = waitingOn("tutorialLayer", tutorialLayer);
			}

			if (waiting)
			{
				return;
			}

			if (!assets.ok)
			{
				context.appInfo.terminateError("Game Assets failed to load, further progress is impossible.");
			}
			else
			{
				finishReady();
			}
		}

		private function finishReady() : void
		{
			statCosts = (wranglers.wrangled(STAT_COSTS_URL) as GameStatCostsWrangler).statCosts;

			if (!statCosts)
			{
				logger.error("Failed to load stat costs");
				statCosts = new GameStatCosts;
			}

			_classes = new EntityClassDefList();
			_classes.registerAll((wranglers.wrangled(CHARACTER_CLASS_DEFS_URL) as EntityClassDefWrangler).manager, logger);
			_classes.registerAll((wranglers.wrangled(PROP_CLASS_DEFS_URL) as EntityClassDefWrangler).manager, logger);

			_triggers = new BattleBoardTriggerDefManager(logger);
			_triggers.registerAll(wranglers.wrangled(TRIGGER_CLASS_DEFS_URL).vars);

			ambienceDef = new GameAmbienceDef(wranglers.wrangled(AMBIENCE_URL).vars, logger);
			sceneListDef = new SceneListDefVars(wranglers.wrangled(SCENE_LIST_URL).vars, logger);
			achievementListDef = new AchievementListDefVars(wranglers.wrangled(ACHIEVEMENT_DEFS_URL).vars, logger, context.locale);
			this.guiAlerts = new GuiAlertManager(alerts, gameGuiContext, guiresman);

			createOfflineAccountInfo();

			fsm = new GameFsm(this);
			shell.addShell("fsm", fsm.shell);

			ready = true;
			readyCallback();

			// start a timer to check the steam overlay

			const steamTimer : Timer = new Timer(10000, 1);
			steamTimer.addEventListener(TimerEvent.TIMER_COMPLETE, steamTimerCompleteHandler);
			steamTimer.start();
		}

		private function steamTimerCompleteHandler(event : TimerEvent) : void
		{
			if (fsm.communicator && fsm.communicator.connected)
			{
				// check the steam overlay
				const overlay : Boolean = steamworks.SteamUtils_IsOverlayEnabled();
				logger.info("GameConfig SteamUtils_IsOverlayEnabled = " + overlay);
				const txn : SessionSteamOverlayTxn = new SessionSteamOverlayTxn(fsm.credentials, null, logger, overlay);
				txn.send(fsm.communicator);
			}
		}

		public function generateStartingRoster(tutorial : Boolean) : AccountInfoDef
		{
			const aid : AccountInfoDef = new AccountInfoDefVars(wranglers.wrangled(STARTING_ROSTER_URL).vars, this);
			aid.tutorial = tutorial;
			return aid;
		}

		public function createOfflineAccountInfo() : void
		{
			// must be 2 different objects
			starting_roster = generateStartingRoster(false);
			accountInfo = generateStartingRoster(false);

			if (options.partyOverride)
			{
				accountInfo.legend.party.reset(options.partyOverride);
			}
		}

		private function combatAssetsCompleteHandler(cad : GameAssetsDef) : void
		{
			if (!cad.ok)
			{
				context.appInfo.terminateError("Game Assets failed to load, further progress is impossible.");
				return;
			}
			checkReady();
		}

		private function abilityCompleteHandler(factory : BattleAbilityDefFactory) : void
		{
			if (factory.errors)
			{
				context.appInfo.terminateError("BattleAbilityDefFactory failed to load, goodbye.");
				return;
			}
			checkReady();
		}

		private static function transformUrl(appUrlRoot : String, rhs : String) : String
		{
			if (rhs.indexOf("://") > 0)
			{
				return rhs;
			}

			var back : int = 0;
			var backs : int = 0;
			for (; ; )
			{
				var next : int = rhs.indexOf("../", back);
				if (next >= 0)
				{
					++backs;
					back = next + 3;
					continue;
				}
				break;
			}

			var slash : int = appUrlRoot.length - 1;

			for (var i : int = 0; i < backs; ++i)
			{
				var ns : int = appUrlRoot.lastIndexOf("/", slash - 1);

				if (ns < 0)
				{
					throw new ArgumentError("fail -- cannot descend back " + i + "/" + backs + " folders into root " + appUrlRoot);
				}

				slash = ns;
			}

			var myRoot : String = appUrlRoot.substring(0, slash + 1);
			var rhsRel : String = rhs.substring(back);
			return myRoot + rhsRel;
		}

		public function get logger() : ILogger
		{
			return context.logger;
		}

		public function get classes() : EntityClassDefList
		{
			return _classes;
		}

		public function get triggers() : BattleBoardTriggerDefManager
		{
			return _triggers;
		}

		public var stashed_account_info : AccountInfoDef;

		public function get accountInfo() : AccountInfoDef
		{
			return _accountInfo;
		}

		public function get legend() : Legend
		{
			if (saga)
			{
				return saga.caravan.legend;
			}
			else if (factions)
			{
				return factions.legend;
			}
			return null;
		}

		public var starting_roster : AccountInfoDef;

		public function set accountInfo(value : AccountInfoDef) : void
		{
			_accountInfo = value;
			if (gameGuiContext)
			{
				gameGuiContext.accountInfo = value;
			}

			checkShowNews();

			checkLoginStreakAlert();

			dispatchEvent(new Event(EVENT_ACCOUNT_INFO));
		}

		private var shownLoginStreak : Boolean;

		private function checkLoginStreakAlert() : void
		{
			if (!_accountInfo || !globalPrefs)
			{
				return;
			}

			if (_accountInfo.tutorial)
			{
				return;
			}

			if (shownLoginStreak)
			{
				return;
			}

			const ai : AccountInfoDef = _accountInfo;
			if (!ai.daily_login_streak || !fsm || !fsm.session.credentials.sessionKey)
			{
				return;
			}

			shownLoginStreak = true;

			const last_streak : int = globalPrefs.getPref(PREF_LAST_DAILY_LOGIN_STREAK);
			if (ai.daily_login_streak != last_streak || ai.daily_login_bonus > 0)
			{
				const title : String = "Daily Login Streak";
				const msg : String = "Days Logged In: " + ai.daily_login_streak + "\nBonus Renown Remaining: " + ai.daily_login_bonus;
				const alert : Alert = Alert.create(0, title, msg, null, null, AlertOrientationType.LEFT, AlertStyleType.NORMAL, null)
				alerts.addAlert(alert);
				globalPrefs.setPref(PREF_LAST_DAILY_LOGIN_STREAK, ai.daily_login_streak);
			}

		}

		public function addShellCmds() : void
		{

			shell.add("config", shellFuncConfig);
			shell.add("redraw_regions", shellFuncRedrawRegions);
			shell.add("anim", shellFuncAnim);
			shell.add("spritesheet", shellFuncSpritesheet);
			shell.add("skirmish", shellFuncSkirmish);
			shell.add("kiosk", shellFuncKiosk);
			shell.add("beta", shellFuncBeta);
			shell.add("log_anim_events", shellFuncLogAnimEvents);
			shell.add("fmod_sound", shellFuncSound);
			shell.add("fmod_param", shellFuncFmodParam);
			shell.add("alert", shellFuncAlert);
			shell.add("steam_check_overlay", shellFuncSteamCheckOverlay);
			shell.add("steam_activate_overlay", shellFuncSteamActivateOverlay);
			shell.add("steam_user_activate_overlay", shellFuncSteamUserActivateOverlay);
			shell.add("steam_web_activate_overlay", shellFuncSteamWebActivateOverlay);
			shell.add("steam_store_activate_overlay", shellFuncSteamStoreActivateOverlay);
			shell.add("market", shellFuncMarket);
			shell.add("video", shellFuncVideo);
			shell.add("end_tutorial", shellFuncEndTutorial);
			shell.add("vtut1", shellFuncVtut1);
			shell.add("vtut2", shellFuncVtut2);
			shell.add("tt", shellFuncTt);
			shell.add("display_list", shellFuncDisplayList);
			shell.add("dialog", shellFuncDialog);
			shell.add("tourney_join", shellFuncTourneyJoin);
			shell.add("rtf_debug", shellFuncRtfDebug);
			shell.add("assemble", shellFuncAssembleHeroes);

		}

		private function shellFuncConfig(c : CmdExec) : void
		{
			var argv : Array = c.param;
			logger.info("Config Information");
		}

		private function shellFuncRedrawRegions(c : CmdExec) : void
		{
			var argv : Array = c.param;

			if (argv.length < 2)
			{
				context.appInfo.hideRedrawRegions();
			}
			else
			{
				var color : uint = uint(argv[1]);
				context.appInfo.showRedrawRegions(color);
			}
		}

		private function shellFuncAnim(c : CmdExec) : void
		{
			var argv : Array = c.param;

			if (argv.length >= 2)
			{
				AnimClipDef.setPlaybackMod(argv[1]);
			}

			logger.info("Anim playbackMod: " + AnimClipDef.playbackMod);

		}

		private function shellFuncSpritesheet(c : CmdExec) : void
		{
			var argv : Array = c.param;

			if (argv.length >= 2)
			{
				AnimClipSprite.ENABLE_SPRITESHEET = (argv[1] == "true");
			}

			logger.info("AnimClipSprite.ENABLE_SPRITESHEET: " + AnimClipSprite.ENABLE_SPRITESHEET);

		}

		private function shellFuncKiosk(c : CmdExec) : void
		{
			if (runMode == RunMode.KIOSK)
			{
				runMode = RunMode.DEVELOPER;
			}
			logger.info("RunMode " + runMode);
		}

		private function shellFuncBeta(c : CmdExec) : void
		{
			if (runMode == RunMode.BETA)
			{
				runMode = RunMode.DEVELOPER;
			}
			logger.info("RunMode " + runMode);
		}

		private function shellFuncLogAnimEvents(c : CmdExec) : void
		{
			AnimController.log_anim_events = !AnimController.log_anim_events;
			logger.info("log_anim_events " + AnimController.log_anim_events);
		}

		private function shellFuncSound(c : CmdExec) : void
		{
			const event : String = c.param[1];
			logger.info("event=" + event);

			if (c.param.length >= 3)
			{
				const param : String = c.param[2];
				const value : Number = c.param[3];
				logger.info("param=" + param + ", value=" + value);
				soundSystem.driver.setEventParameter(event, param, value);
			}
			soundSystem.driver.playEvent(event);

		}

		private function shellFuncFmodParam(c : CmdExec) : void
		{
			if (c.param.length < 4)
			{
				logger.error("Usage: " + c.param[0] + " <event> <param> <value>");
				return;
			}
			const event : String = c.param[1];
			logger.info("event=" + event);
			const param : String = c.param[2];
			const value : Number = c.param[3];
			logger.info("param=" + param + ", value=" + value);
			soundSystem.driver.setEventParameter(event, param, value);
		}

		private function shellFuncAlert(c : CmdExec) : void
		{
			const orient : AlertOrientationType = Enum.parse(AlertOrientationType, c.param[1]) as AlertOrientationType;
			const style : AlertStyleType = Enum.parse(AlertStyleType, c.param[2]) as AlertStyleType;
			const name : String = c.param[3];
			const msg : String = c.param[4];

			const alert : Alert = Alert.create(0, name, msg, "Proving Grounds", null, orient, style, null);
			alerts.addAlert(alert);
		}

		private function shellFuncSkirmish(c : CmdExec) : void
		{
			var argv : Array = c.param;

			if (argv.length < 2)
			{
				logger.error("Usage: " + argv[0] + " <scene>");
				return;
			}

			var data : StateData = fsm.current ? fsm.current.data : new StateData;

			var scene : String = argv[1];
			var def : SceneListItemDef = sceneListDef.fetch(scene);
			if (def)
			{
				data.setValue(GameStateDataEnum.SCENE_URL, def.url);
				data.setValue(GameStateDataEnum.LOCAL_TIMER_SECS, 0);
				data.removeValue(GameStateDataEnum.CONVO);
				data.removeValue(GameStateDataEnum.HAPPENING_ID);
				data.removeValue(GameStateDataEnum.MATCH_RESOLUTION_CONTINUE_ONLY);
				data.removeValue(GameStateDataEnum.BATTLE_BUCKET);
				data.removeValue(GameStateDataEnum.BATTLE_SPAWN_TAGS);

				data.setValue(GameStateDataEnum.LOCAL_PARTY, accountInfo.legend.party.getEntityListDef());
				fsm.transitionTo(SceneLoadState, data);
			}
			else
			{
				logger.error("Invalid scene: " + scene);
			}
		}

		private function shellFuncSteamCheckOverlay(c : CmdExec) : void
		{
			var argv : Array = c.param;
			const enabled : Boolean = steamworks.SteamUtils_IsOverlayEnabled();
			const present : Boolean = steamworks.SteamUtils_BOverlayNeedsPresent();

			logger.info("Overlay enabled=" + enabled + ", needsPresent=" + present);

		}

		private function shellFuncSteamActivateOverlay(c : CmdExec) : void
		{
			var argv : Array = c.param;

			const location : String = argv[1];

			steamworks.SteamFriends_ActivateGameOverlay(location);

		}

		private function shellFuncSteamUserActivateOverlay(c : CmdExec) : void
		{
			var argv : Array = c.param;
			const location : String = argv[1];
			const steamId : String = argv[2];

			steamworks.SteamFriends_ActivateGameOverlayToUser(location, steamId);

		}

		private function shellFuncSteamWebActivateOverlay(c : CmdExec) : void
		{
			var argv : Array = c.param;
			const location : String = argv[1];
			steamworks.SteamFriends_ActivateGameOverlayToWebPage(location);
		}

		private function shellFuncSteamStoreActivateOverlay(c : CmdExec) : void
		{
			var argv : Array = c.param;
			const appid : int = argv[1];
			const flag : int = argv[2];
			steamworks.SteamFriends_ActivateGameOverlayToStore(appid, flag);
		}

		private function shellFuncMarket(c : CmdExec) : void
		{
			pageManager.showMarketplace(true, null, null, null);
		}

		private function shellFuncVideo(c : CmdExec) : void
		{
			if (runMode.developer)
			{
				fsm.current.data.setValue(GameStateDataEnum.VIDEO_URL, c.param[1]);
				fsm.transitionTo(VideoQueueState, fsm.current.data);
			}
		}

		private function shellFuncVtut1(c : CmdExec) : void
		{
			//if (runMode.developer)
			{
				//clean data on tutorial
				fsm.transitionTo(VideoTutorial1State, fsm.current.data);
			}
		}

		private function shellFuncVtut2(c : CmdExec) : void
		{
			//if (runMode.developer)
			{
				//clean data on tutorial
				fsm.transitionTo(VideoTutorial2State, fsm.current.data);
			}
		}

		private function shellFuncEndTutorial(c : CmdExec) : void
		{
			if (accountInfo.tutorial)
			{
				fsm.transitionTo(TutorialEndState, fsm.current.data);
			}
		}

		private function shellFuncTt(c : CmdExec) : void
		{
			if (runMode.developer)
			{
				const attach : String = c.param[1];
				const align : TutorialTooltipAlign = Enum.parse(TutorialTooltipAlign, c.param[2]) as TutorialTooltipAlign;
				const anchor : TutorialTooltipAnchor = Enum.parse(TutorialTooltipAnchor, c.param[3]) as TutorialTooltipAnchor;
				const offset : Number = c.param[4];
				const text : String = c.param[5];
				const arrow : Boolean = BooleanVars.parse(c.param[6]);
				const button : Boolean = BooleanVars.parse(c.param[7]);

				tutorialLayer.createTooltip(attach, align, anchor, offset, text, arrow, button, 0);
			}

		}

		private function shellFuncDialog(c : CmdExec) : void
		{
			const d : IGuiDialog = gameGuiContext.createDialog();
			d.openDialog("This is the text", "This is the body", "OK", null);
		}

		private function shellFuncTourneyJoin(c : CmdExec) : void
		{
			const tourney_id : int = c.param[1];
			gameGuiContext.joinTourney(tourney_id, function() : void
			{
				logger.info("join tourney callback");
			});
		}

		private function shellFuncAssembleHeroes(c : CmdExec) : void
		{
			fsm.transitionTo(AssembleHeroesState, fsm.current.data);
		}

		private function shellFuncRtfDebug(c : CmdExec) : void
		{
			Op_WaitForActionComplete.DEBUG_WAIT = !Op_WaitForActionComplete.DEBUG_WAIT;
			logger.debugEnabled = true;
			logger.info("Op_WaitForActionComplete.DEBUG_WAIT " + Op_WaitForActionComplete.DEBUG_WAIT);
		}

		private function shellFuncDisplayList(c : CmdExec) : void
		{
			const path : String = c.param[1];
			const depth : int = c.param[2];
			logger.info(tutorialLayer.printDisplayList(path, depth));
		}

		public function updateGameConfig(delta : int) : void
		{
			if (ready)
			{
				fsm.update(delta);
				var sounded : Boolean = soundSystem.driver.systemUpdate();
				steamworks.SteamAPI_RunCallbacks();
				tutorialLayer.update();
				pageManager.update(delta);
			}
		}

		public function get gameServerUrl() : String
		{
			return _gameServerUrl;
		}

		public function set gameServerUrl(value : String) : void
		{
			_gameServerUrl = value;
		}

		private function setupHosts() : void
		{
			serverHostsLive = "http://tbs-" + _buildRelease + "-live.stoicstudio.com/";
			serverHostsQa = "http://tbs-" + _buildRelease + "-qa.stoicstudio.com/";
			logger.info("CONFIG HOSTS buildRelease=" + _buildRelease);
		}

		public function get buildRelease() : String
		{
			return _buildRelease;
		}

		public function set buildRelease(value : String) : void
		{
			_buildRelease = value;
			setupHosts();
		}

		public function get kioskMode() : Boolean
		{
			return runMode == RunMode.KIOSK;
		}

		public function get betaMode() : Boolean
		{
			return runMode == RunMode.BETA;
		}

		public var pageManager : GamePageManagerAdapter;

		public function checkShowNews() : void
		{
			if (!_accountInfo || !globalPrefs)
			{
				return;
			}

			if (_accountInfo.tutorial || !_accountInfo.completed_tutorial)
			{
				return;
			}

			if (_accountInfo.login_count <= 1)
			{
				// don't show the news on the first login
				return;
			}

			if (!pageManager)
			{
				return;
			}

			//globalPrefs.setPref(PREF_NEWS_READ_DATE, null);
			var d : Date = globalPrefs.getPref(PREF_NEWS_READ_DATE);
			var r : Date = news.getLastDate();
			if (!d || (r && d.date < r.date))
			{
				showNews();
			}
		}

		public function showNews() : void
		{
			var d : Date = globalPrefs.getPref(PREF_NEWS_READ_DATE);
			var r : Date = news.getLastDate();
			globalPrefs.setPref(PREF_NEWS_READ_DATE, r);
			var start : int = news.findFirstIndexAfterDate(d);
			pageManager.showNews(news, start);
		}
	}
}

