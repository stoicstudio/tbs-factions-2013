package engine.battle.ability.def
{
	import engine.ability.IAbilityDef;
	import engine.ability.IAbilityDefLevels;
	import engine.ability.def.AbilityDefLevel;
	import engine.ability.def.AbilityDefLevels;

	import flash.utils.Dictionary;

	public class BattleAbilityDefLevels extends AbilityDefLevels
	{
		public var abilitiesByTag : Dictionary;

		public function BattleAbilityDefLevels()
		{
			super();
		}

		override public function clone() : IAbilityDefLevels
		{
			const d : BattleAbilityDefLevels = new BattleAbilityDefLevels;
			for each (var a : AbilityDefLevel in abilities)
			{
				var ba : BattleAbilityDef = a.def as BattleAbilityDef;
				d.setAbilityDefLevel(ba, a.level);
			}

			d.cacheAbilityTags();
			return d;
		}

		override public function setAbilityDefLevel(def : IAbilityDef, level : int) : void
		{
			if (!(def is BattleAbilityDef))
			{
				throw new ArgumentError("no , not battle...");
			}

			super.setAbilityDefLevel(def, level);
		}

		private function cacheAbilityTags() : void
		{
			if (abilitiesByTag)
			{
				return;
			}

			abilitiesByTag = new Dictionary;

			for each (var adl : AbilityDefLevel in abilities)
			{
				var bad : BattleAbilityDef = (adl.def as BattleAbilityDef);
				var t : BattleAbilityTag = bad.tag;
				var tas : Vector.<AbilityDefLevel> = getAbilitiesByTag(t);
				tas.push(adl);
			}
		}

		public function getAbilitiesByTag(tag : BattleAbilityTag) : Vector.<AbilityDefLevel>
		{
			cacheAbilityTags();

			var tas : Vector.<AbilityDefLevel> = abilitiesByTag[tag];
			if (!tas)
			{
				tas = new Vector.<AbilityDefLevel>;
				abilitiesByTag[tag] = tas;
			}
			return tas;
		}

		public function getFirstAbilityByTag(tag : BattleAbilityTag) : AbilityDefLevel
		{
			cacheAbilityTags();

			var tas : Vector.<AbilityDefLevel> = getAbilitiesByTag(tag);
			return tas.length > 0 ? tas[0] : null;
		}

	}
}
