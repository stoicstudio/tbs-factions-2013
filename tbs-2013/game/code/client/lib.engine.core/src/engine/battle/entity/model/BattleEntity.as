package engine.battle.entity.model
{
	import flash.errors.IllegalOperationError;
	import flash.events.IEventDispatcher;
	import flash.geom.Point;

	import engine.ability.IAbilityDef;
	import engine.anim.view.AnimController;
	import engine.battle.ability.def.BattleAbilityDef;
	import engine.battle.ability.def.IBattleAbilityDef;
	import engine.battle.ability.effect.model.BattleFacing;
	import engine.battle.ability.effect.model.Effect;
	import engine.battle.ability.effect.model.EffectTag;
	import engine.battle.ability.effect.model.IEffect;
	import engine.battle.ability.effect.model.IPersistedEffects;
	import engine.battle.ability.effect.model.PersistedEffects;
	import engine.battle.ability.model.BattleAbility;
	import engine.battle.ability.model.BattleAbilityValidation;
	import engine.battle.ability.model.BattleRecord;
	import engine.battle.ability.phantasm.model.IChainPhantasms;
	import engine.battle.board.model.BattleBoard;
	import engine.battle.board.model.BattlePartyType;
	import engine.battle.board.model.IBattleBoard;
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.board.model.IBattleEntityMobility;
	import engine.battle.board.model.IBattleMove;
	import engine.battle.fsm.BattleFsmConfig;
	import engine.battle.fsm.BattleMove;
	import engine.battle.fsm.state.BattleStateTurnLocalBase;
	import engine.battle.sim.IBattleParty;
	import engine.core.logging.ILogger;
	import engine.entity.def.IEntityDef;
	import engine.entity.model.Entity;
	import engine.sound.ISoundDriver;
	import engine.sound.view.SoundController;
	import engine.stat.def.StatType;
	import engine.stat.model.Stat;
	import engine.stat.model.StatEvent;
	import engine.tile.Tile;
	import engine.tile.Tiles;
	import engine.tile.def.TileRect;

	public class BattleEntity extends Entity implements IBattleEntity
	{
		private var _board : IBattleBoard;
		public var pos : Point = new Point();
		private var _rect : TileRect;
		private var _facing : BattleFacing = BattleFacing.SE;
		private var _collidable : Boolean = true;
		private var _party : IBattleParty;
		private var _enabled : Boolean; // intended to hide the display position of the thing -- instead let's have an uninitialized positional state
		private var _mobility : BattleEntityMobility;
		public var animController : AnimController;
		public var soundController : SoundController;
		public var _deploymentReady : Boolean;
		private var _logger : ILogger;
		private var _locoId : String;
		private var _ignoreTargetRotation : int;
		private var _ignoreFacing : Boolean = false;
		private var _killingEffect : Effect;
		private var diedThisTurn : Boolean;

		public function BattleEntity(def : IEntityDef, id : String, board : IBattleBoard, soundDriver : ISoundDriver, logger : ILogger)
		{
			super(def, id);

			if (def == null)
			{
				throw new ArgumentError("can't entity without a def, def.");
			}

			this._party = party;
			this._board = board;
			this._logger = logger;

			var i : int;
			for (i = 0; i < def.stats.numStats; ++i)
			{
				var defstat : Stat = def.stats.getStatByIndex(i);
				var stat : Stat = stats.addStat(defstat.type, defstat.base);
			}

			animController = new AnimController(this.id, null, animControllerHandler, logger);
			soundController = new SoundController(this.id, soundDriver, soundControllerCompleteHandler, logger);

			_mobility = new BattleEntityMobility(this);
			collidable = def.entityClass.collidable;

			if (def.entityClass.mobile)
			{
				temporaryCharacterCtor();
			}
		}

		public function get locoId() : String
		{
			return _locoId;
		}

		public function set locoId(value : String) : void
		{
			_locoId = value;
		}

		protected function soundControllerCompleteHandler(controller : SoundController) : void
		{
		}

		private function animControllerHandler(rhs : AnimController) : void
		{
			if (animController != rhs)
			{
				return;
			}

			// TODO change sprite

		}

		public function cleanup() : void
		{
			if (def.entityClass.mobile)
			{
				cleanupTemporaryCharacter();
			}

			animController.cleanup();
			animController = null;
			_mobility.cleanup();
			_mobility = null;
		}

		public function get x() : Number
		{
			return pos.x;
		}

		public function get y() : Number
		{
			return pos.y;
		}

		public function get centerX() : Number
		{
			return x + width / 2;
		}

		public function get centerY() : Number
		{
			return y + length / 2;
		}

		private var _suppressMoveEvents : Boolean;

		public function set suppressMoveEvents(value : Boolean) : void
		{
			_suppressMoveEvents = value;
		}

		public function setPos(x : Number, y : Number) : void
		{
			if (fake)
			{
				return;
			}

			if (pos.y != y || pos.x != x)
			{
				pos.x = x;
				pos.y = y;
				if (!_suppressMoveEvents)
				{
					dispatchEvent(new BattleEntityEvent(BattleEntityEvent.MOVED, this));
				}
			}
		}

		public function get width() : Number
		{
			return def.entityClass.bounds.width;
		}

		public function get length() : Number
		{
			return def.entityClass.bounds.length;
		}

		public function get height() : Number
		{
			return def.entityClass.bounds.height;
		}

		public function get tile() : Tile
		{
			if (board && board.tiles)
			{
				return board.tiles.getTile(pos.x, pos.y);
			}
			return null;
		}

		public function get rect() : TileRect
		{
			var t : Tile = tile;

			if (t == null)
			{
				return null;
			}

			if (_rect == null)
			{
				_rect = new TileRect(t.location, def.entityClass.bounds.width, def.entityClass.bounds.length);
			}
			else
			{
				_rect.loc = tile.location;
			}
			return _rect;
		}

		public var flyText : String;
		public var flyTextColor : uint;
		public var flyTextFontName : String;
		public var flyTextFontSize : int;

		public function playGoAnimation() : void
		{
			dispatchEvent(new BattleEntityEvent(BattleEntityEvent.GO_ANIMATION, this));
		}

		public function emitFlyText(str : String, color : uint, fontName : String, fontSize : int) : void
		{
			if (fake)
			{
				return;
			}

			flyText = str;
			flyTextColor = color;
			flyTextFontName = fontName;
			flyTextFontSize = fontSize;
			dispatchEvent(new BattleEntityEvent(BattleEntityEvent.FLY_TEXT, this));
		}

		public function get facing() : BattleFacing
		{
			return _facing;
		}

		public function set facing(value : BattleFacing) : void
		{
			if (fake)
			{
				return;
			}

			if (_ignoreFacing)
			{
				return;
			}

			if (_facing != value)
			{
				_facing = value;
				dispatchEvent(new BattleEntityEvent(BattleEntityEvent.FACING, this));
			}
		}

		public function get collidable() : Boolean
		{
			return _collidable;
		}

		public function set collidable(value : Boolean) : void
		{
			if (fake)
			{
				return;
			}

			if (_collidable != value)
			{
				_collidable = value;
				dispatchEvent(new BattleEntityEvent(BattleEntityEvent.COLLIDABLE, this));
			}
		}

		public function get tiles() : Tiles
		{
			return board.tiles;
		}

		///////////////////////// stuff from character ///////////////////////
		///////////////////////// refactor into components ///////////////////////

		private var _effects : PersistedEffects;
		private var _selected : Boolean;
		private var _hilighted : Boolean;
		private var _targeted : Boolean;
		private var _triggering : Boolean;
		private var _record : BattleRecord = new BattleRecord;
		private var _fakeRecord : BattleRecord;
		private var _alive : Boolean = true;

		//////

		private function temporaryCharacterCtor() : void
		{

			_effects = new PersistedEffects(this, logger);

			stats.addStat(StatType.STRENGTH_ATTACK, 0);
			stats.addStat(StatType.MIN_STRENGTH_ATTACK, 0);

			var bb : BattleBoard = _board as BattleBoard;
			if (bb)
			{
				for (var ai : int = 0; ai < def.passives.numAbilities; ++ai)
				{
					var ad : BattleAbilityDef = def.passives.getAbilityDef(ai) as BattleAbilityDef;
					if (ad)
					{
						var pas : BattleAbility = new BattleAbility(this, ad, bb.abilityManager);
						pas.execute(null);
					}
				}
			}
			// TODO: data drive triggers on stat changes
			// for instance, character classes could specify a trigger for STRENGTH that sets ALIVE to zero when STRENGTH == 0
			// or could trigger a special animation when STRENGTH == 2, or even ARMOR == 0
			// or could make the character run away, cast a healing spell, etc...

			stats.getStat(StatType.STRENGTH).addEventListener(StatEvent.CHANGE, strengthChangeHandler);
			stats.getStat(StatType.ARMOR).addEventListener(StatEvent.CHANGE, armorChangeHandler);
		}

		public function cleanupTemporaryCharacter() : void
		{
			stats.getStat(StatType.STRENGTH).removeEventListener(StatEvent.CHANGE, strengthChangeHandler);
			stats.getStat(StatType.ARMOR).removeEventListener(StatEvent.CHANGE, armorChangeHandler);
			_effects.cleanup();
			_effects = null;
		}

		protected function strengthChangeHandler(event : StatEvent) : void
		{
			var stat : Stat = stats.getStat(StatType.STRENGTH);

			if (stat.base < stat.original && event.delta < 0)
			{
				dispatchEvent(new BattleEntityEvent(BattleEntityEvent.DAMAGED, this));
			}

			if (stat.value <= 0)
			{
				// dead dead dead
				alive = false;
			}
		}

		protected function armorChangeHandler(event : StatEvent) : void
		{
			var stat : Stat = stats.getStat(StatType.ARMOR);

			if (stat.base < stat.original && event.delta < 0)
			{
				dispatchEvent(new BattleEntityEvent(BattleEntityEvent.DAMAGED, this));
			}
		}

		public function get triggering() : Boolean
		{
			return _triggering;
		}

		public function set triggering(value : Boolean) : void
		{
			if (fake)
			{
				return;
			}

			if (_triggering != value)
			{
				_triggering = value;
				dispatchEvent(new BattleEntityEvent(BattleEntityEvent.TRIGGERING, this));
			}
		}

		public function get selected() : Boolean
		{
			return _selected;
		}

		public function set selected(value : Boolean) : void
		{
			if (fake)
			{
				return;
			}

			if (_selected != value)
			{
				_selected = value;
				dispatchEvent(new BattleEntityEvent(BattleEntityEvent.SELECTED, this));
			}
		}

		public function get hilighted() : Boolean
		{
			return _hilighted;
		}

		public function set hilighted(value : Boolean) : void
		{
			if (fake)
			{
				return;
			}

			if (_hilighted != value)
			{
				_hilighted = value;
				dispatchEvent(new BattleEntityEvent(BattleEntityEvent.HILIGHTED, this));
			}
		}

		public function get targeted() : Boolean
		{
			return _targeted;
		}

		public function set targeted(value : Boolean) : void
		{
			if (fake)
			{
				return;
			}

			if (_targeted != value)
			{
				_targeted = value;
				dispatchEvent(new BattleEntityEvent(BattleEntityEvent.TARGETED, this));
			}
		}

		public function get effects() : IPersistedEffects
		{
			return _effects;
		}

		public function get team() : String
		{
			return party ? party.team : null;
		}

		public function onStartTurn() : void
		{
			this.mobility.moved = false;

			_effects.clearTag(EffectTag.MOVED_THIS_TURN);
			_effects.clearTag(EffectTag.SPECIAL_PUNCTURE_BONUS);
			board.triggers.clearEntitiesHitThisTurn();

			checkPulsingTriggers();
			board.abilityManager.handleStartTurn();
			_effects.handleStartTurn();
		}

		public function onEndTurn() : void
		{
			if (_effects)
			{
				_effects.handleEndTurn();
			}
		}

		protected function checkPulsingTriggers() : void
		{
			var currentTile : Tile = this.tile;
			if (currentTile)
			{
				if (board.boardSetup)
				{
					board.triggers.checkPulsingTriggers(this, currentTile);
				}
			}
		}

		public function endTurn() : void
		{
			if (fake)
			{
				return;
			}

			const bb : BattleBoard = _board as BattleBoard;

			if (!bb || !bb.sim.fsm.turn || bb.sim.fsm.turn.entity != this)
			{
				return;
			}
			const state : BattleStateTurnLocalBase = bb.sim.fsm.current as BattleStateTurnLocalBase;
			if (state)
			{
				state.skip();
			}
		}

		public function setTurnSuspended(value : Boolean) : void
		{
			if (fake)
			{
				return;
			}

			var bb : BattleBoard = _board as BattleBoard;
			if (bb && bb.sim.fsm.turn)
			{
				if (bb.sim.fsm.turn.entity == this)
				{
					bb.sim.fsm.turn.suspended = true;
				}
			}
		}

		public function createChainForEffect(effect : IEffect) : IChainPhantasms
		{
			if (fake)
			{
				return null;
			}

			var bb : BattleBoard = _board as BattleBoard;
			if (bb)
			{

				return bb.phantasms.createChainForEffect(effect as Effect);
			}

			return null;
		}

		public function get record() : BattleRecord
		{
			return _fakeRecord ? _fakeRecord : _record;
		}

		public function get alive() : Boolean
		{
			return _alive;
		}

		public function set alive(value : Boolean) : void
		{
			if (fake)
			{
				return;
			}

			if (_alive != value)
			{
				_alive = value;
				collidable = value && def.entityClass.collidable;
				dispatchEvent(new BattleEntityEvent(BattleEntityEvent.ALIVE, this));

				if (_alive == false)
				{
					diedThisTurn = true;

					mobility.stopMoving();

					if (this.playerControlled == true)
					{
						endTurn();
					}
				}
			}
		}

		public function get animEventDispatcher() : IEventDispatcher
		{
			return this;
		}

		public function get enabled() : Boolean
		{
			return _enabled;
		}

		public function set enabled(value : Boolean) : void
		{
			if (fake)
			{
				return;
			}

			if (_enabled == value)
			{
				return;
			}

			_enabled = value;

			dispatchEvent(new BattleEntityEvent(BattleEntityEvent.ENABLED, this));
		}

		public function get board() : IBattleBoard
		{
			return _board;
		}

		public function get party() : IBattleParty
		{
			return _party;
		}

		public function set party(value : IBattleParty) : void
		{
			_party = value;
		}

		public function get mobility() : IBattleEntityMobility
		{
			return _mobility;
		}

		public function get logger() : ILogger
		{
			return _logger;
		}

		public function set deploymentReady(value : Boolean) : void
		{
			if (fake)
			{
				return;
			}

			if (_deploymentReady != value)
			{
				_deploymentReady = value;
				dispatchEvent(new BattleEntityEvent(BattleEntityEvent.DEPLOYMENT_READY, this));
				enabled = enabled || _deploymentReady;
			}
		}

		public function get deploymentReady() : Boolean
		{
			return _deploymentReady;
		}

		public function get mobile() : Boolean
		{
			return def.entityClass.mobile;
		}

		override public function set fake(value : Boolean) : void
		{
			super.fake = value;
			if (value)
			{
				_fakeRecord = new BattleRecord;
			}
			else
			{
				_fakeRecord = null;
			}
		}

		override public function get isPlayer() : Boolean
		{
			return party ? party.isPlayer : true;
		}

		override public function get isEnemy() : Boolean
		{
			return party ? party.isEnemy : false;
		}

		override public function get playerControlled() : Boolean
		{
			if (!party)
			{
				return false;
			}

			switch (party.type)
			{
				case BattlePartyType.REMOTE:
					return false;
				case BattlePartyType.LOCAL:
					return true;
				case BattlePartyType.AI:
					return !BattleFsmConfig.enableAi;
				default:
					throw new IllegalOperationError("no such type " + party.type);
			}

		}

		override public function update(delta : int) : void
		{
			super.update(delta);

			if (mobility)
			{
				mobility.update(delta);
			}

			animController.update(delta);
		}

		public function handleMissed(effect : IEffect) : void
		{
			dispatchEvent(new BattleEntityEvent(BattleEntityEvent.MISSED, this));
		}

		public function handleResisted(effect : IEffect) : void
		{
			dispatchEvent(new BattleEntityEvent(BattleEntityEvent.RESISTED, this));
		}

		public function get ignoreTargetRotation() : Boolean
		{
			return _ignoreTargetRotation > 0;
		}

		public function incrementIgnoreTargetRotation() : void
		{
			++_ignoreTargetRotation;
		}

		public function decrementIgnoreTargetRotation() : void
		{
			if (_ignoreTargetRotation == 0)
			{
				throw new IllegalOperationError("Too many");
			}
			--_ignoreTargetRotation;
		}

		public function get ignoreFacing() : Boolean
		{
			return _ignoreFacing;
		}

		public function set ignoreFacing(val : Boolean) : void
		{
			_ignoreFacing = val;
		}

		public function get ignoreFreezeFrame() : Boolean
		{
			return animController.ignoreFreezeFrame;
		}

		public function set ignoreFreezeFrame(val : Boolean) : void
		{
			animController.ignoreFreezeFrame = val;
		}

		public function get killingEffect() : IEffect
		{
			return _killingEffect;
		}

		public function set killingEffect(value : IEffect) : void
		{
			if (_killingEffect)
			{
				return;
			}

			_killingEffect = value as Effect;

			dispatchEvent(new BattleEntityEvent(BattleEntityEvent.KILLING_EFFECT, this));
		}

		public function highestAvailableAbilityDef() : IBattleAbilityDef
		{
			const abl : IAbilityDef = def.actives.getAbilityDef(0);
			var abilityLevel : int = Math.min(stats.GetMaxAbilityLevel(StatType.ACTIVE_0), stats.getValue(StatType.WILLPOWER));

			// JU_TODO: test
			//abilityLevel = 1;
			//abilityLevel = 2;
			//abilityLevel = 3;
			// JU_TODO: end test

			if (abilityLevel > 0)
			{
				return abl.getAbilityDefForLevel(abilityLevel) as BattleAbilityDef;
			}
			return null;
		}

		public function lowestValidAbilityDef(t : IBattleEntity, tile : Tile, move : IBattleMove) : IBattleAbilityDef
		{
			var highestDef : BattleAbilityDef = highestAvailableAbilityDef() as BattleAbilityDef;
			var highestLevel : int = highestDef.level;

			for (var i : int = 1; i <= highestLevel; i++)
			{
				const def : BattleAbilityDef = highestDef.getBattleAbilityDefLevel(i);

				const anyTile : Boolean = true; // not sure if this is correct in all cases
				const checkCosts : Boolean = true;
				const valid : BattleAbilityValidation = BattleAbilityValidation.validate(def, this, move as BattleMove, t, tile, anyTile, checkCosts);
				if (valid == BattleAbilityValidation.OK)
				{
					return def;
				}
			}
			return null;
		}

		public function expireDeadEntitiesEffects() : void
		{
			if (_effects && diedThisTurn)
			{
				diedThisTurn = false;
				effects.handleEndTurn();
			}
		}
	}
}
