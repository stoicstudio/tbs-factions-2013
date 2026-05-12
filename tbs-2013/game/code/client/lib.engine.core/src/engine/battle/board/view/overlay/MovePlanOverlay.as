package engine.battle.board.view.overlay
{
	import flash.display.Bitmap;
	import flash.geom.Point;

	import engine.battle.BattleAssetsDef;
	import engine.battle.board.IsoBattleRectangleUtils;
	import engine.battle.board.view.BattleBoardView;
	import engine.battle.board.view.EntityLinkedDirtyRenderSprite;
	import engine.battle.entity.model.BattleEntity;
	import engine.battle.fsm.BattleFsmEvent;
	import engine.battle.fsm.BattleMoveEvent;
	import engine.battle.fsm.BattleTurn;
	import engine.path.PathFloodSolverNode;
	import engine.stat.def.StatType;
	import engine.tile.Tile;
	import engine.tile.def.TileLocation;

	public class MovePlanOverlay extends EntityLinkedDirtyRenderSprite
	{
		private var _turn : BattleTurn;

		public function MovePlanOverlay(sceneView : BattleBoardView)
		{
			super(sceneView);

			view.board.sim.fsm.addEventListener(BattleFsmEvent.TURN, turnHandler);
			view.board.sim.fsm.addEventListener(BattleFsmEvent.TURN_COMMITTED, fsmEventHandler);
			view.board.sim.fsm.addEventListener(BattleFsmEvent.INTERACT, interactHandler);

			var assets : BattleAssetsDef = view.board.assets;

			view.bitmapPool.addPool(assets.board_move_arrow_north, 2, 16);
			view.bitmapPool.addPool(assets.board_move_arrow_south, 2, 16);
			view.bitmapPool.addPool(assets.board_move_star_north, 0, 5);
			view.bitmapPool.addPool(assets.board_move_star_south, 0, 5);
		}

		override public function cleanup() : void
		{
			view.board.sim.fsm.removeEventListener(BattleFsmEvent.TURN_COMMITTED, fsmEventHandler);
			view.board.sim.fsm.removeEventListener(BattleFsmEvent.INTERACT, interactHandler);
			view.board.sim.fsm.removeEventListener(BattleFsmEvent.TURN, turnHandler);
		}

		private function comparePathFloodSolverNodes(a : PathFloodSolverNode, b : PathFloodSolverNode) : int
		{
			return a.g - b.g;
		}

		override protected function onRender() : void
		{
			while (numChildren > 0)
			{
				var b : Bitmap = removeChildAt(numChildren - 1) as Bitmap;
				if (b)
				{
					view.bitmapPool.reclaim(b);
				}
			}

			if (!_entity || !_turn || _turn.move.committed)
			{
				return;
			}

			var hw : Number = _entity.width / 2;
			var hl : Number = _entity.length / 2;

			for (var i : int = 1; i < _turn.move.numSteps; ++i)
			{
				var src : Tile = _turn.move.getStep(i - 1);
				var dst : Tile = _turn.move.getStep(i - 0);

				var star : Boolean = i > _entity.stats.getValue(StatType.MOVEMENT);
				var arrow : Bitmap = getArrow(src.location, dst.location, star);

				addChild(arrow);

				var mx : Number = (src.location.x + dst.location.x) / 2 + _entity.width / 2;
				var my : Number = (src.location.y + dst.location.y) / 2 + _entity.length / 2;
				var dp : Point = IsoBattleRectangleUtils.getIsoPointScreenPoint(view.units, mx, my);
				arrow.x = dp.x - (arrow.scaleX * arrow.width / 2);
				arrow.y = dp.y - arrow.height / 2;
			}
		}

		private function getArrow(src : TileLocation, dst : TileLocation, star : Boolean) : Bitmap
		{
			var dx : int = dst.x - src.x;
			var dy : int = dst.y - src.y;

			var b : Bitmap;
			if (star)
			{
				if (dx > 0)
				{
					b = view.bitmapPool.pop(view.board.assets.board_move_star_south);
					b.scaleX = 1;
				}
				else if (dy < 0)
				{
					b = view.bitmapPool.pop(view.board.assets.board_move_star_north);
					b.scaleX = 1;
				}
				else if (dy > 0)
				{
					b = view.bitmapPool.pop(view.board.assets.board_move_star_south);
					b.scaleX = -1;
				}
				else if (dx < 0)
				{
					b = view.bitmapPool.pop(view.board.assets.board_move_star_north);
					b.scaleX = -1;
				}
			}
			else
			{

				if (dx > 0)
				{
					b = view.bitmapPool.pop(view.board.assets.board_move_arrow_south);
					b.scaleX = 1;
				}
				else if (dy < 0)
				{
					b = view.bitmapPool.pop(view.board.assets.board_move_arrow_north);
					b.scaleX = 1;
				}
				else if (dy > 0)
				{
					b = view.bitmapPool.pop(view.board.assets.board_move_arrow_south);
					b.scaleX = -1;
				}
				else if (dx < 0)
				{
					b = view.bitmapPool.pop(view.board.assets.board_move_arrow_north);
					b.scaleX = -1;
				}

			}

			return b;
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
			if (_turn)
			{

				_turn.move.removeEventListener(BattleMoveEvent.COMMITTED, moveCommittedHandler);
				_turn.move.removeEventListener(BattleMoveEvent.MOVE_CHANGED, moveChangedHandler);
			}

			_turn = value;

			entity = turn ? turn.entity as BattleEntity : null;

			if (_turn)
			{
				_turn.move.addEventListener(BattleMoveEvent.COMMITTED, moveCommittedHandler);
				_turn.move.addEventListener(BattleMoveEvent.MOVE_CHANGED, moveChangedHandler);
			}

			setRenderDirty();
		}

		private function interactHandler(event : BattleFsmEvent) : void
		{
			setRenderDirty();
		}

		private function moveChangedHandler(event : BattleMoveEvent) : void
		{
			checkCanRender();
			setRenderDirty();
		}

		private function moveCommittedHandler(event : BattleMoveEvent) : void
		{
			checkCanRender();
		}

		private function fsmEventHandler(event : BattleFsmEvent) : void
		{
			checkCanRender();
		}

		override protected function checkCanRender() : void
		{
			canRender = _turn && !_turn.committed && !_turn.move.committed && _turn.entity.playerControlled && !_turn.turnInteract && !_turn.ability;
		}
	}
}
