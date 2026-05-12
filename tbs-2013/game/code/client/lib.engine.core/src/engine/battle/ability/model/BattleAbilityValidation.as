package engine.battle.ability.model
{
	import engine.battle.ability.def.BattleAbilityDef;
	import engine.battle.ability.def.BattleAbilityRangeType;
	import engine.battle.ability.def.BattleAbilityTargetRule;
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.entity.model.BattleEntity;
	import engine.battle.fsm.BattleMove;
	import engine.core.logging.ILogger;
	import engine.core.util.UtilFunctions;
	import engine.stat.def.StatType;
	import engine.stat.model.Stat;
	import engine.tile.ITileResident;
	import engine.tile.Tile;
	import engine.tile.def.TileLocation;
	import engine.tile.def.TileRect;
	import engine.tile.def.TileRectRange;

	public class BattleAbilityValidation
	{
		public static const OK : BattleAbilityValidation = new BattleAbilityValidation("OK");
		public static const OUT_OF_RANGE : BattleAbilityValidation = new BattleAbilityValidation("OUT_OF_RANGE");
		public static const INSUFFICIENT_TILE : BattleAbilityValidation = new BattleAbilityValidation("INSUFFICIENT_TILE");
		public static const INVALID_TARGET : BattleAbilityValidation = new BattleAbilityValidation("INVALID_TARGET");
		public static const MOVED : BattleAbilityValidation = new BattleAbilityValidation("MOVED");
		public static const INSUFFICIENT_STARS : BattleAbilityValidation = new BattleAbilityValidation("INSUFFICIENT_STARS");
		public static const INAPPROPRIATE_TAGS : BattleAbilityValidation = new BattleAbilityValidation("INAPPROPRIATE_TAGS");

		public var name : String;

		public function BattleAbilityValidation(name : String)
		{
			this.name = name;
		}

		private static function validateMovement(def : BattleAbilityDef, movePlan : BattleMove) : Boolean
		{
			if (def.maxMove >= 0)
			{
				if (movePlan)
				{
					if ((movePlan.numSteps - 1) > def.maxMove)
					{
						return false;
					}
				}
			}

			return true;
		}

		public static function validateCosts(def : BattleAbilityDef, caster : IBattleEntity, move : BattleMove, logger : ILogger) : Boolean
		{
			var ok : Boolean = true;

			var moveStars : int = 0;

			if (move && !move.committed)
			{
				moveStars = Math.max(0, (move.numSteps - 1) - caster.stats.getValue(StatType.MOVEMENT));
			}

			if (def.horn)
			{
				if (caster.party.hornSize < def.horn)
				{
					if (logger)
					{
						logger.error("Not enough HORN");
					}
					return false;
				}
			}

			for each (var cost : Stat in def.costs)
			{
				var value : int = caster.stats.getValue(cost.type);
				if (cost.type == StatType.WILLPOWER)
				{
					var exertion : int = caster.stats.getValue(StatType.EXERTION);

					if (exertion < cost.value)
					{
						if (logger)
						{
							logger.error("Not enough EXERTION (" + exertion + "/" + cost.value + ") for " + def.id + " by " + caster.id);
						}
						else
						{
							return false;
						}
					}

					value -= moveStars;
				}

				if (cost.value > value)
				{
					ok = false;

					if (logger)
					{
						logger.error("Not enough " + cost.type + " (" + value + "/" + cost.value + ") for " + def.id + " by " + caster.id);
					}
					else
					{
						return false;
					}
				}
			}
			return ok;
		}

		private static function validateTags(def : BattleAbilityDef, caster : IBattleEntity, target : IBattleEntity) : Boolean
		{
			if (def.casterEffectTagReqs)
			{
				if (!def.casterEffectTagReqs.checkTags(caster.effects))
				{
					return false;
				}
			}

			if (def.targetEffectTagReqs)
			{
				if (!target || !def.targetEffectTagReqs.checkTags(target.effects))
				{
					return false;
				}
			}
			return true;
		}

		public static function validate(def : BattleAbilityDef, caster : IBattleEntity, movePlan : BattleMove, target : IBattleEntity, tile : Tile, anyTile : Boolean, checkCosts : Boolean) : BattleAbilityValidation
		{
			// did caster move too far already?
			if (!validateMovement(def, movePlan))
			{
				return MOVED;
			}

			// TODO: data-drive the costs as a list of stat values to deduct
			if (checkCosts && !validateCosts(def, caster, movePlan, null))
			{
				return INSUFFICIENT_STARS;
			}

			if (!validateTags(def, caster, target))
			{
				return INAPPROPRIATE_TAGS;
			}

			if (!def.targetRule.isValid(caster, target, tile, anyTile, def))
			{
				return INVALID_TARGET;
			}

			var v : BattleAbilityValidation = validateRange(def, caster, movePlan, target, tile);

			if (v != OK)
			{
				return v;
			}

			if (def.targetRule == BattleAbilityTargetRule.TILE_EMPTY || def.targetRule == BattleAbilityTargetRule.TILE_ANY)
			{
				if (tile)
				{
					// todo: data drive this blocking with a def rule (any tile, unblocked tile, self tile, etc...)					
					var tileResident : ITileResident = tile.findResident(caster);
					if (tileResident != null)
					{
						// Rule TILE_ANY still blocks with non-mobile entities (props)
						if (def.targetRule == BattleAbilityTargetRule.TILE_EMPTY || tileResident.mobile == false)
						{
							return INVALID_TARGET;
						}
					}
				}
			}

			return OK;
		}

		public static function validateRange(def : BattleAbilityDef, caster : IBattleEntity, movePlan : BattleMove, target : IBattleEntity, tile : Tile) : BattleAbilityValidation
		{
			if (BattleAbilityRangeType.NONE == def.rangeType)
			{
				return OK;
			}
			
			if (target != null)
			{
				if (target.mobile == false)
				{
					return INVALID_TARGET;
				}

				if (target.tile == null)
				{
					return INVALID_TARGET;
				}
			}

			// zero range means infinite

			if (def.rangeType != BattleAbilityRangeType.NONE && (def.rangeMax > 0 || def.rangeMin > 0))
			{
				var dist : int = -1;

				var rect : TileRect = movePlan ? new TileRect(movePlan.last.location, caster.width, caster.length) : caster.rect;
				if (def.targetRule == BattleAbilityTargetRule.TILE_EMPTY || def.targetRule == BattleAbilityTargetRule.TILE_ANY)
				{
					if (tile != null)
					{
						dist = TileRectRange.computeRange(rect, tile.rect);
					}
				}
				else if (def.targetRule == BattleAbilityTargetRule.SPECIAL_RUN_THROUGH)
				{
					var behind : Tile = UtilFunctions.getTileAvailableBehind(caster, target);
					if (!behind)
					{
						return INSUFFICIENT_TILE;
					}
					dist = TileRectRange.computeRange(rect, behind.rect) - 1;
				}
				else if (def.targetRule == BattleAbilityTargetRule.SPECIAL_BATTERING_RAM)
				{
					dist = TileRectRange.computeRange(rect, target.rect);
				}
				else if (target != null)
				{
					dist = TileRectRange.computeRange(rect, target.rect);
				}

				if (dist >= 0)
				{
					if (dist > def.rangeMax)
					{
						// too far
						return OUT_OF_RANGE;
					}

					if (dist < def.rangeMin)
					{
						// too close
						return OUT_OF_RANGE;
					}
				}

				// AXIAL
				if (target != null && (def.targetRule == BattleAbilityTargetRule.SPECIAL_RUN_THROUGH || def.targetRule == BattleAbilityTargetRule.SPECIAL_BATTERING_RAM))
				{
					if (UtilFunctions.isAxialEntity2Entity(caster, target) == false)
					{
						return OUT_OF_RANGE;
					}

				}
			}

			return OK;
		}

		public function toString() : String
		{
			return "[" + name + "]";
		}
	}
}
