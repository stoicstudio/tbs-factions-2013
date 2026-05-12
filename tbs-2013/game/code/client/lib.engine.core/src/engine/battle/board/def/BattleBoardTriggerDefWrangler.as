package engine.battle.board.def
{
	import engine.core.logging.ILogger;
	import engine.resource.ResourceManager;
	import engine.resource.def.DefWrangler;
	
	public class BattleBoardTriggerDefWrangler extends DefWrangler
	{
		public function BattleBoardTriggerDefWrangler(url:String, logger:ILogger, resman:ResourceManager, completeCallback:Function)
		{
			super(url, logger, resman, completeCallback);
		}
	}
}