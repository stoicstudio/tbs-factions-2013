package engine.core.locale
{
	import engine.core.logging.ILogger;
	import engine.gui.IGuiButton;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.utils.Dictionary;

	public class Localizer
	{
		public var id : LocaleCategory;
		private var tokens : Dictionary = new Dictionary;
		public var tokenList : Vector.<String> = new Vector.<String>;
		public var logger : ILogger;
		private var dates : Dictionary;
		public var locale : Locale;

		public function Localizer(id : LocaleCategory, logger : ILogger)
		{
			this.id = id;
			// disable localizer errors until we are ready to deal with them
			this.logger = null;
			//this.logger = logger;
		}

		public function addTranslation(token : String, value : String, date : Date = null) : void
		{
			if (!(token in tokens))
			{
				tokenList.push(token);
			}

			tokens[token] = value;

			if (date)
			{
				if (!dates)
				{
					dates = new Dictionary;
				}

				dates[token] = date;
			}
		}

		public function setValue(token : String, value : String) : void
		{
			addTranslation(token, value, new Date);
			if (locale)
			{
				locale.modified = true;
			}
		}

		public function getDate(token : String) : Date
		{
			return dates ? dates[token] : null;
		}

		public function translate(token : String, raw : Boolean = false) : String
		{
			if (token in tokens)
			{
				return tokens[token];
			}

			if (raw)
			{
				return null;
			}

			if (logger)
			{
				logger.error("Localizer.translate " + this + ":[" + token + "] failed.");
			}
			return "{" + token + "}";
		}

		public function toString() : String
		{
			return id.toString();
		}

		private function getToken(s : String) : String
		{
			var dollar : int = s ? s.indexOf("$") : -1;
			var token : String = dollar >= 0 ? s.substring(dollar + 1) : null;
			return token;
		}

		public function translateDisplayObjects(p : DisplayObject) : void
		{
			var nameToken : String = getToken(p.name);

			var tf : TextField = p as TextField;
			if (tf)
			{
				var textToken : String = getToken(tf.text);
				var result : String;
				if (textToken)
				{
					result = translate(textToken);
					tf.text = result;
				}
				else if (nameToken)
				{
					result = translate(nameToken);
					tf.text = result;
				}
				return;
			}

			var sb : SimpleButton = p as SimpleButton;
			if (sb)
			{
				if (nameToken)
				{
					LocaleUtil.setText(sb, translate(nameToken));
				}
				return;
			}

			var ib : IGuiButton = p as IGuiButton;
			if (ib)
			{
				if (nameToken)
				{
					var tld : String = translate(nameToken);
					ib.buttonText = tld;
				}
			}
			var doc : DisplayObjectContainer = p as DisplayObjectContainer;

			if (!doc)
			{
				return;
			}

			for (var i : int = 0; i < doc.numChildren; ++i)
			{
				var c : DisplayObject = doc.getChildAt(i);

				translateDisplayObjects(c);
			}
		}

	}
}
