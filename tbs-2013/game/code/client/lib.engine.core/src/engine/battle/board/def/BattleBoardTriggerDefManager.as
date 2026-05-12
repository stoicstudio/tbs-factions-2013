package engine.battle.board.def
{
	import engine.core.logging.ILogger;

	import flash.utils.Dictionary;

	public class BattleBoardTriggerDefManager
	{
		private var logger : ILogger;
		private var _defs : Dictionary = new Dictionary();

		public function BattleBoardTriggerDefManager(logger : ILogger)
		{
			this.logger = logger;
		}

		public function registerAll(vars : Object) : void
		{
			for each (var obj : Object in vars.triggerdefs)
			{
				var battleBoardTriggerDef : BattleBoardTriggerDef = BattleBoardTriggerDefVars.parse(obj, logger);
				_defs[battleBoardTriggerDef.id] = battleBoardTriggerDef;
			}
		}

		public function getDef(id : String) : BattleBoardTriggerDef
		{
			return _defs[id];
		}
	}
}
