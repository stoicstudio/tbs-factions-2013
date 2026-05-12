package engine.battle.def
{
	import engine.anim.def.AnimLibrary;
	import engine.anim.def.AnimLibraryVars;
	import engine.battle.ability.effect.model.BattleFacing;
	import engine.resource.AnimClipResource;
	import engine.resource.Resource;
	import engine.resource.ResourceManager;
	import engine.resource.def.DefResource;

	public class IsoAnimLibraryResource extends DefResource
	{
		private var _library : AnimLibrary;

		public function IsoAnimLibraryResource(url : String, erm : ResourceManager, loaderFactoryFunc : Function)
		{
			super(url, erm, loaderFactoryFunc);
		}

		override protected function internalOnLoadComplete() : void
		{
			super.internalOnLoadComplete();
			if (jo)
			{

				_library = new AnimLibraryVars(jo, BattleFacing, logger, null, null);

				if (_library.errors)
				{
					throw new ArgumentError("Anim Library had errors " + url);
				}

				_library.resolve(resourceManager);

				for each (var r : Resource in _library.resourceGroup.resources)
				{
					addChild(r.url, AnimClipResource);
				}
			}
		}

		public function get library() : AnimLibrary
		{

			return _library;

		}
	}
}
