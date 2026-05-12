package engine.tourney
{
	import engine.def.BooleanVars;

	public class TourneyDef
	{
		public var name : String;
		public var rewards : Vector.<int> = new Vector.<int>;
		public var entry_fee : int;
		public var daily_limit : int;
		public var power_requirement : int;
		public var enabled : Boolean;

		public function TourneyDef()
		{
		}

		public function fromJson(json : Object) : void
		{
			name = json.name;
			for each (var rwv : Object in json.rewards)
			{
				rewards.push(rwv);
			}
			entry_fee = json.entry_fee;
			daily_limit = json.daily_limit;
			power_requirement = json.power_requirement;
			enabled = BooleanVars.parse(json.enabled, true);
		}
	}
}
