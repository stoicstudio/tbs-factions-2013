package engine.battle.ability.model
{
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import engine.battle.ability.def.BattleAbilityDef;
	import engine.battle.ability.def.BattleAbilityRotationRule;
	import engine.battle.ability.def.BattleAbilityTargetRotationRule;
	import engine.battle.ability.def.BattleAbilityTargetRule;
	import engine.battle.ability.effect.def.EffectDefConditions;
	import engine.battle.ability.effect.def.IEffectDef;
	import engine.battle.ability.effect.model.Effect;
	import engine.battle.ability.effect.model.EffectPhase;
	import engine.battle.ability.phantasm.model.ChainPhantasms;
	import engine.battle.ability.phantasm.model.ChainPhantasmsEvent;
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.fsm.BattleMove;
	import engine.stat.def.StatType;
	import engine.stat.model.Stat;
	import engine.tile.Tile;

	public class BattleAbility extends EventDispatcher implements IBattleAbility
	{
		private var _parent : IBattleAbility;
		private var _def : BattleAbilityDef;

		public function set targetSet(value : BattleTargetSet) : void
		{
			_targetSet = value;
		}

		private var callback : Function;
		private var _caster : IBattleEntity;
		public var chains : Vector.<ChainPhantasms> = new Vector.<ChainPhantasms>;
		public var effects : Vector.<Effect> = new Vector.<Effect>;
		private var _executed : Boolean;
		private var _executing : Boolean;
		private var _completed : Boolean;
		private var abilityPreCompletionTriggered : Boolean;
		private var abilityPostCompletionTriggered : Boolean;
		private var children : Vector.<BattleAbility> = new Vector.<BattleAbility>;
		private var tags : Dictionary = new Dictionary;
		private var _targetSet : BattleTargetSet;
		private var _manager : BattleAbilityManager;
		public var id : int;
		private var targetsAffected : int = 0;
		private var _fake : Boolean;
		private var _executedId : int;
		private var _blockedComplete : int = 0;

		public function BattleAbility(caster : IBattleEntity, def : BattleAbilityDef, manager : BattleAbilityManager)
		{
			if (caster == null)
			{
				manager.logger.error("Must have a caster for battle ability " + def);
				throw new IllegalOperationError("no caster");
			}
			this.caster = caster;
			this.id = manager.nextId;
			this._def = def;
			this._manager = manager;
			_targetSet = new BattleTargetSet(this);

			if (_manager.faking)
			{
				_fake = true;
			}
		}

		public static function getStatChange(def : BattleAbilityDef, caster : IBattleEntity, stat : StatType, result : StatChangeData, target : IBattleEntity, themove : BattleMove) : Boolean
		{

			var valid : BattleAbilityValidation = BattleAbilityValidation.validate(def as BattleAbilityDef, caster, themove, target, null, false, false);
			var delta : int = -1;

			if (valid == BattleAbilityValidation.OK && target.stats.getValue(stat) > 0)
			{
				var oldTile : Tile = caster.tile;

				try
				{
					// we must move the entity in a fakey way into position so the ability can evaluate from the battlemove destination
					caster.suppressMoveEvents = true;
					if (themove)
					{
						caster.setPos(themove.last.x, themove.last.y);
					}
					caster.board.fake = true;
					var battleAbility : BattleAbility = new BattleAbility(caster, def, caster.board.abilityManager);
					battleAbility.targetSet.setTarget(target);
					var val0 : int = target.stats.getValue(stat);
					battleAbility.execute(null);
					result.missChance = target.stats.getValue(StatType.FAKE_MISS_CHANCE);
					var val1 : int = target.stats.getValue(stat);
					delta = val0 - val1;
				}
				catch (e : Error)
				{
					caster.board.logger.error("Something went wrong while faking " + stat + " with " + def + ": " + e.getStackTrace());
					return false;
				}

				caster.board.fake = false;
				caster.setPos(oldTile.x, oldTile.y);
				caster.suppressMoveEvents = false;
			}
			else
			{
				return false;
			}

			result.amount = delta;
			return true;
		}

		public function get root() : IBattleAbility
		{
			if (parent)
			{
				return parent.root;
			}
			return this;
		}

		private function get debugCasterId() : String
		{
			return (caster ? caster.id : "null")
		}

		override public function toString() : String
		{
			return "[" + executedId + " " + debugCasterId + "->" + targetSet.debugIds + " " + def.id + "/" + def.level + "]";
		}

		private function executeTiles() : void
		{
			var delay : int = 0;
			for each (var tile : Tile in targetSet.tiles)
			{
				var targetAffected : Boolean;
				var allowRotation : Boolean = shouldAllowRotation();
				var allowTargetRotation : Boolean = shouldAllowTargetRotation();

				for each (var ed : IEffectDef in def.effects)
				{
					var effect : Effect;

					// can this effect go?
					if (!checkEffectConditions(ed))
					{
						continue;
					}

					var valid : BattleAbilityValidation = BattleAbilityValidation.validate(def, caster, null, targetSet.baseTarget, tile, false, false);
					if (valid == BattleAbilityValidation.OK)
					{
						if (!targetAffected)
						{
							targetAffected = true;
							++targetsAffected;
						}

						// all abilities are required to have at least one target
						effect = new Effect(this, ed, targetSet.baseTarget, tile);
						executeEffect(effect, delay, allowRotation, allowTargetRotation);
					}
				}

				delay += def.targetDelay;
			}
		}

		private function shouldAllowRotation() : Boolean
		{
			switch (def.rotationRule)
			{
				case BattleAbilityRotationRule.FIRST_TARGET:
					return targetsAffected == 0;
				case BattleAbilityRotationRule.ALL_TARGETS:
					return true;
				case BattleAbilityRotationRule.NONE:
					return false;
			}
			return false;
		}

		private function shouldAllowTargetRotation() : Boolean
		{
			switch (def.targetRotationRule)
			{
				case BattleAbilityTargetRotationRule.FACE_CASTER:
					return true;
				case BattleAbilityTargetRotationRule.NONE:
					return false;
			}
			return false;
		}

		private function executeTargetEffectDef(target : IBattleEntity, ed : IEffectDef, delay : int, allowRotation : Boolean, allowTargetRotation : Boolean, validate : Boolean, ari : BattleAbilityRetargetInfo) : Boolean
		{
			if (!fake && !manager.faking)
			{
				manager.logger.debug("BattleAbility.executeTargetEffectDef() " + target + " " + ed);
			}

			var effect : Effect;

			// can this effect go?
			if (!checkEffectConditions(ed))
			{
				return false;
			}

			if (ari)
			{
				target = ari.target;
			}

			var dtile : Tile = targetSet.baseTile;

			var valid : BattleAbilityValidation;
			if (validate)
			{
				valid = BattleAbilityValidation.validate(def, caster, null, target, dtile, false, false);
			}
			if (!validate || valid == BattleAbilityValidation.OK)
			{
				// all abilities are required to have at least one target
				effect = new Effect(this, ed, target, dtile);
				effect.waitForAbility = ari ? ari.insert : null;
				executeEffect(effect, delay, allowRotation, allowTargetRotation);
				return true;
			}
			else
			{
				if (!fake && !manager.faking)
				{
					manager.logger.debug("BattleAbility.executeTargetEffectDef() could not validate effect " + this.def.id + "," + ed.name + " for target " + target.id + " validation=" + valid);
				}
			}

			return false;
		}

		private function executeTargets() : void
		{
			var dtile : Tile = targetSet.baseTile;
			var delay : int = 0;
			var ed : IEffectDef;

			// see if we need to run any of the effects on the caster
			for each (ed in def.effects)
			{
				if (ed.targetCaster)
				{
					executeTargetEffectDef(caster, ed, delay, false, false, false, null);
				}
			}

			for each (var target : IBattleEntity in targetSet.targets)
			{
				var targetAffected : Boolean;
				var allowRotation : Boolean = shouldAllowRotation();
				var allowTargetRotation : Boolean = shouldAllowTargetRotation();

				var ari : BattleAbilityRetargetInfo = target.effects.onAbilityExecutingOnTarget(this);
				if (ari)
				{
					if (!fake && !manager.faking)
					{
						manager.logger.debug("BattleAbility.executeTargets() " + this + " retargeted " + target + " to " + ari);
					}
				}

				for each (ed in def.effects)
				{
					// targetCaster has already been taken care of above
					if (ed.targetCaster)
					{
						continue;
					}

					var validate : Boolean = ari == null;
					if (executeTargetEffectDef(target, ed, delay, allowRotation, allowTargetRotation, validate, ari))
					{
						if (!targetAffected)
						{
							targetAffected = true;
							++targetsAffected;
						}
					}
				}

				delay += def.targetDelay;
			}
		}

		public function checkCosts(probe : Boolean = false) : Boolean
		{
			var ok : Boolean = true;

			if (def.horn)
			{
				if (caster.party.hornSize < def.horn)
				{
					if (!probe && !fake && !manager.faking)
					{
						manager.logger.error("Not enough HORN for " + this);
					}
					ok = false;
				}
			}

			const numStats : int = def.costs.numStats;
			for (var i : int = 0; i < numStats; ++i)
			{
				var cost : Stat = def.costs.getStatByIndex(i);
				if (cost.value > caster.stats.getValue(cost.type))
				{
					if (!probe && !fake && !manager.faking)
					{
						manager.logger.error("Not enough " + cost.type + " for " + this);
					}

					ok = false;
				}
			}

			return ok;
		}

		private function deductCosts() : Boolean
		{
			if (!checkCosts())
			{
				return false;
			}

			if (!fake && !manager.faking)
			{
				if (def.horn)
				{
					caster.party.hornSize -= def.horn;
				}

				const numStats : int = def.costs.numStats;
				for (var i : int = 0; i < numStats; ++i)
				{
					var cost : Stat = def.costs.getStatByIndex(i);
					caster.stats.getStat(cost.type).base -= cost.value;
				}
			}

			return true;
		}

		public function execute(callback : Function) : void
		{
			if (executed || executing)
			{
				throw new IllegalOperationError("no, no, no");
			}

			if (!_manager.enabled)
			{
				// nothing to do
				return;
			}

			var nid : int = manager.nextExecutedId;
			if (_executedId != 0 && nid != _executedId)
			{
				manager.logger.error("DIVERGENCE Ability: " + this + ", should be id " + _executedId);
			}

			_executedId = nid;

			executing = true;

			if (!deductCosts())
			{
				manager.logger.error("Attempt to execute ability without being able to pay the costs " + this);
				// fail.
				checkCompletion();
				return;
			}

			this.callback = callback;

			if (targetSet.targets.length == 0)
			{
				targetSet.setTarget(caster);
			}

			if (!fake && !manager.faking)
			{
				manager.logger.debug("BattleAbility.execute() " + this);
			}

			if (def.targetRule == BattleAbilityTargetRule.TILE_EMPTY || def.targetRule == BattleAbilityTargetRule.TILE_ANY)
			{
				executeTiles();
			}
			else
			{
				executeTargets();
			}

			executing = false;
			executed = true;

			checkCompletion();
		}

		public function addChildAbility(child : IBattleAbility) : void
		{
			if (child == this)
			{
				throw new IllegalOperationError("epic failure of parenting");
			}

			if (!_manager.enabled)
			{
				// nothing to do
				return;
			}
			child.parent = this;
			children.push(child);
			child.execute(null);
		}

		private function checkEffectConditions(ed : IEffectDef) : Boolean
		{
			for each (var c : EffectDefConditions in ed.conditions)
			{
				if (c.other)
				{
					var other : Effect = getEffectByName(c.other);
					if (!other)
					{
						return false;
					}

					if (!c.isResultSatisfactory(other.result))
					{
						return false;
					}
				}

				if (c.minLevel > def.level)
				{
					return false;
				}
			}

			return true;
		}

		public function getEffectByName(en : String) : Effect
		{
			for each (var effect : Effect in effects)
			{
				if (effect.def.name == en)
				{
					return effect;
				}
			}

			return null;
		}

		public function getEffectByDef(ed : IEffectDef) : Effect
		{
			for each (var effect : Effect in effects)
			{
				if (effect.def == ed)
				{
					return effect;
				}
			}

			return null;
		}

		public function executeEffect(effect : Effect, delay : int, allowRotation : Boolean, allowTargetRotation : Boolean) : void
		{
			effects.push(effect);

			effect.execute();

			if (effect.def.phantasms != null)
			{
				if (!fake && !manager.faking)
				{
					var chain : ChainPhantasms = caster.createChainForEffect(effect) as ChainPhantasms;
					if (chain)
					{
						chains.push(chain);
						chain.addEventListener(ChainPhantasmsEvent.ENDED, phantasmsEndedHandler);
						chain.addEventListener(ChainPhantasmsEvent.APPLIED, phantasmAppliedHandler);

						// this call to start can cause the phantasmsEndedHandler() to fire immediately
						// however, we must supress calls to checkCompletion, because we might have more effects to process
						chain.start(delay, allowRotation, allowTargetRotation);
					}
				}
			}

			// TODO allow the effect itself to indicate that it is ready to complete, even without a chain

			if (!chain)
			{
				effect.apply();
				effect.phase = EffectPhase.COMPLETED;
			}
		}

		protected function phantasmAppliedHandler(event : ChainPhantasmsEvent) : void
		{
			event.chain.effect.apply();
			handlePhantasmsEnded(event.chain);
		}

		private function handlePhantasmsEnded(chain : ChainPhantasms) : void
		{
			if (chain.ended)
			{
				chain.removeEventListener(ChainPhantasmsEvent.ENDED, phantasmsEndedHandler);
				chain.removeEventListener(ChainPhantasmsEvent.APPLIED, phantasmAppliedHandler);

				var index : int = chains.indexOf(chain);

				if (index >= 0)
				{
					chains.splice(index, 1);
				}

				chain.effect.phase = EffectPhase.COMPLETED;
				chain.cleanup();
				checkCompletion();
			}
		}

		protected function phantasmsEndedHandler(event : ChainPhantasmsEvent) : void
		{
			handlePhantasmsEnded(event.chain);
		}

		private function checkChildCompletion() : Boolean
		{
			// child completion blocks parent completion
			for each (var child : BattleAbility in children)
			{
				// waiting on child
				if (!child.completed)
				{
					manager.logger.debug("BattleAbility.checkCompletion checkChildCompletion " + this + " WAITING CHILD " + child);

					return false;
				}
			}

			return true;
		}

		public function checkCompletion() : void
		{
			if (completed)
			{
				if (!fake && !manager.faking)
				{
					//manager.logger.debug("BattleAbility.checkCompletion ALREADY COMPLETED");
				}
				return;
			}

			// don't complete before we have finished executing!
			// this can get hit if a phantasm completes immediately, but we have more effects to execute
			if (!executed)
			{
				if (!fake && !manager.faking)
				{
					//manager.logger.debug("BattleAbility.checkCompletion FALSE " + this + " NOT EXECUTED");
				}

				return;
			}

			// no more phantasms to display
			if (chains.length > 0)
			{
				if (!fake && !manager.faking)
				{
					//manager.logger.debug("BattleAbility.checkCompletion FALSE " + this + " CHAINS REMAIN");
				}
				return;
			}

			if (blockedComplete)
			{
				return;
			}

			for each (var effect : Effect in effects)
			{
				if (effect.isBlockedComplete)
				{
					if (!fake && !manager.faking)
					{
						manager.logger.debug("BattleAbility.checkCompletion FALSE " + this + " EFFECT BLOCKED " + effect);
					}
					return;
				}
			}

			for each (var chain : ChainPhantasms in chains)
			{
				if (!chain.ended)
				{
					if (!fake && !manager.faking)
					{
						//manager.logger.debug("BattleAbility.checkCompletion FALSE " + this + " CHAIN NOT ENDED " + chain);
					}
					return;
				}
			}

			// waiting on children to complete
			if (!checkChildCompletion())
			{
				if (!fake && !manager.faking)
				{
					//manager.logger.debug("BattleAbility.checkCompletion FALSE " + this + " NOT checkChildCompletion");
				}
				return;
			}

			// ok now give a one-time chance for responses to the bottom-up completion of abilities

			if (!abilityPreCompletionTriggered)
			{
				abilityPreCompletionTriggered = true;

				dispatchEvent(new BattleAbilityEvent(BattleAbilityEvent.ABILITY_PRE_COMPLETE, this));
				manager.onAbilityPreComplete(this);

				// that trigger might have caused something to get childed

				if (!checkChildCompletion())
				{
					if (!fake && !manager.faking)
					{
						//manager.logger.debug("BattleAbility.checkCompletion checkChildCompletion FALSE " + this);
					}
					return;
				}
			}

			completed = true;

			if (!fake && !manager.faking)
			{
				manager.logger.debug("BattleAbility.checkCompletion COMPLETED " + this + ", children=" + children.length);
			}

			// let any parents know about our readiness to complete.  this will generate another chance for more children to appear

			if (parent)
			{
				parent.checkCompletion();
			}

			if (completed)
			{
				handlePostComplete();
			}
		}

		private function handlePostComplete() : void
		{
			if (!completed)
			{
				return;
			}

			if (!abilityPostCompletionTriggered)
			{
				abilityPostCompletionTriggered = true;

				dispatchEvent(new BattleAbilityEvent(BattleAbilityEvent.ABILITY_POST_COMPLETE, this));

				manager.onAbilityPostComplete(this);
				if (!checkChildCompletion())
				{
					completed = false;
					return;
				}
			}

			// it would be fail sauce for an ability to be added to 'us'
			for each (var child : BattleAbility in children)
			{
				child.handlePostComplete();

				if (!child.completed)
				{
					completed = false;
				}
			}

			if (!completed)
			{
				return;
			}

			if (!finalCompleted)
			{
				// finally done.  and your little dog, too

				dispatchEvent(new BattleAbilityEvent(BattleAbilityEvent.ABILITY_AND_CHILDREN_COMPLETE, this));

				manager.onAbilityAndChildrenComplete(this);

				setFinalCompleted();
			}
		}

		private var _finalCompleted : Boolean;

		public function onEffectPhaseChange(e : Effect) : void
		{
			for each (var chain : ChainPhantasms in chains)
			{
				chain.onEffectPhaseChange(e);
			}
		}

		public function get executed() : Boolean
		{
			return _executed;
		}

		public function set executed(value : Boolean) : void
		{
			_executed = value;
		}

		public function get executing() : Boolean
		{
			return _executing;
		}

		public function set executing(value : Boolean) : void
		{
			if (_executing == value)
			{
				return;
			}

			_executing = value;
			dispatchEvent(new BattleAbilityEvent(BattleAbilityEvent.EXECUTING, this));
			manager.onAbilityExecuting(this);
		}

		public function get completed() : Boolean
		{
			return _completed;
		}

		public function set completed(value : Boolean) : void
		{
			_completed = value;
		}

		public function get finalCompleted() : Boolean
		{
			return _finalCompleted;
		}

		public function setFinalCompleted() : void
		{
			if (finalCompleted)
			{
				return;
			}

			_finalCompleted = true;

			if (callback != null)
			{
				callback(this);
				callback = null;
			}

			dispatchEvent(new BattleAbilityEvent(BattleAbilityEvent.FINAL_COMPLETE, this));

			manager.onAbilityFinalComplete(this);
		}

		public function get caster() : IBattleEntity
		{
			return _caster;
		}

		public function set caster(value : IBattleEntity) : void
		{
			_caster = value;
		}

		public function get def() : BattleAbilityDef
		{
			return _def;
		}

		public function get targetSet() : BattleTargetSet
		{
			return _targetSet;
		}

		public function get parent() : IBattleAbility
		{
			return _parent;
		}

		public function set parent(value : IBattleAbility) : void
		{
			_parent = value;
		}

		public function get manager() : BattleAbilityManager
		{
			return _manager;
		}

		public function get fake() : Boolean
		{
			return _fake;
		}

		public function get executedId() : int
		{
			return _executedId;
		}

		public function internalSetexecutedId(value : int) : void
		{
			_executedId = value;
		}

		public function removeAllEffects() : void
		{
			for each (var eff : Effect in effects)
			{
				if (eff.phase != EffectPhase.REMOVED)
				{
					eff.remove();
				}
			}
		}

		public function onEffectUnblocked(effect : Effect) : void
		{
			checkCompletion();
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
				checkCompletion();
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
