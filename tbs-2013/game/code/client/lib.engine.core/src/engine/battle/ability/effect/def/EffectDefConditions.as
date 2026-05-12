package engine.battle.ability.effect.def
{
	import engine.battle.ability.effect.model.EffectResult;

	public class EffectDefConditions
	{

		public var other : String;
		public var results : Vector.<EffectResult> = new Vector.<EffectResult>;
		public var minLevel : int;

		public function EffectDefConditions()
		{
		}

		public function isResultSatisfactory(rhs : EffectResult) : Boolean
		{
			// no results is good results...
			if (results.length == 0)
			{
				return true;
			}

			// any of these results is satisfactory
			for each (var cr : EffectResult in results)
			{
				if (cr == rhs)
				{
					return true;
				}
			}

			return false;
		}
	}
}
