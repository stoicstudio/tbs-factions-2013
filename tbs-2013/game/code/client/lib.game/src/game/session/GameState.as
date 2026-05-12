package game.session
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.State;
	import engine.core.fsm.StateData;
	import engine.core.http.HttpCommunicator;
	import engine.core.logging.ILogger;
	import engine.session.Credentials;
	
	import game.cfg.GameConfig;

	public class GameState extends State
	{
		public function GameState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		public function get gameFsm() : GameFsm
		{
			return fsm as GameFsm;
		}

		public function get credentials() : Credentials
		{
			return gameFsm.credentials;
		}

		public function get communicator() : HttpCommunicator
		{
			return gameFsm.communicator;
		}

		public function get config() : GameConfig
		{
			return gameFsm.config;
		}

		public function handlePageReady() : void
		{

		}

	}
}
