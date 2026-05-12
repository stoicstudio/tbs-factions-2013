package engine.ability.def
{
	import engine.ability.IAbilityDef;
	import engine.ability.IAbilityDefLevel;
	import engine.ability.IAbilityDefLevels;
	
	import flash.errors.IllegalOperationError;
	import flash.utils.Dictionary;

	public class AbilityDefLevels implements IAbilityDefLevels
	{
		protected var abilities : Vector.<IAbilityDefLevel> = new Vector.<IAbilityDefLevel>;
		private var indexes : Dictionary = new Dictionary;

		public function AbilityDefLevels()
		{
		}

		public function clone() : IAbilityDefLevels
		{
			throw new IllegalOperationError("pure virtual");
		}	

		public function setAbilityDefLevel(def : IAbilityDef, level : int) : void
		{
			var index : int = getAbilityIndex(def.id);
			var adl : IAbilityDefLevel = new AbilityDefLevel(def, level);
			if (index >= 0)
			{
				abilities[index] = adl;
			}
			else
			{
				addAbilityDefLevel(adl);
			}
		}

		private function addAbilityDefLevel(adl : IAbilityDefLevel) : void
		{
			abilities.push(adl);
			indexes[adl.id] = abilities.length - 1;
		}

		public function get numAbilities() : int
		{
			return abilities.length;
		}

		public function getAbilityDef(index : int) : IAbilityDef
		{
			return abilities[index].def;
		}

		public function getAbilityDefLevel(index : int) : IAbilityDefLevel
		{
			return abilities[index];
		}

		public function getAbilityIndex(id : String) : int
		{
			if (id in indexes)
			{
				return indexes[id];
			}
			else
			{
				return -1;
			}
		}

		public function getAbilityLevel(index : int) : int
		{
			return abilities[index].level;
		}

		public static function save(rhs : IAbilityDefLevels) : Array
		{
			var r : Array = [];
			for (var i : int = 0; i < rhs.numAbilities; ++i)
			{
				var adl : IAbilityDefLevel = rhs.getAbilityDefLevel(i);
				r.push(AbilityDefLevel.save(adl));
			}
			return r;
		}

		public function hasAbility(id : String) : Boolean
		{
			return id in indexes;

		}

		public function getAbilityDefById(id : String) : IAbilityDef
		{
			var lvl : IAbilityDefLevel = getAbilityDefLevelById(id);
			return lvl ? lvl.def : null;
		}

		public function getAbilityDefLevelById(id : String) : IAbilityDefLevel
		{
			var index : int = getAbilityIndex(id);
			if (index >= 0)
			{
				return getAbilityDefLevel(index);
			}
			return null;

		}

	}
}
