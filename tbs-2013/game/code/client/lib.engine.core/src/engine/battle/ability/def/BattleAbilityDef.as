package engine.battle.ability.def
{
	import engine.ability.def.AbilityDef;
	import engine.ability.def.AbilityDefFactory;
	import engine.battle.ability.effect.def.EffectDef;
	import engine.battle.ability.effect.def.EffectStackRule;
	import engine.battle.ability.effect.def.EffectTagReqs;
	import engine.battle.ability.effect.def.IEffectDef;

	public class BattleAbilityDef extends AbilityDef implements IBattleAbilityDef
	{
		public var rangeMin : int;
		public var rangeMax : int;
		public var targetRule : BattleAbilityTargetRule;
		public var targetCount : int;
		public var rangeType : BattleAbilityRangeType;
		public var casterEffectTagReqs : EffectTagReqs;
		public var targetEffectTagReqs : EffectTagReqs;
		public var maxMove : int;

		public var targetDelay : int;
		public var tag : BattleAbilityTag;
		public var stackRule : EffectStackRule;
		public var effects : Vector.<EffectDef> = new Vector.<EffectDef>;
		public var rotationRule : BattleAbilityRotationRule = BattleAbilityRotationRule.FIRST_TARGET;
		public var targetRotationRule : BattleAbilityTargetRotationRule = BattleAbilityTargetRotationRule.FACE_CASTER;
		public var tileTargetUrl : String = "common/battle/tile/enemy_target_1.png";

		public var moveTag : BattleAbilityMoveTag = BattleAbilityMoveTag.NONE;
		public var suppressOptionalStars : Boolean = true;
		public var minResultDistance : int = 0;
		public var maxResultDistance : int = 0;

		public function BattleAbilityDef(root : BattleAbilityDef = null)
		{
			super(root);
		}

		/**
		 * Levels everywhere to are referred as one-based.
		 * @param level
		 * @return
		 *
		 */
		public function getBattleAbilityDefLevel(level : int) : BattleAbilityDef
		{
			return super.getAbilityDefForLevel(level) as BattleAbilityDef;
		}

		public function get battleAbilityDefRoot() : BattleAbilityDef
		{
			return super.root as BattleAbilityDef;
		}

		override public function link(factory : AbilityDefFactory) : void
		{
			for each (var e : IEffectDef in effects)
			{
				var ed : EffectDef = e as EffectDef;
				if (ed)
				{
					ed.link(factory as BattleAbilityDefFactory);
				}
			}
		}

		public function getEffectDefByName(name : String) : IEffectDef
		{
			for each (var e : IEffectDef in effects)
			{
				if (e.name == name)
				{
					return e;
				}
			}

			return null;
		}

	}
}
