package engine.battle.fsm
{
	import flash.utils.Dictionary;

	import engine.core.util.Enum;

	public class BattleRewardData
	{
		public var awards : Dictionary = new Dictionary;
		//key is id and value is the renown rewarded.
		public var achievements : Dictionary = new Dictionary;
		private var _total_renown : int;

		public function BattleRewardData()
		{
		}

		public function parseJson(vars : Object) : void
		{
			if (vars == null)
			{
				return;
			}

			var key : String;

			for (key in vars.awards)
			{
				const type : BattleRenownAwardType = Enum.parse(BattleRenownAwardType, key) as BattleRenownAwardType;
				awards[type] = vars.awards[key];
			}

			for (key in vars.achievements)
			{
				achievements[key] = vars.achievements[key];
			}

			total_renown = vars.total_renown;
		}

		public function getAward(type : BattleRenownAwardType) : int
		{
			return awards[type];
		}

		public function getAchievementRenown(id : String) : int
		{
			return achievements[id];
		}

		public function mergeAchievements(rhs : BattleRewardData) : void
		{
			for (var key : Object in rhs.achievements)
			{
				// keep the achievements from earlier
				this.achievements[key] = rhs.achievements[key];
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
