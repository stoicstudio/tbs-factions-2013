package engine.battle.board.view.overlay
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextField;

	import engine.battle.ability.def.BattleAbilityDef;
	import engine.battle.ability.def.BattleAbilityDefLevels;
	import engine.battle.ability.def.BattleAbilityTag;
	import engine.battle.ability.model.BattleAbility;
	import engine.battle.ability.model.StatChangeData;
	import engine.battle.board.view.BattleBoardView;
	import engine.battle.board.view.EntityLinkedDirtyRenderSprite;
	import engine.battle.entity.model.BattleEntity;
	import engine.battle.fsm.BattleFsmEvent;
	import engine.battle.fsm.BattleTurn;
	import engine.stat.def.StatType;

	public class DamageFlagOverlay extends EntityLinkedDirtyRenderSprite
	{
		private var _turn : BattleTurn;
		private const url : String = "common/battle/vfx/damage_flag.swf/gui_damage_flag";

		public function DamageFlagOverlay(sceneView : BattleBoardView)
		{
			super(sceneView);

			view.board.sim.fsm.addEventListener(BattleFsmEvent.TURN, turnHandler);
			view.board.sim.fsm.addEventListener(BattleFsmEvent.TURN_IN_RANGE, turnInRangeHandler);
			view.board.sim.fsm.addEventListener(BattleFsmEvent.INTERACT, interactHandler);

			view.movieClipPool.addPool(url, 2, 16);

		}

		override public function cleanup() : void
		{
			view.board.sim.fsm.removeEventListener(BattleFsmEvent.TURN_IN_RANGE, turnInRangeHandler);
			view.board.sim.fsm.removeEventListener(BattleFsmEvent.INTERACT, interactHandler);
			view.board.sim.fsm.removeEventListener(BattleFsmEvent.TURN, turnHandler);
		}

		override protected function onRender() : void
		{
			while (numChildren > 0)
			{
				var b : MovieClip = removeChildAt(numChildren - 1) as MovieClip;
				if (b)
				{
					view.movieClipPool.reclaim(b);
				}
			}

			var isAbilityTarget : Boolean = fsm.turn.ability && fsm.turn.ability.targetSet.hasTarget(entity);
			var isStandardTarget : Boolean = !fsm.turn.ability && fsm.turn.entity.playerControlled && fsm.interact == entity && entity in fsm.turn.inRange;
			if (isAbilityTarget || isStandardTarget || turn.committed || (!fsm.turn.committed && fsm.turn.ability))
			{
				return;
			}

			for each (var e : BattleEntity in _turn.inRange)
			{
				var damageFlag : MovieClip = view.movieClipPool.pop(url);
				var damageFlagText : TextField = damageFlag.getChildByName("damage_text") as TextField;
				var entX : Number = e.centerX * view.units;
				var entY : Number = e.centerY * view.units;
				var screen : Point = view.getScreenPoint(entX, entY);
				var batks : BattleAbilityDefLevels = turn.entity.def.attacks as BattleAbilityDefLevels;
				var scd : StatChangeData = new StatChangeData;
				BattleAbility.getStatChange(batks.getFirstAbilityByTag(BattleAbilityTag.ATTACK_STR).def as BattleAbilityDef, turn.entity as BattleEntity, StatType.STRENGTH, scd, e, turn.move);
				damageFlagText.text = scd.amount.toString();
				damageFlag.x = screen.x;
				damageFlag.y = screen.y + 8;
				addChild(damageFlag);
			}
		}

		private function turnHandler(event : BattleFsmEvent) : void
		{
			turn = view.board.sim.fsm.turn;
		}

		public function get turn() : BattleTurn
		{
			return _turn;
		}

		public function set turn(value : BattleTurn) : void
		{
			_turn = value;
			entity = turn ? turn.entity as BattleEntity : null;
			setRenderDirty();
		}

		private function interactHandler(event : BattleFsmEvent) : void
		{
			setRenderDirty();
		}

		private function turnInRangeHandler(event : BattleFsmEvent) : void
		{
			setRenderDirty();
		}

	}
}
