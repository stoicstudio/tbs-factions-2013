package game.entity
{
	import engine.core.logging.ILogger;
	import engine.resource.ResourceManager;
	import engine.resource.def.DefWrangler;

	public class GameStatCostsWrangler extends DefWrangler
	{
		public var statCosts : GameStatCosts;

		public function GameStatCostsWrangler(url : String, logger : ILogger, resman : ResourceManager, completeCallback : Function)
		{
			super(url, logger, resman, completeCallback);
		}

		override protected function handleDefrComplete() : Boolean
		{
			try
			{
				statCosts = new GameStatCostsVars(vars, logger);
			}
			catch (e : Error)
			{
				logger.error("Failed to parse vars: " + e.getStackTrace());
			}

			return true;
		}
	}
}
