package engine.core.locale
{
	import flash.display.DisplayObject;
	import flash.utils.Dictionary;

	import engine.core.logging.ILogger;

	public class Locale
	{
		private var localizers : Dictionary = new Dictionary;
		public var localizerList : Vector.<Localizer> = new Vector.<Localizer>;
		private var _modified : Boolean;

		private var _logger : ILogger;

		/**
		 *
		 * @param logger Can be null if you don't want locale error messages
		 *
		 */
		public function Locale(logger : ILogger)
		{
			this._logger = logger;
		}

		public function get logger() : ILogger
		{
			return _logger;
		}

		public function addCategory(category : LocaleCategory) : Localizer
		{
			return getLocalizer(category, true);
		}

		protected function addLocalizer(localizer : Localizer) : void
		{
			if (logger)
			{
				logger.debug("Locale.addLocalizer START " + localizer.id);
			}

			const old : Localizer = getLocalizer(localizer.id);
			if (old)
			{
				if (logger)
				{
					logger.error("Locale.addLocalizer already has localize " + localizer.id);
				}
				throw new ArgumentError("Locale.addLocalizer already have a localizer of id " + localizer.id);
			}

			localizers[localizer.id] = localizer;
			localizerList.push(localizer);
			localizer.locale = this;

			if (logger)
			{
				logger.debug("Locale.addLocalizer FINISHED " + localizer.id);
			}
		}

		public function getLocalizer(category : LocaleCategory, create : Boolean = false) : Localizer
		{
			var tc : Localizer = localizers[category];
			if (!tc)
			{
				if (create)
				{
					tc = new Localizer(category, logger);
					addLocalizer(tc);
				}
			}
			return tc;
		}

		public function addTranslation(category : LocaleCategory, token : String, value : String) : void
		{
			const tc : Localizer = getLocalizer(category, true);
			tc.addTranslation(token, value);
		}

		public function translate(category : LocaleCategory, token : String, raw : Boolean = false) : String
		{
			const tc : Localizer = getLocalizer(category);

			if (!tc)
			{
				if (raw)
				{
					return null;
				}

				return "{" + token + "}";
			}

			const value : String = tc.translate(token, raw);
			return value;
		}

		public function getTokens(category : LocaleCategory) : Vector.<String>
		{
			const tc : Localizer = getLocalizer(category);
			return tc.tokenList;
		}

		public function translateDisplayObjects(category : LocaleCategory, p : DisplayObject) : void
		{
			var tc : Localizer = getLocalizer(category, true);
			tc.translateDisplayObjects(p);
		}

		public function get modified() : Boolean
		{
			return _modified;
		}

		public function set modified(value : Boolean) : void
		{
			_modified = value;
		}

		public function replaceTranslatedTokens(translated : String, tokens : Array) : String
		{
			var result : String = translated;
			var p : int = result.indexOf("%");

			var i : int = 0;

			while (p >= 0 && i < tokens.length)
			{
				if (result.length <= p)
				{
					break;
				}

				const code : String = result.charAt(p + 1);

				var repl : String = null;
				switch (code)
				{
					case "%":
						repl = "%";
						break;
					case "s":
						repl = tokens[i];
						++i;
						break;
				}

				if (repl != null)
				{
					result = result.substr(0, p) + repl + result.substr(p + 2);
				}

				p = result.indexOf("%", p + repl.length);
			}

			return result;
		}

	}
}
