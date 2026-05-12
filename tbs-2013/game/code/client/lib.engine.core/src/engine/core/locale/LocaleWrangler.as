package engine.core.locale
{
	import engine.core.logging.ILogger;
	import engine.resource.ResourceManager;
	import engine.resource.def.DefWrangler;

	public class LocaleWrangler extends DefWrangler
	{
		public var locale : Locale;
		public var keepDates : Boolean;
		public var categoryClazz : Class;

		public function LocaleWrangler(url : String, logger : ILogger, resman : ResourceManager, completeCallback : Function, categoryClazz : Class, keepDates : Boolean)
		{
			super(url, logger, resman, completeCallback);
			this.keepDates = keepDates;
			this.categoryClazz = categoryClazz;
		}

		override protected function handleDefrComplete() : Boolean
		{
			logger.debug("LocaleWrangler.handleDefrComplete " + url + " vars=" + vars);

			super.handleDefrComplete();

			if (vars)
			{
				locale = new LocaleVars(vars, categoryClazz, keepDates, logger);
			}

			return true;
		}
	}
}
