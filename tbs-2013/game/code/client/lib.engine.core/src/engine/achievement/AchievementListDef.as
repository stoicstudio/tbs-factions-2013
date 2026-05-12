package engine.achievement
{
	import flash.utils.Dictionary;

	public class AchievementListDef
	{
		public function AchievementListDef()
		{
		}

		public var defs : Vector.<AchievementDef> = new Vector.<AchievementDef>;

		private var _id2def : Dictionary = new Dictionary;

		public function fetch(id : String) : AchievementDef
		{
			return _id2def[id];
		}

		protected function addDef(def : AchievementDef) : void
		{
			_id2def[def.id] = def;

			defs.push(def);

		}
	}
}
