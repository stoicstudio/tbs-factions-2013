package engine.battle.board.view.overlay
{
	import flash.display.DisplayObject;
	import flash.geom.Point;

	import engine.anim.view.AnimClipSprite;
	import engine.battle.BattleAssetsDef;
	import engine.battle.board.IsoBattleRectangleUtils;
	import engine.battle.board.view.BattleBoardView;
	import engine.battle.board.view.EntityLinkedDirtyRenderSprite;
	import engine.tile.def.TileLocation;

	public class TileMarkerOverlay extends EntityLinkedDirtyRenderSprite
	{
		private var _loc : TileLocation;
		private var _width : int = 2;

		public function TileMarkerOverlay(sceneView : BattleBoardView)
		{
			super(sceneView);

			name = "tile_marker";

			const assets : BattleAssetsDef = view.board.assets;

			view.animClipSpritePool.addPool(assets.board_active_enemy_1, 1, 1);
			view.animClipSpritePool.addPool(assets.board_active_enemy_2, 1, 1);
		}

		public function get tileLocation() : TileLocation
		{
			return _loc;
		}

		public function set tileLocation(value : TileLocation) : void
		{
			if (_loc != value)
			{
				_loc = value;
				setRenderDirty();
				checkCanRender();
			}
		}

		override public function cleanup() : void
		{

		}

		override protected function handleCanRenderChanged() : void
		{
			clearChildren();
		}

		private function clearChildren() : void
		{
			while (numChildren > 0)
			{
				const b : AnimClipSprite = removeChildAt(numChildren - 1) as AnimClipSprite;
				if (b)
				{
					b.name = "";
					view.animClipSpritePool.reclaim(b);
				}
			}

		}

		override protected function onRender() : void
		{
			clearChildren();
			if (_loc)
			{
				const d : DisplayObject = view.animClipSpritePool.pop(view.board.assets.board_active_enemy_2);
				d.name = "tile";
				addChild(d);
				const mx : Number = _loc.x + _width / 2;
				const my : Number = _loc.y + _width / 2;
				const dp : Point = IsoBattleRectangleUtils.getIsoPointScreenPoint(view.units, mx, my);

				d.x = dp.x;
				d.y = dp.y;
			}
		}

		override protected function checkCanRender() : void
		{
			canRender = _loc != null;
		}
	}
}
