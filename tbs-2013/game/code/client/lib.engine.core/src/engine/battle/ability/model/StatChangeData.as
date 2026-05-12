package engine.battle.ability.model
{

	public class StatChangeData
	{
		public function StatChangeData()
		{
			
		}
		
		public var amount : int;
		public var missChance : int;
		
		public function toString() : String
		{
			return amount + "@" + missChance;
		}

	}
}
