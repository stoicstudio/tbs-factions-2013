package engine.battle.ability.effect.op.model
{
	import engine.battle.ability.effect.model.Effect;
	import engine.battle.ability.effect.model.EffectResult;
	import engine.battle.ability.effect.op.def.EffectDefOp;
	import engine.battle.ability.model.BattleAbilityRetargetInfo;
	import engine.battle.ability.model.IBattleAbility;
	import engine.battle.board.model.IBattleEntity;
	import engine.stat.def.StatType;
	import engine.stat.model.Stat;
	import engine.tile.Tile;

	public class Op
	{
		public var effect : Effect;
		public var result : EffectResult;
//		public var chain : ChainPhantasms;
		public var def : EffectDefOp;

		public function Op(def : EffectDefOp, effect : Effect)
		{
			this.def = def;
			this.effect = effect;
//			chain = null;
//
//			if (effect.def.phantasms)
//			{
//				chain = new ChainPhantasms(effect);
//			}
		}

		public function toString() : String
		{
			return "Op [" + def + " " + result + " " + effect + "]";
		}

		public function execute() : EffectResult
		{
			return EffectResult.OK;
		}

		public function apply() : void
		{

		}

		public function remove() : void
		{

		}

		public function targetStartTurn() : Boolean
		{
			return false;
		}

		public function casterStartTurn() : Boolean
		{
			return false;
		}

//		public function otherAbilityComplete(abl : Ability) : Boolean
//		{
//return false;
//		}

//		public function get scene() : CombatSceneModel
//		{
//			return effect.ability.caster.scene;
//		}

		// TODO remove CombatCharacterModel dep in favor of IAbilityTarget
//		public function get target() : CombatCharacterModel
//		{
//			return effect.target as CombatCharacterModel;
//		}

		public function get target() : IBattleEntity
		{
			return effect.target;
		}

		public function get caster() : IBattleEntity
		{
			return effect.ability.caster;
		}

		public function get tile() : Tile
		{
			return effect.tile;
		}

		public function onAbilityExecutingOnTarget(abl : IBattleAbility) : BattleAbilityRetargetInfo
		{
			return null;
		}

		protected function requireStat(from : IBattleEntity, type : StatType) : Stat
		{
			var stat : Stat = from.stats.getStat(type);
			if (!stat)
			{
				throw new ArgumentError("Op.requireStat " + from.id + " does not have stat " + type);
			}
			return stat;
		}
	}
}
