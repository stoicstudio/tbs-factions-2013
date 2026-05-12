
package engine.battle.ability.effect.op.model
{
	import flash.utils.Dictionary;

	import engine.battle.ability.def.BattleAbilityDef;
	import engine.battle.ability.def.BattleAbilityResponseTargetType;
	import engine.battle.ability.def.BattleAbilityTargetRule;
	import engine.battle.ability.def.IBattleAbilityDef;
	import engine.battle.ability.effect.def.EffectTagReqs;
	import engine.battle.ability.effect.def.EffectTagReqsVars;
	import engine.battle.ability.effect.model.Effect;
	import engine.battle.ability.effect.model.EffectTag;
	import engine.battle.ability.effect.op.def.EffectDefOp;
	import engine.battle.ability.model.BattleAbility;
	import engine.battle.ability.model.BattleAbilityEvent;
	import engine.battle.ability.model.BattleAbilityResponsePhase;
	import engine.battle.ability.model.IBattleAbility;
	import engine.battle.board.model.IBattleEntity;
	import engine.core.util.Enum;
	import engine.def.BooleanVars;
	import engine.def.NumberVars;

	public class Op_WaitForActionComplete extends Op
	{
		public static const schema : Object =
			{
				properties: {
					ability: {type: "string"},
					targetRule: {type: "string"},
					casterRule: {type: "string"},
					responseTarget: {type: "string"},
					responseCaster: {type: "string", optional: true},
					responsePhase: {type: "string"},
					tagReqs: {type: EffectTagReqsVars.schema, optional: true},
					respondsToSameAbilityDef: {type: "boolean", optional: true},
					responseTargetMustBeAlive: {type: "boolean", optional: true},
					ownerMustBeAlive: {type: "boolean", optional: true},
					effectMustBeIntact: {type: "boolean", optional: true},
					responseCountLimit: {type: "number", optional: true}
				}
			};

		private var ablDef : BattleAbilityDef;
		private var targetRule : BattleAbilityTargetRule;
		private var casterRule : BattleAbilityTargetRule;
		private var responseTarget : BattleAbilityResponseTargetType;
		private var responseCaster : BattleAbilityResponseTargetType = BattleAbilityResponseTargetType.CASTER;
		private var responsePhase : BattleAbilityResponsePhase;
		private var tagReqs : EffectTagReqs;
		private var operants : Dictionary = new Dictionary;
		private var respondsToSameAbilityDef : Boolean = false;
		private var responseTargetMustBeAlive : Boolean = true;
		private var ownerMustBeAlive : Boolean = true;
		private var effectMustBeIntact : Boolean = true;
		private var responseCountLimit : int = 1;
		public static var DEBUG_WAIT : Boolean = false;

		public function Op_WaitForActionComplete(def : EffectDefOp, effect : Effect)
		{
			super(def, effect);
			ablDef = effect.ability.manager.factory.fetchBattleAbilityDef(def.params.ability);
			targetRule = Enum.parse(BattleAbilityTargetRule, def.params.targetRule) as BattleAbilityTargetRule;
			casterRule = Enum.parse(BattleAbilityTargetRule, def.params.casterRule) as BattleAbilityTargetRule;
			responseTarget = Enum.parse(BattleAbilityResponseTargetType, def.params.responseTarget) as BattleAbilityResponseTargetType;

			if (def.params.responseCaster)
			{
				responseCaster = Enum.parse(BattleAbilityResponseTargetType, def.params.responseCaster) as BattleAbilityResponseTargetType;
			}
			responsePhase = Enum.parse(BattleAbilityResponsePhase, def.params.responsePhase) as BattleAbilityResponsePhase;

			respondsToSameAbilityDef = BooleanVars.parse(def.params.respondsToSameAbilityDef, respondsToSameAbilityDef);
			responseCountLimit = NumberVars.parse(def.params.responseCountLimit, responseCountLimit);

			responseTargetMustBeAlive = BooleanVars.parse(def.params.responseTargetMustBeAlive, responseTargetMustBeAlive);
			ownerMustBeAlive = BooleanVars.parse(def.params.ownerMustBeAlive, ownerMustBeAlive);
			effectMustBeIntact = BooleanVars.parse(def.params.effectMustBeIntact, effectMustBeIntact);

			if (def.params.tagReqs)
			{
				tagReqs = new EffectTagReqsVars(def.params.tagReqs, effect.ability.manager.logger);
			}
		}

		override public function apply() : void
		{
			if (responsePhase == BattleAbilityResponsePhase.PRE_COMPLETE)
			{
				effect.ability.manager.addEventListener(BattleAbilityEvent.ABILITY_PRE_COMPLETE, abilityCompleteHandler);
			}
			else if (responsePhase == BattleAbilityResponsePhase.POST_COMPLETE)
			{
				effect.ability.manager.addEventListener(BattleAbilityEvent.ABILITY_POST_COMPLETE, abilityCompleteHandler);
			}
			effect.ability.manager.addEventListener(BattleAbilityEvent.ABILITY_AND_CHILDREN_COMPLETE, abilityAndChildrenCompleteHandler);
		}

		private static function captureTagSet(v : Array, d : Dictionary) : void
		{
			for each (var s : String in v)
			{
				var t : EffectTag = Enum.parse(EffectTag, s) as EffectTag;
				d[t] = t;
			}
		}

		private function checkParents(other : IBattleAbility) : Boolean
		{
			var p : IBattleAbility = other;

			var myRoot : IBattleAbilityDef = effect.ability.def.root as IBattleAbilityDef;
			var rspRoot : IBattleAbilityDef = ablDef.root as IBattleAbilityDef;

			while (p)
			{
				if (p == effect.ability)
				{
					return false;
				}

				if (!respondsToSameAbilityDef)
				{
					if (p.def.root == myRoot)
					{
						return false;
					}

					if (p.def.root == rspRoot)
					{
						return false;
					}
				}

				var count : int = (p in operants) ? operants[p] : 0;

				if (responseCountLimit > 0 && count >= responseCountLimit)
				{
					// already responded to an operant in this hierarchy
					return false;
				}

				p = p.parent;
			}

			return true;
		}

		protected function abilityAndChildrenCompleteHandler(event : BattleAbilityEvent) : void
		{
			delete operants[event.ability];
		}

		protected function abilityCompleteHandler(event : BattleAbilityEvent) : void
		{
			const other : BattleAbility = event.ability as BattleAbility;

			if (effect.ability.fake || effect.ability.manager.faking || other.fake)
			{
				return;
			}

			if (DEBUG_WAIT)
			{
				effect.ability.manager.logger.debug("--->> Op_WaitForActionComplete " + effect.ability + " SAW " + other);
			}

			if (other.def.root == effect.ability.def.root)
			{
				if (DEBUG_WAIT)
				{
					effect.ability.manager.logger.debug("--->> Op_WaitForActionComplete " + effect.ability + " RETURN roots");
				}
				// don't respond to abilities of the same def
				return;
			}

			// this can happen because an earlier callback handler can complete the ability before it gets to our handler
			if (other.finalCompleted)
			{
				if (DEBUG_WAIT)
				{
					effect.ability.manager.logger.debug("--->> Op_WaitForActionComplete " + effect.ability + " RETURN other.finalCompleted");
				}

				return;
			}

			const otherRoot : IBattleAbility = other.root;

			if (!checkParents(other))
			{
				if (DEBUG_WAIT)
				{
					effect.ability.manager.logger.debug("--->> Op_WaitForActionComplete " + effect.ability + " RETURN !checkParents");
				}

				return;
			}

			if (!casterRule.isValid(effect.ability.caster, other.caster, null, true))
			{
				if (DEBUG_WAIT)
				{
					effect.ability.manager.logger.debug("--->> Op_WaitForActionComplete " + effect.ability + " RETURN !casterRule.isValid");
				}

				return;
			}

			if (ownerMustBeAlive && (!caster.alive || !target.alive))
			{
				if (DEBUG_WAIT)
				{
					effect.ability.manager.logger.debug("--->> Op_WaitForActionComplete " + effect.ability + " RETURN ownerMustBeAlive");
				}

				return;
			}

			if (effectMustBeIntact && effect.removed)
			{
				if (DEBUG_WAIT)
				{
					effect.ability.manager.logger.debug("--->> Op_WaitForActionComplete " + effect.ability + " RETURN effectMustBeIntact");
				}

				// all done, the owning effect is kaput
				return;
			}

			other.blockComplete();

			for each (var able : Effect in other.effects)
			{
				if (!targetRule.isValid(effect.ability.caster, able.target, able.tile, false))
				{
					if (DEBUG_WAIT)
					{
						effect.ability.manager.logger.debug("--->> Op_WaitForActionComplete " + effect.ability + " SKIP " + able + " !targetRule.isValid");
					}

					continue;
				}

				if (tagReqs && !tagReqs.checkTags(able))
				{
					if (DEBUG_WAIT)
					{
						effect.ability.manager.logger.debug("--->> Op_WaitForActionComplete " + effect.ability + " SKIP " + able + " !tagReqs.checkTags");
					}

					continue;
				}

				var count : int = (otherRoot in operants) ? operants[otherRoot] : 0;

				operants[otherRoot] = ++count;

				const rc : IBattleEntity = responseCaster == BattleAbilityResponseTargetType.TARGET ? able.ability.caster : caster;
				const child : BattleAbility = new BattleAbility(rc, ablDef, effect.ability.manager);

				// who.  shall.  we.  target!

				var rt : IBattleEntity;
				switch (responseTarget)
				{
					case BattleAbilityResponseTargetType.SELF:
						rt = caster;
						break;
					case BattleAbilityResponseTargetType.CASTER:
						rt = other.caster;
						break;
					case BattleAbilityResponseTargetType.TARGET:
						rt = able.target;
						break;
				}

				if (!rt)
				{
					if (DEBUG_WAIT)
					{
						effect.ability.manager.logger.debug("--->> Op_WaitForActionComplete " + effect.ability + " SKIP " + able + " !rt");
					}
					continue;
				}

				if (!rt.alive && responseTargetMustBeAlive == true)
				{
					if (DEBUG_WAIT)
					{
						effect.ability.manager.logger.debug("--->> Op_WaitForActionComplete " + effect.ability + " SKIP " + able + " responseTargetMustBeAlive");
					}
					continue;
				}

				child.targetSet.setTarget(rt);

//				effect.ability.manager.logger.debug("--->> Op_WaitForActionComplete " + effect.ability + "  RESPONDED TO " + other + "/" + able + " WITH " + child);

				other.addChildAbility(child);

				effect.handleUsed();

					// todo should we keep going through multiple effects and targets?
					//return;
			}

			other.unblockComplete();

			return;
		}
	}
}
