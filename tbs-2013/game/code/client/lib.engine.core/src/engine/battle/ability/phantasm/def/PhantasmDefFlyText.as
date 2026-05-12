package engine.battle.ability.phantasm.def
{
	import engine.core.logging.ILogger;
	import engine.core.util.Enum;
	import engine.def.EngineJsonDef;

	public class PhantasmDefFlyText extends PhantasmDef
	{
		public static const schema : Object =
			{
				name: "PhantasmDefFlyText",
				description: "PhantasmDefFlyText Definition",
				type: "object",
				properties: {
					message: {
						type: "string",
						description: "the encoded message"
					},
					color: {
						type: "number",
						description: "the color to display"
					},
					fontName: {
						type: "string",
						description: "the font name"
					},
					fontSize: {
						type: "number",
						description: "the font size"
					},
					base:
					{
						type: PhantasmDefVars.schema
					}
				}
			};

		public var message : String;
		public var color : uint;
		public var fontName : String;
		public var fontSize : int;
		public var tokens : Array = new Array;

		override public function toString() : String
		{
			return "PDFlyText " + super.toString() + " color=" + color + " fontName=" + fontName + " fontSize=" + fontSize + " message=" + message;
		}

		public function PhantasmDefFlyText(vars : Object, logger : ILogger)
		{
			EngineJsonDef.validateThrow(vars, schema, logger);
			PhantasmDefVars.parse(this, vars.base, logger);

			this.message = vars.message;
			this.color = vars.color;
			this.fontName = vars.fontName;
			this.fontSize = vars.fontSize;

			var ctts : Vector.<Enum> = Enum.getVector(TextToken);

			var last : int = 0;
			var index : int = 0;

			while (true)
			{
				index = message.indexOf("%", last);

				if (index < 0)
				{
					tokens.push(message.substring(last));
					break;
				}

				// double %%, just use one of them literally
				if (message.charAt(index + 1) == "%")
				{
					// include a single % sign on the end
					tokens.push(message.substring(last, index + 1));
					// ignore the next one and keep going
					last = index + 2;
					continue;
				}

				if (index > last)
				{
					// intervening string needs to go on the list
					tokens.push(message.substring(last, index));
				}

				var foundToken : Boolean = false;

				for each (var ctt : TextToken in ctts)
				{
					if (message.indexOf(ctt.token, index + 1) == (index + 1))
					{
						// get rid of the literal token
						last = index + 1 + ctt.token.length;

						if (ctt == TextToken.OPVAR)
						{
							if (message.charAt(last) == "{")
							{
								++last;
								var endBrace : int = message.indexOf("}", last);
								var customPath : String = message.substring(last, endBrace);
								var ctc : TextOpVar = new TextOpVar(customPath);
								last = endBrace + 1;
								tokens.push(ctc);
							}
							else
							{
								logger.error("wtf " + message.substring(last));
							}
						}
						else
						{
							// this token immediately follows index						
							tokens.push(ctt);
						}
						foundToken = true;
						break;
					}
				}

				if (!foundToken)
				{
					var remainder : String = message.substring(index)
					// bad token, stop processing
					logger.error("invalid token: [" + remainder + "]");
					tokens.push(remainder);
					break;
				}
			}
		}
	}
}
