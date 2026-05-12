package game.session.states
{
	import engine.battle.SceneListItemDef;
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;
	import engine.core.pref.PrefBag;
	import engine.entity.def.EntityListDefVars;

	import game.cfg.GameConfig;
	import game.gui.GuiGamePrefs;
	import game.session.GameFsm;
	import game.session.GameState;
	import game.session.actions.VersusCancelTxn;
	import game.session.actions.VersusStartMatchTxn;
	import game.session.actions.VsType;

	import tbs.srv.battle.data.BattlePartyData;
	import tbs.srv.battle.data.client.BattleCreateData;
	import tbs.srv.util.Tourney;

	public class VersusFindMatchState extends GameState
	{
		private static const MAX_DELAY : int = 5000;
		private var txn : VersusStartMatchTxn;
		private var nextDelay : int = 500;
		private var match_handle : int;
		private static var last_match_handle : int = 0;
		public var vs_type : VsType;
		public var vs_power : int;

		public function VersusFindMatchState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleCleanup() : void
		{
			communicator.removePollTimeRequirement(this);

			if (config.factions)
			{
				config.factions.vsmonitor.setPlayerQueuePower(vs_type, 0);
			}

			match_handle = 0;

			if (txn)
			{
				txn.abort();
				txn = null;
			}

			if (phase != StatePhase.COMPLETED)
			{
				// cancel any outstanding matches
				new VersusCancelTxn(credentials, match_handle, null, gameFsm.config).send(communicator);
			}
		}

		override public function handleMessage(msg : Object) : Boolean
		{
			if (msg["class"] == "tbs.srv.battle.data.BattleCreateData")
			{
				var bcd : BattleCreateData = new BattleCreateData;
				bcd.parseJson(msg, logger);

				var order : int = 0;
				var opponent_name : String;
				var opponent_party : EntityListDefVars;
				var opponent_id : int;

				var local_party : EntityListDefVars;
				var local_party_data : BattlePartyData;

				logger.info("VersusFindMatchState starting Battle " + bcd.battle_id + " url=" + msg.scene);
				for (var i : int = 0; i < bcd.parties.length; ++i)
				{
					var party : BattlePartyData = bcd.parties[i];
					logger.info("   Party " + i + ": " + party);

					if (party.user == credentials.userId)
					{
						logger.info("     ME!");
						order = i;

						if (party.match_handle != match_handle)
						{
							logger.info("VersusFindMatchState We already gave up on match_handle " + party.match_handle);
							return true;
						}

						local_party_data = party;
						var local_eld : Object = {defs: party.defs};
						local_party = new EntityListDefVars(config.context.locale).fromJson(local_eld, logger, config.abilityFactory, config.classes);

					}
					else
					{
						opponent_id = party.user;
						opponent_name = party.display_name;
						var eld : Object = {defs: party.defs};
						opponent_party = new EntityListDefVars(config.context.locale).fromJson(eld, logger, config.abilityFactory, config.classes);
					}
				}

				data.setValue(GameStateDataEnum.OPPONENT_ID, opponent_id);
				data.setValue(GameStateDataEnum.OPPONENT_NAME, opponent_name);
				data.setValue(GameStateDataEnum.OPPONENT_PARTY, opponent_party);
				data.setValue(GameStateDataEnum.LOCAL_PARTY, local_party);
				data.setValue(GameStateDataEnum.LOCAL_TIMER_SECS, local_party_data.timer);
				data.setValue(GameStateDataEnum.BATTLE_CREATE_DATA, bcd);
				data.removeValue(GameStateDataEnum.MATCH_RESOLUTION_CONTINUE_ONLY);
				data.removeValue(GameStateDataEnum.BATTLE_BUCKET);
				data.removeValue(GameStateDataEnum.BATTLE_SPAWN_TAGS);
				data.removeValue(GameStateDataEnum.VERSUS_RESTART);

				const sceneDef : SceneListItemDef = config.sceneListDef.fetch(bcd.scene);
				if (!sceneDef)
				{
					logger.error("Invalid scene id: " + bcd.scene);
					phase = StatePhase.FAILED;
					return true;
				}
				const sceneUrl : String = sceneDef.url;
				data.setValue(GameStateDataEnum.SCENE_URL, sceneUrl);
				data.setValue(GameStateDataEnum.PLAYER_ORDER, order);

				phase = StatePhase.COMPLETED;
				return true;
			}

			return false;
		}

		override protected function handleEnteredState() : void
		{
			gameFsm.updateGameLocation("loc_versus");

			communicator.setPollTimeRequirement(this, 2000);

			logger.info("Entering VS...");

			match_handle = ++last_match_handle;

			data.setValue(GameStateDataEnum.BATTLE_CREATE_DATA, null);
			data.setValue(GameStateDataEnum.LOCAL_PARTY, null);
			data.setValue(GameStateDataEnum.LOCAL_TIMER_SECS, 0);
			data.removeValue(GameStateDataEnum.MATCH_RESOLUTION_CONTINUE_ONLY);

			var forceOpponent : int = data.getValue(GameStateDataEnum.FORCE_OPPONENT_ID);
			var forceSceneId : String = data.getValue(GameStateDataEnum.BATTLE_SCENE_ID);
			var battleTimer : int = data.getValue(GameStateDataEnum.BATTLE_TIMER_SECS);
			var tourney_id : int = data.getValue(GameStateDataEnum.VERSUS_TOURNEY_ID);
			vs_type = data.getValue(GameStateDataEnum.VERSUS_TYPE);
			vs_power = config.legend.party.totalPower;

			config.factions.vsmonitor.setPlayerQueuePower(vs_type, vs_power);

			txn = new VersusStartMatchTxn(credentials, forceOpponent, forceSceneId, match_handle, battleTimer, tourney_id, vs_type, null, gameFsm.config);

			txn.send(communicator);
		}

		public static function restartFind(type : VsType, config : GameConfig) : void
		{
			var fsm : GameFsm = config.fsm;
			var data : StateData = fsm.current.data;
			data.setValue(GameStateDataEnum.VERSUS_TYPE, type);
			var tid : int = 0;
			if (type == VsType.TOURNEY)
			{
				var t : Tourney = config.factions.tourneys.tourney;
				tid = t ? t.tourney_id : 0;
				data.setValue(GameStateDataEnum.VERSUS_TOURNEY_ID, tid);
			}
			else
			{
				data.removeValue(GameStateDataEnum.VERSUS_TOURNEY_ID);
			}

			var timer : int = computeTimer(tid, config.globalPrefs);

			data.setValue(GameStateDataEnum.BATTLE_TIMER_SECS, timer);
			data.setValue(GameStateDataEnum.FORCE_OPPONENT_ID, config.options.versusForceOpponentId);
			data.setValue(GameStateDataEnum.SCENE_URL, config.options.versusForceScene);

			if (fsm.currentClass == VersusFindMatchState)
			{
				data.setValue(GameStateDataEnum.VERSUS_RESTART, true);
				fsm.transitionTo(VersusCancelState, data);
			}
			else
			{
				fsm.transitionTo(VersusFindMatchState, data);
			}

		}

		public static function computeTimer(tourney_id : int, pref : PrefBag) : int
		{
			const DEFAULT_BATTLE_TIMER : int = 45;
			const EXPERT_MODE_TIMER : int = 30;
			var timer : int = DEFAULT_BATTLE_TIMER;
			if (pref.getPref(GuiGamePrefs.PREF_EXPERT_MODE) || tourney_id)
			{
				timer = EXPERT_MODE_TIMER;
			}

			return timer;
		}
	}
}
