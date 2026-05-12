package engine.battle.board.view.overlay
{
	import flash.display.Bitmap;
	import flash.geom.Point;

	import engine.battle.BattleAssetsDef;
	import engine.battle.ability.def.BattleAbilityTargetRule;
	import engine.battle.ability.model.BattleAbility;
	import engine.battle.board.IsoBattleRectangleUtils;
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.board.view.BattleBoardView;
	import engine.battle.board.view.EntityLinkedDirtyRenderSprite;
	import engine.battle.fsm.BattleFsmEvent;
	import engine.battle.fsm.BattleTurn;
	import engine.core.util.UtilFunctions;
	import engine.math.MathUtil;
	import engine.tile.Tile;
	import engine.tile.def.TileLocation;

	public class AbilityDestinationOverlay extends EntityLinkedDirtyRenderSprite
	{
		public function AbilityDestinationOverlay(sceneView : BattleBoardView)
		{
			super(sceneView);

			fsm.addEventListener(BattleFsmEvent.TURN_ABILITY, fsmEventHandler);
			fsm.addEventListener(BattleFsmEvent.TURN_ABILITY_TARGETS, fsmEventHandler);
			fsm.addEventListener(BattleFsmEvent.TURN_COMMITTED, fsmEventHandler);

			var assets : BattleAssetsDef = view.board.assets;

			view.bitmapPool.addPool(assets.board_move_arrow_special_north, 3, 16);
			view.bitmapPool.addPool(assets.board_move_arrow_special_south, 3, 16);
		}

		override public function cleanup() : void
		{
			fsm.removeEventListener(BattleFsmEvent.TURN_ABILITY, fsmEventHandler);
			fsm.removeEventListener(BattleFsmEvent.TURN_ABILITY_TARGETS, fsmEventHandler);
			fsm.removeEventListener(BattleFsmEvent.TURN_COMMITTED, fsmEventHandler);
		}

		private function removeAllArrows() : void
		{
			while (numChildren > 0)
			{
				var b : Bitmap = removeChildAt(numChildren - 1) as Bitmap;
				if (b)
				{
					view.bitmapPool.reclaim(b);
				}
			}
		}

		override protected function handleCanRenderChanged() : void
		{
			if (!canRender)
			{
				removeAllArrows();
			}
		}

		override protected function onRender() : void
		{
			removeAllArrows();

			const turn : BattleTurn = fsm.turn;
			const ability : BattleAbility = turn ? turn.ability : null;

			if (!turn || turn.committed || !ability || ability.targetSet.targets.length == 0)
			{
				return;
			}

			const target : IBattleEntity = ability.targetSet.targets[0];
			const start : TileLocation = target.tile.location;

			var resultDistance : int = 0;
			var endTile : Tile = null;
			for (var j : int = ability.def.maxResultDistance; j >= ability.def.minResultDistance; --j)
			{
				endTile = UtilFunctions.getTileAvailableBehindAtDist(ability.caster, target, j);

				if (endTile != null)
				{
					resultDistance = j;
					break;
				}
			}

			if (!endTile)
			{
				return;
			}

			const hw : Number = target.width / 2;
			const hl : Number = target.length / 2;

			const end : TileLocation = endTile.location;

			const delta : Point = new Point(MathUtil.clampValue(end.x - start.x, -1, 1), MathUtil.clampValue(end.y - start.y, -1, 1));
			for (var i : int = i; i < resultDistance; ++i)
			{
				var p0 : TileLocation = TileLocation.fetch(start.x + delta.x * i, start.y + delta.y * i);
				var p1 : TileLocation = TileLocation.fetch(start.x + delta.x * (i + 1), start.y + delta.y * (i + 1));
				var arrow : Bitmap = getArrow(p0, p1);

				addChild(arrow);

				var mx : Number = (p0.x + p1.x) / 2 + hw;
				var my : Number = (p0.y + p1.y) / 2 + hl;
				var dp : Point = IsoBattleRectangleUtils.getIsoPointScreenPoint(view.units, mx, my);
				arrow.x = dp.x - (arrow.scaleX * arrow.width / 2);
				arrow.y = dp.y - arrow.height / 2;
			}
		}

		private function getArrow(src : TileLocation, dst : TileLocation) : Bitmap
		{
			const dx : int = dst.x - src.x;
			const dy : int = dst.y - src.y;

			var b : Bitmap;

			if (dx > 0)
			{
				b = view.bitmapPool.pop(view.board.assets.board_move_arrow_special_south);
				b.scaleX = 1;
			}
			else if (dy < 0)
			{
				b = view.bitmapPool.pop(view.board.assets.board_move_arrow_special_north);
				b.scaleX = 1;
			}
			else if (dy > 0)
			{
				b = view.bitmapPool.pop(view.board.assets.board_move_arrow_special_south);
				b.scaleX = -1;
			}
			else if (dx < 0)
			{
				b = view.bitmapPool.pop(view.board.assets.board_move_arrow_special_north);
				b.scaleX = -1;
			}

			return b;
		}

		private function fsmEventHandler(event : BattleFsmEvent) : void
		{
			checkCanRender();
			setRenderDirty();
		}

		override protected function checkCanRender() : void
		{
			const turn : BattleTurn = fsm.turn;
			const ability : BattleAbility = turn ? turn.ability : null;

			if (turn && !turn.committed)
			{
				if (ability)
				{
					if (ability.def.targetRule === BattleAbilityTargetRule.SPECIAL_BATTERING_RAM)
					{
						if (ability.targetSet.targets.length > 0)
						{
							canRender = true;
							return;
						}
					}
				}
			}

			canRender = false;
		}
	}
}
