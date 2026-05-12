package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;

	import game.session.GameState;

	public class VersusFailState extends GameState
	{
		public function VersusFailState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			const lobby_id : int = data.getValue(GameStateDataEnum.BATTLE_FRIEND_LOBBY_ID);

			if (config.factions && lobby_id == config.factions.lobbyManager.current.options.lobby_id)
			{
				config.fsm.transitionTo(FriendLobbyState, null);
			}
			else if (config.runMode.town)
			{
				fsm.transitionTo(GreatHallState, data);
			}
			else
			{
				fsm.transitionTo(VersusFindMatchState, data);
			}
		}

	}
}
