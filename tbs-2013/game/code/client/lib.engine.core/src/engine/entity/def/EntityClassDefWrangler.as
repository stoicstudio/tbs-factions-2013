package engine.entity.def
{
	import engine.core.locale.Locale;
	import engine.core.logging.ILogger;
	import engine.resource.ResourceManager;
	import engine.resource.def.DefWrangler;

	public class EntityClassDefWrangler extends DefWrangler
	{
		public var manager : EntityClassDefList;
		private var locale : Locale;

		public function EntityClassDefWrangler(url : String, logger : ILogger, resman : ResourceManager, locale : Locale, completeCallback : Function)
		{
			logger.debug("EntityClassDefWrangler ctor " + url);

			this.locale = locale;
			super(url, logger, resman, completeCallback);
		}

		override protected function handleDefrComplete() : Boolean
		{
			super.handleDefrComplete();
			
			logger.debug("EntityClassDefWrangler.handleDefrComplete PARSING");

			manager = new EntityClassDefListVars().fromJson(vars, logger, locale);

			logger.debug("EntityClassDefWrangler.handleDefrComplete PARSED");
			
			return true;
		}

	}
}
