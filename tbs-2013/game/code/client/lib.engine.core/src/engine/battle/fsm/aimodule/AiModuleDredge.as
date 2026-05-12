package engine.battle.fsm.aimodule
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	import engine.battle.ability.def.BattleAbilityDef;
	import engine.battle.ability.model.BattleAbility;
	import engine.battle.ability.model.BattleAbilityManager;
	import engine.battle.fsm.BattleMove;
	import engine.battle.fsm.state.BattleStateTurnAi;
	import engine.battle.fsm.state.turn.cmd.BattleTurnCmdAction;
	import engine.stat.def.StatType;
	import engine.tile.Tile;

	public class AiModuleDredge extends AiModuleBase
	{
		public function AiModuleDredge(state : BattleStateTurnAi)
		{
			super(state);
		}

		private var chosenPlan : AiPlan;

		private var plans : Vector.<AiPlan> = new Vector.<AiPlan>;

		private var timer : Timer = new Timer(0, 0);

		private var stars : int = 0;
		private var str1 : BattleAbilityDef = null;
		private var brk1 : BattleAbilityDef = null;

		public override function performMove() : Boolean
		{
			if (battleFsm.turn.suspended || ss.skipped)
			{
				return false;
			}

			timer.addEventListener(TimerEvent.TIMER, timerHandler);
			timer.start();

			var tileArray : Array;
			var targetTile : Tile;

			var exertion : int = caster.stats.getValue(StatType.EXERTION);
			var willpower : int = caster.stats.getValue(StatType.WILLPOWER);

			stars = Math.min(exertion, willpower);
			str1 = atkStr ? atkStr.def.getAbilityDefForLevel(1) as BattleAbilityDef : null;
			brk1 = atkArm ? atkArm.def.getAbilityDefForLevel(1) as BattleAbilityDef : null;

			return true;
		}

		private function timerHandler(event : TimerEvent) : void
		{
			tickAi();
		}

		private var brkIndex : int;
		private var strIndex : int;

		override public function cleanup() : void
		{
			if (timer)
			{
				timer.removeEventListener(TimerEvent.TIMER, timerHandler);
				timer.stop();
				timer = null;
			}

			super.cleanup();
		}

		private function tickAi() : void
		{
			if (str1)
			{
				if (strIndex < enemies.length)
				{
					strIndex = findPlans(str1, StatType.STRENGTH, enemies, plans, strIndex);
					return;
				}
			}

			if (brk1)
			{
				if (brkIndex < enemies.length)
				{
					brkIndex = findPlans(brk1, StatType.ARMOR, enemies, plans, brkIndex);
					return;
				}
			}

			if (!chosenPlan)
			{
				chooseBestPlan();
			}
		}

		private function chooseBestPlan() : void
		{
			timer.removeEventListener(TimerEvent.TIMER, timerHandler);
			timer.stop();

			plans.sort(AiPlan.compare);

			chosenPlan = plans.length > 0 ? plans[0] : null;

			if (!chosenPlan)
			{
				chosenPlan = makeNullPlan();
			}

			var mv : BattleMove = battleFsm.turn.move;

			if (chosenPlan)
			{
				ss.logger.debug("♕♔♘♞♛♜ CHOSE PLAN " + chosenPlan);

				var pmv : BattleMove = chosenPlan.mv;
				if (pmv)
				{
					for (var i : int = 1; i < pmv.numSteps; ++i)
					{
						mv.addStep(pmv.getStep(i));
					}
				}
			}

			mv.setCommitted("AiModuleDredge.performMove");
			battleFsm.turn.entity.mobility.executeMove(mv);

		}

		private function makeNullPlan() : AiPlan
		{
			return new AiPlan(this, null, null, null);
		}

		public override function performAction() : Boolean
		{
			if (!battleFsm || battleFsm.turn.suspended || ss.skipped)
			{
				return false;
			}

			var ablman : BattleAbilityManager = battleFsm.board.abilityManager;
			if (!chosenPlan.abldef)
			{
				if (battleFsm.turn.move.numSteps > 1)
				{
					chosenPlan.abldef = ablman.factory.fetch("abl_end") as BattleAbilityDef;
				}
				else
				{
					chosenPlan.abldef = ablman.factory.fetch("abl_rest") as BattleAbilityDef;
				}

				chosenPlan.target = null;
			}

			var abl_chosen : BattleAbility = new BattleAbility(caster, chosenPlan.abldef, ablman);
			if (chosenPlan.target)
			{
				abl_chosen.targetSet.setTarget(chosenPlan.target);
			}
			ss.cmdSeq.addCmd(new BattleTurnCmdAction(ss, 0, true, abl_chosen, true));

			//phase = StatePhase.COMPLETED;

			return true;
		}

		protected function test01_move() : void
		{
			var myTile : Tile = battleFsm.turn.entity.tile;
			var tileX : int = myTile.x;
			var tileY : int = myTile.y;
			var testTile : Tile;

			--tileX;
			testTile = battleFsm.board.tiles.getTile(tileX, tileY);
			battleFsm.turn.move.addStep(testTile);

			--tileY;
			testTile = battleFsm.board.tiles.getTile(tileX, tileY);
			battleFsm.turn.move.addStep(testTile);

			++tileX;
			testTile = battleFsm.board.tiles.getTile(tileX, tileY);
			battleFsm.turn.move.addStep(testTile);

			++tileY;
			testTile = battleFsm.board.tiles.getTile(tileX, tileY);
			battleFsm.turn.move.addStep(testTile);

			battleFsm.turn.move.setCommitted("tes01_move");
			battleFsm.turn.entity.mobility.executeMove(battleFsm.turn.move);
		}

		protected function test02_move() : void
		{
			var myTile : Tile = battleFsm.turn.entity.tile;
			var tileX : int = myTile.x;
			var tileY : int = myTile.y;
			var testTile : Tile;

			++tileY
			testTile = battleFsm.board.tiles.getTile(tileX, tileY);
			battleFsm.turn.move.addStep(testTile);

			++tileY;
			testTile = battleFsm.board.tiles.getTile(tileX, tileY);
			battleFsm.turn.move.addStep(testTile);

			--tileY;
			testTile = battleFsm.board.tiles.getTile(tileX, tileY);
			battleFsm.turn.move.addStep(testTile);

			--tileY;
			testTile = battleFsm.board.tiles.getTile(tileX, tileY);
			battleFsm.turn.move.addStep(testTile);

			battleFsm.turn.move.setCommitted("test02_move");
			battleFsm.turn.entity.mobility.executeMove(battleFsm.turn.move);
		}
	}
}
