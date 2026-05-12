package engine.battle.entity.view
{
	import engine.battle.board.view.BattleBoardView;
	import engine.battle.entity.model.BattleEntity;
	import engine.resource.ResourceManager;

	public class EntityViewFactory
	{
		public function EntityViewFactory()
		{
		}

		public static function create(sceneView : BattleBoardView, ent : BattleEntity, resman : ResourceManager) : EntityView
		{
			var view : EntityView;

			if (ent.def.entityClass.mobile)
			{
				view = new CharacterView(sceneView, ent, resman);
			}
			else
			{
				view = new EntityView(sceneView, ent, resman);
			}
			return view;
		}

	}
}
