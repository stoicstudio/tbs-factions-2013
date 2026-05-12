package engine.battle.ability.def
{
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.entity.model.BattleEntity;
	import engine.core.util.Enum;
	import engine.core.util.UtilFunctions;
	import engine.tile.Tile;

	public class BattleAbilityTargetRule extends Enum
	{
		public static const NONE : BattleAbilityTargetRule = new BattleAbilityTargetRule("NONE", enumCtorKey);
		public static const FRIENDLY : BattleAbilityTargetRule = new BattleAbilityTargetRule("FRIENDLY", enumCtorKey);
		public static const SELF : BattleAbilityTargetRule = new BattleAbilityTargetRule("SELF", enumCtorKey);
		public static const FRIENDLY_OTHER : BattleAbilityTargetRule = new BattleAbilityTargetRule("FRIENDLY_OTHER", enumCtorKey);
		public static const ENEMY : BattleAbilityTargetRule = new BattleAbilityTargetRule("ENEMY", enumCtorKey);
		public static const TILE_ANY : BattleAbilityTargetRule = new BattleAbilityTargetRule("TILE_ANY", enumCtorKey);
		public static const TILE_EMPTY : BattleAbilityTargetRule = new BattleAbilityTargetRule("TILE_EMPTY", enumCtorKey);
		public static const ANY : BattleAbilityTargetRule = new BattleAbilityTargetRule("ANY", enumCtorKey);
		public static const ADJACENT_BATTLEENTITY : BattleAbilityTargetRule = new BattleAbilityTargetRule("ADJACENT_BATTLEENTITY", enumCtorKey);
		public static const ENEMY_NEIGHBORS : BattleAbilityTargetRule = new BattleAbilityTargetRule("ENEMY_NEIGHBORS", enumCtorKey);

		// axial, enemy, empty space behind them
		public static const SPECIAL_RUN_THROUGH : BattleAbilityTargetRule = new BattleAbilityTargetRule("SPECIAL_RUN_THROUGH", enumCtorKey);

		// melee range, axial clear path
		public static const SPECIAL_BATTERING_RAM : BattleAbilityTargetRule = new BattleAbilityTargetRule("SPECIAL_BATTERING_RAM", enumCtorKey);

		// axial
		public static const SPECIAL_SLAG_AND_BURN : BattleAbilityTargetRule = new BattleAbilityTargetRule("SPECIAL_SLAG_AND_BURN", enumCtorKey);

		public function BattleAbilityTargetRule(name : String, secret : Object)
		{
			super(name, secret);
		}

		public function isValid(caster : IBattleEntity, target : IBattleEntity, tile : Tile, anyTile : Boolean, battleAbilityDef : BattleAbilityDef = null) : Boolean
		{
			if (target != null && target.mobile == false)
			{
				return false;
			}

			switch (this)
			{
				case NONE:
					return true;
				case FRIENDLY:
					return target != null && caster.team == target.team;
				case ENEMY:
				{
					if (target != null && target.alive && (target is BattleEntity) && caster.team != target.team)
					{
						return true;
					}
					return false;
				}
				case ADJACENT_BATTLEENTITY:
				{
					if (target != null && target != caster && target.alive && (target is BattleEntity))
					{
						return true;
					}
					return false;
				}
				case ENEMY_NEIGHBORS:
				{
					// This target type is the neighbors of the target.  It is OK for the target itself to be dead (ie: heavy impact)
					if (target != null && (target is BattleEntity) && caster.team != target.team)
					{
						return true;
					}
					return false;
				}
				case SELF:
					return target != null && caster == target;
				case FRIENDLY_OTHER:
					return target != null && caster.team == target.team && caster != target;
				case TILE_ANY:
				case TILE_EMPTY:
					// tiles are handled especially 
					return tile != null || anyTile;
				case ANY:
					return target != null;
				case SPECIAL_RUN_THROUGH:
				{
					// Axial and empty space behind
					if (target != null && (target is BattleEntity) && caster.team != target.team)
					{
						if (UtilFunctions.isAxialEntity2Entity(caster, target) == false)
						{
							return false;
						}

						var behind : Tile = UtilFunctions.getTileAvailableBehind(caster, target);

						if (behind)
						{
							if (UtilFunctions.axialPathClearOfBlockers(caster, behind.x, behind.y) == true)
							{
								return true;
							}
						}
					}
					return false;
				}
				case SPECIAL_BATTERING_RAM:
				{
					if (target != null && (target is BattleEntity))
					{
						if (UtilFunctions.isAxialEntity2Entity(caster, target) == false)
						{
							return false;
						}

						if (battleAbilityDef != null)
						{
							var availTile : Tile = null;

							for (var i : int = battleAbilityDef.maxResultDistance; i >= battleAbilityDef.minResultDistance; --i)
							{
								availTile = UtilFunctions.getTileAvailableBehindAtDist(caster, target, i);
								if (availTile)
								{
									if (UtilFunctions.axialPathClearOfBlockers(target, availTile.x, availTile.y) == true)
									{
										return true;
									}
								}
							}
						}
					}
					return false;
				}
			}
			return false;
		}
	}
}
