package engine.battle.board.view
{
	import flash.geom.Rectangle;

	import engine.battle.board.IsoBattleRectangleUtils;
	import engine.battle.entity.model.BattleEntity;

	public class EntityLinkedDirtyRenderSprite extends DirtyRenderSprite
	{
		protected var _entity : BattleEntity;

		public function EntityLinkedDirtyRenderSprite(sceneView : BattleBoardView)
		{
			super(sceneView);
			canRender = false;
		}

		public function get entity() : BattleEntity
		{
			return _entity;
		}

		public function set entity(value : BattleEntity) : void
		{
			if (_entity)
			{
				onEntityRemoved();
			}

			_entity = value;

			if (_entity)
			{
				onEntityAdded();
			}

			checkCanRender();
			setRenderDirty();
		}

		protected function checkCanRender() : void
		{
			canRender = _entity != null;
		}

		public function getEntityBaseScreenRect() : Rectangle
		{
			if (!_entity)
			{
				return null;
			}

			return IsoBattleRectangleUtils.getIsoRectScreenRect(view.units, _entity.x, _entity.y, _entity.width, _entity.length);
		}

		protected function onEntityAdded() : void
		{

		}

		protected function onEntityRemoved() : void
		{

		}

	}
}
