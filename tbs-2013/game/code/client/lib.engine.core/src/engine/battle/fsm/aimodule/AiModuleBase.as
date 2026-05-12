package engine.battle.fsm.aimodule
{
	import flash.utils.getTimer;

	import engine.ability.def.AbilityDefLevel;
	import engine.battle.ability.def.BattleAbilityDef;
	import engine.battle.ability.def.BattleAbilityDefLevels;
	import engine.battle.ability.def.BattleAbilityTag;
	import engine.battle.entity.model.BattleEntity;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.BattleMove;
	import engine.battle.fsm.state.BattleStateTurnAi;
	import engine.stat.def.StatType;
	import engine.tile.Tile;

	public class AiModuleBase
	{
		public var ss : BattleStateTurnAi;
		public var battleFsm : BattleFsm;
		public var caster : BattleEntity;
		public var enemies : Vector.<BattleEntity> = new Vector.<BattleEntity>;
		public var friends : Vector.<BattleEntity> = new Vector.<BattleEntity>;

		public var isRanged : Boolean = false;
		public var atkStr : AbilityDefLevel;
		public var atkArm : AbilityDefLevel;

		public function AiModuleBase(state : BattleStateTurnAi)
		{
			battleFsm = state.battleFsm;
			ss = state;

			caster = battleFsm.turn.entity as BattleEntity;
			buildEnemyArray();

			var batks : BattleAbilityDefLevels = battleFsm.turn.entity.def.attacks as BattleAbilityDefLevels;
			atkStr = batks.getFirstAbilityByTag(BattleAbilityTag.ATTACK_STR);
			atkArm = batks.getFirstAbilityByTag(BattleAbilityTag.ATTACK_ARM);

			// TODO: this is good for simple classes, but more will be needed in derived modules for mixed melee/ranged classes if we get them
			isRanged = (atkStr.id == "abl_bow_str" || atkArm.id == "abl_bow_arm");

		}

		public function performMove() : Boolean
		{
			return false;
		}

		public function performAction() : Boolean
		{
			return false;
		}

		public function cleanup() : void
		{
			battleFsm = null;
			caster = null;
			enemies = null;
			atkStr = null;
			atkArm = null;
		}

		protected function buildEnemyArray() : void
		{
			enemies.splice(0, enemies.length);
			for each (var entity : BattleEntity in battleFsm.board.entities)
			{
				if (entity.alive)
				{
					if (entity.team != caster.team)
					{
						enemies.push(entity);
					}
					else
					{
						friends.push(entity);
					}
				}
			}
		}

		private function constructRestPlan() : AiPlan
		{
			var abl_rest : BattleAbilityDef = ss.battleFsm.board.abilityManager.factory.fetch("abl_rest") as BattleAbilityDef;
			return new AiPlan(this, null, abl_rest, null);
		}

		public function findPlans(abldef : BattleAbilityDef, stat : StatType, tgs : Vector.<BattleEntity>, results : Vector.<AiPlan>, start : int) : int
		{
			var exe : int = caster.stats.getValue(StatType.EXERTION);
			var wp : int = caster.stats.getValue(StatType.WILLPOWER);
			var wpe : int = Math.min(exe, wp);
			var wp_orig : int = caster.stats.getStat(StatType.WILLPOWER).original;
			var mr : int = caster.def.stats.getValue(StatType.MOVEMENT);
			var casterRank : int = caster.def.stats.getValue(StatType.RANK);

			var i : int = start;
			for (; i < tgs.length; ++i)
			{
				if (i > start)
				{
					return i;
				}
				var b : BattleEntity = tgs[i];
				// todo some specials' ranks affect range! e.g. bird of prey
				var plan : AiPlan = null;
				var gtg : Array = [false];
				var move : BattleMove = BattleMove.computeMoveToRange(abldef, caster, b, ss.logger, wpe, gtg);
				if (move)
				{
					if (!gtg[0])
					{
						// can't attack from ending location.						
						// compare relative threats

						var from_weight : int = AiPlan.computePositionalWeight(this, this.caster.tile, null);
						var to_weight : int = AiPlan.computePositionalWeight(this, move.last, null);

						if (to_weight <= from_weight)
						{
							// the target location is equally or less desirable than the current

							if (wp < wp_orig && wp < exe)
							{
								// willpower is depleted, let's just rest, up to exertion
								plan = constructRestPlan();
								results.push(plan);
								continue;
							}
						}

						plan = new AiPlan(this, move, null, b);
						results.push(plan);
						continue;
					}

					var mstars : int = Math.max(0, move.numSteps - 1 - mr);
					wpe -= mstars;
				}

				if (gtg[0])
				{
					var maxRank : int;
					if (abldef.tag == BattleAbilityTag.SPECIAL)
					{
						maxRank = Math.min(wpe, casterRank);
					}
					else
					{
						maxRank = Math.min(wpe + 1, abldef.maxLevel);
					}

					for (var rnk : int = 1; rnk <= maxRank; ++rnk)
					{
						var rabledef : BattleAbilityDef = abldef.getBattleAbilityDefLevel(rnk);
						plan = new AiPlan(this, move, rabledef, b);
						results.push(plan);
					}
				}
			}

			return i;
		}

		protected function isInRangeOfEnemyForAttack() : Boolean
		{
			return false;
		}

		// returns *all* empty tiles surrounding enemies
		protected function getMovementTargetTiles() : Array
		{
			var tileArray : Array = new Array();
			var tile : Tile;

			for each (var targetEntity : BattleEntity in enemies)
			{
				const x : int = targetEntity.pos.x;
				const y : int = targetEntity.pos.y;

				if (targetEntity.rect.width == 1)
				{
					addMovementTargetTile(x, y - 1, tileArray);

					addMovementTargetTile(x + 1, y, tileArray);
					addMovementTargetTile(x, y + 1, tileArray);
					addMovementTargetTile(x - 1, y, tileArray);

				}
				else if (targetEntity.rect.width == 2)
				{
					addMovementTargetTile(x, y + 2, tileArray);
					addMovementTargetTile(x + 1, y + 2, tileArray);
					addMovementTargetTile(x + 2, y + 1, tileArray);
					addMovementTargetTile(x + 2, y, tileArray);

					addMovementTargetTile(x, y - 1, tileArray);
					addMovementTargetTile(x + 1, y - 1, tileArray);
					addMovementTargetTile(x - 1, y + 1, tileArray);
					addMovementTargetTile(x - 1, y, tileArray);
				}
			}

			return tileArray;
		}

		protected function addMovementTargetTile(x : int, y : int, tiles : Array) : void
		{
			var tile : Tile = battleFsm.board.tiles.getTile(x, y);

			if (tile != null && tiles.indexOf(tile) == -1)
			{
				if (battleFsm.board.tiles.isTileBlockedForEntity(caster, tile) == false)
				{
					tiles.push(tile);
				}
			}
		}

		protected function getNearestTile(tiles : Array) : Tile
		{
			var ret : Tile = null;
			var shortestDistance2 : int = int.MAX_VALUE;

			for each (var tile : Tile in tiles)
			{
				var dx : int = tile.x - caster.x;
				var dy : int = tile.y - caster.y;

				var dist2 : int = dx * dx + dy * dy;
				if (dist2 < shortestDistance2)
				{
					shortestDistance2 = dist2;
					ret = tile;
				}
			}

			return ret;
		}

	}
}
