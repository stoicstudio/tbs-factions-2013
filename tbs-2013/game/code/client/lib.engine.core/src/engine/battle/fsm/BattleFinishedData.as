package engine.battle.fsm
{

	public class BattleFinishedData
	{
		public var victoriousTeam : String;
		private var _total_renown : int;
		public var rewards : Vector.<BattleRewardData> = new Vector.<BattleRewardData>;

		public function BattleFinishedData()
		{
			victoriousTeam = "";
		}

		public function fromJson(vars : Object) : void
		{
			victoriousTeam = vars.victoriousTeam;
			total_renown = vars.total_renown;

			for each (var rv : Object in vars.rewards)
			{
				const r : BattleRewardData = new BattleRewardData();
				r.parseJson(rv);
				rewards.push(r);
			}
		}

		public function getAward(partyIndex : int, type : BattleRenownAwardType) : int
		{
			return rewards[partyIndex].getAward(type);
		}

		public function getReward(partyIndex : int) : BattleRewardData
		{
			if (partyIndex >= 0 && partyIndex < rewards.length)
			{
				return rewards[partyIndex];
			}
			return null;
		}

		public function mergeAchievements(rhs : BattleFinishedData) : void
		{
			if (rewards.length == rhs.rewards.length)
			{
				for (var i : int = 0; i < rewards.length; ++i)
				{
					rewards[i].mergeAchievements(rhs.rewards[i]);
				}
			}
		}

		public function get total_renown() : int
		{
			return _total_renown;
		}

		public function set total_renown(value : int) : void
		{
			_total_renown = value;
		}

	}
}
