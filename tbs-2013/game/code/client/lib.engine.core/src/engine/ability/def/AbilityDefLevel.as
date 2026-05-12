package engine.ability.def
{
	import engine.ability.IAbilityDef;
	import engine.ability.IAbilityDefLevel;

	public class AbilityDefLevel implements IAbilityDefLevel
	{
		private var _def : IAbilityDef;
		/**
		 * Zero means unavailable, 1 is the base level
		 */
		private var _level : int;

		public function AbilityDefLevel(def : IAbilityDef, level : int)
		{
			this._def = def;
			this._level = level;
		}

		public static function save(rhs : IAbilityDefLevel) : Object
		{
			var r : Object = {
					id: rhs.id,
					level: rhs.level
				};

			return r;
		}

		public function get id() : String
		{
			return def.id;
		}

		public function get def() : IAbilityDef
		{
			return _def;
		}

		public function get level() : int
		{
			return _level;
		}

	}
}
