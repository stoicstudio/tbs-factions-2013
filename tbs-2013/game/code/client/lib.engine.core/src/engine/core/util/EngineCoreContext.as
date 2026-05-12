package engine.core.util
{
	import engine.core.locale.Locale;
	import engine.core.logging.ILogger;

	public class EngineCoreContext
	{
		public var locale : Locale;
		public var logger : ILogger;
		public var appInfo : AppInfo;

		public function EngineCoreContext(locale : Locale, appInfo : AppInfo, logger : ILogger)
		{
			this.locale = locale;
			this.logger = logger;
			this.appInfo = appInfo
		}
	}
}
