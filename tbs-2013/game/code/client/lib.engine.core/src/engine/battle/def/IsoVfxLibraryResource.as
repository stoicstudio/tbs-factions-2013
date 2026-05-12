package engine.battle.def
{
	import engine.resource.AnimClipResource;
	import engine.resource.Resource;
	import engine.resource.ResourceManager;
	import engine.resource.def.DefResource;
	import engine.vfx.VfxLibrary;
	import engine.vfx.VfxLibraryVars;

	public class IsoVfxLibraryResource extends DefResource
	{
		public var library : VfxLibrary;

		public function IsoVfxLibraryResource(url : String, erm : ResourceManager, loaderFactoryFunc : Function)
		{
			super(url, erm, loaderFactoryFunc);
		}

		override protected function internalOnLoadComplete() : void
		{
			super.internalOnLoadComplete();
			if (jo)
			{
				library = new VfxLibraryVars(jo, logger);

				library.resolve(resourceManager);

				for each (var r : Resource in library.groupResources)
				{
					addChild(r.url, AnimClipResource);
				}

				for each (var iurl : String in library.inheritUrls)
				{
					addChild(iurl, IsoVfxLibraryResource);
				}
			}
		}

		override protected function internalOnLoadedAllComplete() : void
		{
			for each (var iurl : String in library.inheritUrls)
			{
				const inherit : IsoVfxLibraryResource = resourceManager.getResource(iurl, IsoVfxLibraryResource) as IsoVfxLibraryResource;
				library.inherits.push(inherit.library);
			}
		}
	}
}
