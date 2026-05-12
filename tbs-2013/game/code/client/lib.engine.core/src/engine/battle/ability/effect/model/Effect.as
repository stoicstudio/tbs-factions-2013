package engine.battle.ability.effect.model
{
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import engine.battle.ability.effect.def.EffectStackRule;
	import engine.battle.ability.effect.def.IEffectDef;
	import engine.battle.ability.effect.op.def.EffectDefOp;
	import engine.battle.ability.effect.op.model.Op;
	import engine.battle.ability.model.BattleAbilityEvent;
	import engine.battle.ability.model.BattleAbilityRetargetInfo;
	import engine.battle.ability.model.IBattleAbility;
	import engine.battle.ability.phantasm.model.ChainPhantasms;
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.entity.model.BattleEntityEvent;
	import engine.stat.def.StatType;
	import engine.stat.model.IStatModProvider;
	import engine.stat.model.Stats;
	import engine.tile.Tile;

	public class Effect extends EventDispatcher implements IEffect, IEffectTagProvider, IStatModProvider
	{
		public var def : IEffectDef;
		private var _ability : IBattleAbility;
		public var result : EffectResult;
		public var applied : Boolean;
		public var useCount : int;
		public var casterTurnCount : int;
		public var targetTurnCount : int;
		private var _phase : EffectPhase;
		private var ops : Vector.<Op> = new Vector.<Op>;
		private var _tags : Dictionary = new Dictionary;
		public static var executing : Boolean = false;
		private var _target : IBattleEntity;
		public var tile : Tile;
		private var _waitForAbility : IBattleAbility;
		public var chain : ChainPhantasms;
		public var removeReason : EffectRemoveReason = EffectRemoveReason.DEFAULT;
		private var _blockedComplete : int = 0;

		public function Effect(ability : IBattleAbility, def : IEffectDef, target : IBattleEntity, tile : Tile)
		{
			this.target = target;
			this.tile = tile;
			this.ability = ability;
			this.def = def;

			for each (var tag : EffectTag in def.tags)
			{
				tags[tag] = tag;
			}
		}

		public function get target() : IBattleEntity
		{
			return _target;
		}

		public function set target(value : IBattleEntity) : void
		{
			_target = value;
		}

		public function cleanup() : void
		{
			removeReason = EffectRemoveReason.CLEANUP;
			remove();
		}

		override public function toString() : String
		{
			return "[action=" + ability.def.id + " eff=" + def.name + " -> " + target + "]";
		}

		public function addTag(tag : EffectTag) : void
		{
			tags[tag] = tag;

			if (ability.manager.faking)
			{
				return;
			}

			if (target.effects.hasEffect(this))
			{
				target.effects.addTag(tag);
			}
		}

		public function hasTag(tag : EffectTag) : Boolean
		{
			return tags[tag] != null;
		}

		/**
		 * Computations about what to do to the targets occurs here.  Target characters don't actually change yet
		 * @return
		 *
		 */
		public function execute() : EffectResult
		{
			if (!ability.manager.faking && !ability.fake)
			{
				def.logger.debug("Effect.execute EXECUTING " + ability.caster.id + " " + this + " target=" + target + " tile=" + tile);
			}
			else
			{
				if (hasTag(EffectTag.NO_FAKING))
				{
					result = EffectResult.FAIL;
					phase = EffectPhase.EXECUTED;
					return result;
				}
			}

			if (executing)
			{
				throw new IllegalOperationError("do not re-enter effect execution");
			}

			// check conditions

			phase = EffectPhase.EXECUTING;

			executing = true;

			for each (var edo : EffectDefOp in def.ops)
			{
				executeOp(edo);
			}

			if (!ability.manager.faking && !ability.fake)
			{
				def.logger.debug("Effect.execute EXECUTED " + this + " result=" + result);
			}

			phase = EffectPhase.EXECUTED;

			executing = false;
			if (result == null)
			{
				// ability doesn't have an op so default to OK/success
				result = EffectResult.OK;
			}

			return result;
		}

		public function executeOp(edo : EffectDefOp) : void
		{
			var op : Op = edo.construct(this);

			ops.push(op);

			if (!ability.manager.faking && !ability.fake)
			{
				def.logger.debug("Effect.executeOp " + op);
			}

			var opResult : EffectResult = op.execute();

			op.result = opResult;

			if (!ability.manager.faking && !ability.fake)
			{
				def.logger.debug("Effect.executeOp " + op + " result=" + op.result);
			}

			// not sure what the meaning of mixed results should be for the ops
			result = opResult.combineUp(result);
		}

		private function checkPreStack() : Boolean
		{
			if (def.persistent)
			{
				if (def.persistent.stack != EffectStackRule.STACK)
				{
					for each (var other : Effect in target.effects.effects)
					{
						if (other.ability.def.root == ability.def.root && other.def.name == def.name)
						{
							if (def.persistent.stack == EffectStackRule.REPLACE_LOWER)
							{
								if (other.ability.def.level >= ability.def.level)
								{
									def.logger.debug("Effect.checkPreStack persist " + ability.caster.id + " cannot replace");
									// can't replace it, so just bail
									return false;
								}
							}
							if (def.persistent.stack == EffectStackRule.REPLACE_LOWER_EQUAL)
							{
								if (other.ability.def.level > ability.def.level)
								{
									def.logger.debug("Effect.checkPreStack persist " + ability.caster.id + " cannot replace");
									// can't replace it, so just bail
									return false;
								}
							}
						}
					}
				}
			}

			return true;
		}

		/**
		 * Actual changes to the target characters occur here
		 *
		 */
		public function apply() : void
		{
			if (!ability.manager.faking && !ability.fake)
			{
				def.logger.debug("Effect.apply " + ability.caster.id + " " + this);
			}

			if (applied)
			{
				return;
			}

			if (_waitForAbility)
			{
				if (_waitForAbility.completed)
				{
					_waitForAbility = null;
				}
				else
				{
					readyToApply = true;
					def.logger.debug("Effect.apply deferring because _waitForAbility " + _waitForAbility + " is not complete");
					return;
				}
			}

			applied = true;

			phase = EffectPhase.APPLYING;

			var canStack : Boolean = checkPreStack();

			if (!canStack)
			{
				result = EffectResult.FAIL;
			}
			else
			{
				for each (var op : Op in ops)
				{
					def.logger.debug("Effect.apply " + this.def.name + " APPLY OP " + op);
					op.apply();
				}
			}

			phase = EffectPhase.APPLIED;

			if (!ability.manager.faking)
			{
				if (target && !target.alive)
				{
					if (ability.fake)
					{
						throw new IllegalOperationError("killing effect in fake");
					}
					target.killingEffect = this;
				}

				// persistent effects stick around for a while, possibly affecting future effects
				if (def.persistent && result == EffectResult.OK)
				{
					def.logger.debug("Effect.apply persist " + ability.caster.id + " " + this);

					if (def.persistent.stack != EffectStackRule.STACK)
					{
						for each (var other : Effect in target.effects.effects)
						{
							if (other.ability.def.root == ability.def.root && other.def.name == def.name)
							{
								def.logger.debug("Effect.apply unstacking " + ability.caster.id + " " + this);
								// remove old effect in favor of new one
								other.remove();
							}
						}
					}

					target.effects.addEffect(this);
					ability.caster.addEventListener(BattleEntityEvent.ALIVE, handleCasterDeath);
				}
			}

			if (!ability.manager.faking && !ability.fake)
			{
				if (result == EffectResult.MISS)
				{
					target.handleMissed(this);
				}

				if (hasTag(EffectTag.RESISTING))
				{
					target.handleResisted(this);
				}
			}
		}

		protected function handleCasterDeath(evt : BattleEntityEvent) : void
		{
			if (!evt.entity.alive)
			{
			//	checkExpiration();
			}
		}

		public function casterStartTurn() : Boolean
		{
			if (ability.manager.faking)
			{
				return false;
			}

			var found : Boolean;
			for each (var op : Op in ops)
			{
				found = op.casterStartTurn() || found;
			}

			if (found)
			{
				++useCount;
			}

			++casterTurnCount;

			checkExpiration();

			return found;
		}

		public function targetStartTurn() : Boolean
		{
			if (ability.manager.faking)
			{
				return false;
			}

			var found : Boolean = false;

			for each (var op : Op in ops)
			{
				found = op.targetStartTurn() || found;
			}

			if (found)
			{
				++useCount;
			}

			++targetTurnCount;

			checkExpiration();

			return found;
		}

		/**
		 * removal of a persistent effect undos any changes that apply() did, usually
		 *
		 */
		public function remove() : void
		{
			if (ability.manager.faking && !ability.fake)
			{
				return;
			}

			phase = EffectPhase.REMOVING;

			ability.caster.removeEventListener(BattleEntityEvent.ALIVE, handleCasterDeath);

			for each (var op : Op in ops)
			{
				op.remove();
			}

			// linked effects
			if (def.persistent.linkedEffectName != null)
			{
				var linkedEffect : Effect = ability.getEffectByName(def.persistent.linkedEffectName);
				if (linkedEffect != null)
				{
					def.logger.debug("#### removing linked effect");
					linkedEffect.removeReason = EffectRemoveReason.LINKED_EFFECT;
					linkedEffect.remove();
				}
			}

			phase = EffectPhase.REMOVED;
		}

		protected function handleRemove() : void
		{

		}

		public function handleUsed() : void
		{
			if (ability.manager.faking && !ability.fake)
			{
				return;
			}

			++useCount;
			checkExpiration();
		}

		public function checkExpiration() : void
		{
			if (!def.persistent)
			{
				return;
			}

			if (!ability.caster.alive)
			{
				removeReason = EffectRemoveReason.CASTER_DEATH;
				remove();
			}
			else if (def.persistent.numUses > 0 && useCount >= def.persistent.numUses)
			{
				removeReason = EffectRemoveReason.USE_COUNT;
				remove();
			}
			else if (def.persistent.casterDuration > 0 && casterTurnCount >= def.persistent.casterDuration)
			{
				removeReason = EffectRemoveReason.CASTER_DURATION;
				remove();
			}
			else if (def.persistent.targetDuration > 0 && targetTurnCount >= def.persistent.targetDuration)
			{
				removeReason = EffectRemoveReason.TARGET_DURATION;
				remove();
			}
		}

		public function forceExpiration() : void
		{
			removeReason = EffectRemoveReason.FORCED_EXPIRATION;
			remove();
		}

		public function get phase() : EffectPhase
		{
			return _phase;
		}

		public function set phase(value : EffectPhase) : void
		{
			if (_phase != value)
			{
				_phase = value;

				// if this is a phase change to which we might trigger a response, let the caster and target know about it

				ability.onEffectPhaseChange(this);
				if (ability.caster.effects)
				{
					ability.caster.effects.onCasterEffectPhaseChange(this);
				}

				if (target.effects)
				{
					target.effects.onTargetEffectPhaseChange(this);
				}

				if (_phase == EffectPhase.REMOVED)
				{
					dispatchEvent(new EffectEvent(EffectEvent.REMOVED));
				}
			}
		}

		public function getOpByName(n : String) : Op
		{
			for each (var op : Op in ops)
			{
				if (op.def.name == n)
				{
					return op;
				}
			}
			return null;
		}

		public function onAbilityExecutingOnTarget(abl : IBattleAbility) : BattleAbilityRetargetInfo
		{
			for each (var op : Op in ops)
			{
				var ari : BattleAbilityRetargetInfo = op.onAbilityExecutingOnTarget(abl);
				if (ari)
				{
					return ari;
				}
			}

			return null;
		}

		public function get waitForAbility() : IBattleAbility
		{
			return _waitForAbility;
		}

		public function set waitForAbility(value : IBattleAbility) : void
		{
			if (_waitForAbility != value)
			{
				if (_waitForAbility)
				{
					_waitForAbility.removeEventListener(BattleAbilityEvent.ABILITY_PRE_COMPLETE, waitForAbilityPreComplete);
				}

				_waitForAbility = value;

				if (_waitForAbility)
				{
					_waitForAbility.addEventListener(BattleAbilityEvent.ABILITY_PRE_COMPLETE, waitForAbilityPreComplete);
				}
			}
		}

		private var readyToApply : Boolean;

		protected function waitForAbilityPreComplete(event : BattleAbilityEvent) : void
		{
			if (event.ability == _waitForAbility)
			{
				def.logger.debug("Effect.waitForAbilityPreComplete " + event.ability);

				_waitForAbility = null;

				if (chain)
				{
					chain.onWaitAbilityComplete();
				}

				if (readyToApply)
				{
					apply();
				}
			}
		}

		// IStatModProvider
		public function get removed() : Boolean
		{
			return this.phase == EffectPhase.REMOVED
		}

		public function get ability() : IBattleAbility
		{
			return _ability;
		}

		public function set ability(value : IBattleAbility) : void
		{
			_ability = value;
		}

		public function get tags() : Dictionary
		{
			return _tags;
		}

		private var annotatedStatChanges : Stats;

		public function annotateStatChange(type : StatType, delta : int) : void
		{
			if (!annotatedStatChanges)
			{
				annotatedStatChanges = new Stats(null, true);
			}

			annotatedStatChanges.addStat(type, annotatedStatChanges.getBase(type) + delta);
		}

		public function getAnnotatedStatChange(type : StatType) : int
		{
			return annotatedStatChanges ? annotatedStatChanges.getBase(type) : 0;
		}

		public function get isBlockedComplete() : Boolean
		{
			return _blockedComplete > 0;
		}

		public function get blockedComplete() : int
		{
			return _blockedComplete;
		}

		public function set blockedComplete(value : int) : void
		{
			if (_blockedComplete == value)
			{
				return;
			}

			_blockedComplete = value;
			if (_blockedComplete == 0)
			{
				ability.onEffectUnblocked(this);
			}
		}

		public function blockComplete() : void
		{
			++blockedComplete;
		}

		public function unblockComplete() : void
		{
			--blockedComplete;
		}

	}
}
