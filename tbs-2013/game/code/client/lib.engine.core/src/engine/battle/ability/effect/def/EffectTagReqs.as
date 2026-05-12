package engine.battle.ability.effect.def
{
	import engine.battle.ability.effect.model.EffectTag;
	import engine.battle.ability.effect.model.IEffectTagProvider;
	import engine.core.util.Enum;

	import flash.utils.Dictionary;

	public class EffectTagReqs
	{

		public var all : Dictionary = new Dictionary;
		public var any : Dictionary = new Dictionary;
		public var none : Dictionary = new Dictionary;

		public function EffectTagReqs()
		{
		}

		protected static function captureTagSet(v : Array, d : Dictionary) : void
		{
			for each (var s : String in v)
			{
				var t : EffectTag = Enum.parse(EffectTag, s) as EffectTag;
				d[t] = t;
			}
		}

		public function checkTags(other : IEffectTagProvider) : Boolean
		{

			var tag : EffectTag;
			for each (tag in all)
			{
				if (!other.hasTag(tag))
				{
					return false;
				}
			}

			var foundAny : Boolean;
			var needsAny : Boolean;
			for each (tag in any)
			{
				needsAny = true;
				if (other.hasTag(tag))
				{
					foundAny = true;
					break;
				}
			}

			if (needsAny && !foundAny)
			{
				return false;
			}

			for each (tag in none)
			{
				if (other.hasTag(tag))
				{
					return false;
				}
			}

			return true;
		}
	}
}
