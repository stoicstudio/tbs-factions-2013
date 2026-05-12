package engine.battle.ability.effect.op.def
{
	import engine.battle.ability.effect.op.model.*;

	public class IdEffectOpRegistry
	{
		private static var registered : Boolean;

		public static function register() : void
		{
			if (registered)
			{
				return;
			}

			registered = true;

			IdEffectOp.ADJACENT_ARMOR_BONUS.register(Op_AdjacentArmorBonus, EffectDefOpVars);
			IdEffectOp.BATTERING_RAM.register(Op_BatteringRam, EffectDefOpVars);
			IdEffectOp.BLOODYFLAIL_DAMAGE.register(Op_BloodyFlail, EffectDefOpVars);
			IdEffectOp.CHANGE_STAT.register(Op_ChangeStat, EffectDefOpVars);
			IdEffectOp.COURAGE.register(Op_DamageCourage, EffectDefOpVars);
			IdEffectOp.DAMAGE_STR.register(Op_DamageStr, EffectDefOpVars);
			IdEffectOp.DAMAGE_ARM.register(Op_BreakArm, OpDef_DamageArm);
			IdEffectOp.END_TURN.register(Op_EndTurn, EffectDefOpVars);
			IdEffectOp.EXEC_ABILITY.register(Op_ExecAbility, OpDef_ExecAbility);
			IdEffectOp.EXPIRE_EFFECTS.register(Op_ExpireEffects, EffectDefOpVars);
			IdEffectOp.HEAVYIMPACT_DAMAGE.register(Op_HeavyImpactDamage, EffectDefOpVars);
			IdEffectOp.INITIATIVE.register(Op_Initiative, EffectDefOpVars);
			IdEffectOp.INT_STAT_MOD.register(Op_IntStatMod, EffectDefOpVars);
			IdEffectOp.POSSESS_ENTITY.register(Op_PossessEntity, EffectDefOpVars);
			IdEffectOp.RETARGET.register(Op_Retarget, EffectDefOpVars);
			IdEffectOp.RUN_THROUGH.register(Op_RunThrough, EffectDefOpVars);
			IdEffectOp.STOP_MOVING.register(Op_StopMoving, EffectDefOpVars);
			IdEffectOp.SUSPEND_TARGET.register(Op_SuspendTarget, EffectDefOpVars);
			IdEffectOp.TILE_TRIGGER.register(Op_TileTrigger, EffectDefOpVars);
			IdEffectOp.PLACE_TILE_TRIGGER.register(Op_PlaceTileTrigger, EffectDefOpVars);
			IdEffectOp.TILE_AOE.register(Op_TileAOE, EffectDefOpVars);
			IdEffectOp.WAIT_FOR_ACTION_COMPLETE.register(Op_WaitForActionComplete, EffectDefOpVars);
			IdEffectOp.WAIT_FOR_DAMAGE_STR.register(Op_WaitForDamageStr, EffectDefOpVars);
			IdEffectOp.WAIT_FOR_START_TURN.register(Op_WaitForStartTurn, EffectDefOpVars);
			IdEffectOp.AURA.register(Op_Aura, EffectDefOpVars);
			IdEffectOp.SLAGANDBURN_TILECROSS.register(Op_SlagAndBurnTileCross, EffectDefOpVars);
			IdEffectOp.MOVE_TO_RANGE.register(Op_MoveToRange, EffectDefOpVars);

			IdEffectOp.ensureRegistrations();
		}
	}
}
