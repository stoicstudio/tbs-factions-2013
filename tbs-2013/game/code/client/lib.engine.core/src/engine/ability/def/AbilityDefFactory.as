package engine.ability.def
{
	import engine.core.logging.ILogger;

	import flash.utils.Dictionary;

	public class AbilityDefFactory
	{
		public var abilityDefs : Dictionary = new Dictionary;
		public var logger : ILogger;
		public var errors : int;

		public function  AbilityDefFactory()
		{
			
		}
		
		public function link() : void
		{
			for each (var abld : AbilityDef in abilityDefs)
			{
				for (var i : int = 0; i < abld.maxLevel; ++i)
				{
					var abilityDef : AbilityDef = abld.getAbilityDefForLevel(i + 1) as AbilityDef;
					abilityDef.link(this);
				}
			}
		}

		public function register(def : AbilityDef) : void
		{
			abilityDefs[def.id] = def;
		}

		public function fetch(id : String, mustExist : Boolean = true) : AbilityDef
		{
			var def : AbilityDef = abilityDefs[id];
			if (!def)
			{
				if (mustExist)
				{
					throw new ArgumentError("invalid/unknown ability id " + id);
				}
			}

			return def;
		}
	}
}
