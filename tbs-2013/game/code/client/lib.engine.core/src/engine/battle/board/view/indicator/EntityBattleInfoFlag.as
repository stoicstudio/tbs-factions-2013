package engine.battle.board.view.indicator
{
	import as3isolib.display.IsoSprite;

	import engine.battle.entity.view.EntityView;
	import engine.entity.def.IEntityDef;
	import engine.gui.IGuiBattleInfoFlag;
	import engine.resource.MovieClipResource;
	import engine.resource.ResourceGroup;
	import engine.resource.ResourceManager;
	import engine.resource.event.ResourceLoadedEvent;

	import flash.display.MovieClip;

	public class EntityBattleInfoFlag extends IsoSprite
	{
		public var guiInfoFlag : IGuiBattleInfoFlag;
		private var infoFlag : MovieClipResource;
		public var entity : IEntityDef;
		private var resourceGroup : ResourceGroup = new ResourceGroup;
		private var guiResourceManager : ResourceManager;

		public function EntityBattleInfoFlag(entityView : EntityView)
		{
			super("flag");
			guiResourceManager = entityView.sceneView.board.scene.context.guiResman;
			entity = entityView.entity._def;
			container.mouseEnabled = false;
			container.mouseChildren = false;
			infoFlag = this.guiResourceManager.getResource("battle.swf/gui.battle.info.flag", MovieClipResource, resourceGroup) as MovieClipResource;
			infoFlag.addResourceListener(infoFlagLoadedHandler);
			this.z = entity.entityClass.bounds.height * entityView.sceneView.units;
			// compensate for the diagonal size which is visible vertically on the screen			
			this.z += entityView.width / 2;

			const MARGIN : Number = 15;
			this.z += MARGIN;
		}

		private function infoFlagLoadedHandler(event : ResourceLoadedEvent) : void
		{
			event.resource.removeEventListener(event.type, infoFlagLoadedHandler);

			if (infoFlag.ok)
			{
				guiInfoFlag = infoFlag.movieClip as IGuiBattleInfoFlag;
				(guiInfoFlag as MovieClip).mouseEnabled = false;
				(guiInfoFlag as MovieClip).mouseChildren = false;
				sprites = new Array(guiInfoFlag);

			}
		}
	}
}
