package engine.core.util
{
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	import engine.core.logging.ILogger;

	public class Enum
	{
		private static const byClassByName : Dictionary = new Dictionary;
		private static const byClassVector : Dictionary = new Dictionary;
		private static var pending : Vector.<Enum> = new Vector.<Enum>;
		protected static const enumCtorKey : Object = {};

		private var _value : int;

		private var _name : String;

		public function Enum(name : String, key : Object)
		{
			super();

			if (enumCtorKey != key)
			{
				throw new ArgumentError("secret!");
			}

			// since the enums are typically created statically by the subclasses,
			// the classes are not yet fully constructed, so we cannot build the
			// class-keyed dictionaries.
			// put the enum on the pending list to be processed as soon as an enum is requested
			pending.push(this);

			this._name = name;
		}

		public function get name() : String
		{
			return _name;
		}

		private static function initializeClass(clazz : Object, logger : ILogger = null) : void
		{
			if (logger)
			{
				logger.debug("Enum.initializeClass " + clazz);
			}

			var b : Dictionary = byClassByName[clazz];
			if (!b)
			{
				if (logger)
				{
					logger.debug("Enum.initializeClass " + clazz + " new dict");
				}

				b = new Dictionary;
				const v : Vector.<Enum> = new Vector.<Enum>;

				var n : int = pending.length;

				if (logger)
				{
					logger.debug("Enum.initializeClass " + clazz + " pending=" + n);
				}

				for (var i : int = 0; i < n; )
				{
					if (logger)
					{
						logger.debug("Enum.initializeClass i=" + i + " pending.length=" + pending.length);
					}

					const e : Enum = pending[i];

					if (logger)
					{
						logger.debug("Enum.initializeClass " + clazz + " found e=" + e);
					}

					const qn : String = getQualifiedClassName(e);

					if (logger)
					{
						logger.debug("Enum.initializeClass " + clazz + " considering e=" + e + ", qn=" + qn);
					}

					var cz : Class = null;

					try
					{
						cz = getDefinitionByName(qn) as Class;
					}
					catch (e : Error)
					{
						if (logger)
						{
							logger.error("No such class " + qn + ": " + e);
						}
						++i;
						continue;
					}

					if (logger)
					{
						logger.debug("Enum.initializeClass " + clazz + " considering e=" + e + ", qn=" + qn + ", cz=" + cz);
					}

					if (cz == clazz)
					{
						if (logger)
						{
							logger.debug("Enum.initializeClass " + clazz + " considering e=" + e + " clazzmatch at v=" + v.length);
						}

						e._value = v.length;

						if (logger)
						{
							logger.debug("Enum.initializeClass " + clazz + " e=" + e + " VALUE SET to " + e.value + ", name=" + e.name);
						}

						v.push(e);

						if (logger)
						{
							logger.debug("Enum.initializeClass " + clazz + " e=" + e + " V NOW " + v.length);
						}

						b[e.name] = e;

						if (logger)
						{
							logger.debug("Enum.initializeClass " + clazz + " e=" + e + " b[e.name]=" + b[e.name]);
						}

						// flip the last element into this slot to avoid spamming splice/delete
						--n;

						if (logger)
						{
							logger.debug("Enum.initializeClass " + clazz + " e=" + e + " i=" + i + ", n=" + n);
						}

						pending[i] = pending[n];

						if (logger)
						{
							logger.debug("Enum.initializeClass " + clazz + " e=" + e + " flopped");
						}
					}
					else
					{
						// otherwise keep going
						++i;
					}
				}

				if (logger)
				{
					logger.debug("Enum.initializeClass " + clazz + " saw all pending");
				}

				byClassByName[clazz] = b;
				byClassVector[clazz] = v;

				// strip off the completed ones
				pending.splice(n, pending.length - n);

				if (logger)
				{
					logger.debug("Enum.initializeClass " + clazz + " found " + v.length);
				}
			}
		}

		private static function getByName(clazz : Class, logger : ILogger) : Dictionary
		{
			initializeClass(clazz, logger);
			return byClassByName[clazz];
		}

		public static function getVector(clazz : Class) : Vector.<Enum>
		{
			initializeClass(clazz);
			return byClassVector[clazz];
		}

		public static function getByOrdinal(clazz : Class, i : int) : Enum
		{
			initializeClass(clazz);
			var v : Vector.<Enum> = byClassVector[clazz];
			if (i >= 0 && i < v.length)
			{
				return v[i];
			}
			return null;
		}

		public static function getCount(clazz : Class) : int
		{
			initializeClass(clazz);
			return byClassVector[clazz].length;
		}

		public static function parse(clazz : Class, name : String, mustExist : Boolean = true, logger : ILogger = null) : Enum
		{
			if (logger)
			{
				logger.debug("Enum.parse clazz=" + clazz + ", name=" + name);
			}

			const dict : Dictionary = getByName(clazz, logger);

			if (logger)
			{
				logger.debug("Enum.parse dict=" + dict);
			}

			if (!dict)
			{
				throw new ArgumentError("Enum.parse invalid class=" + clazz);
			}

			const e : Enum = dict[name];

			if (logger)
			{
				logger.debug("Enum.parse e=" + e);
			}

			if (!e)
			{
				throw new ArgumentError("Enum.parse invalid enum [" + name + "] for type [" + clazz + "]");
			}

			return e;
		}

		public function toString() : String
		{
			return name;
		}

		public function get value() : int
		{
			return _value;
		}
	}
}
