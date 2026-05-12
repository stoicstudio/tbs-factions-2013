package engine.battle.fsm
{

	public class BattleFsmConfig
	{
		public var deployTimeoutMs : int = 60000;
		//public var turnTimeoutMs : int = 60000;
		public var startPartyId : String = "XXXXXX";
		public static var enableAi : Boolean = true;

		public function BattleFsmConfig()
		{
		}
	}
}
