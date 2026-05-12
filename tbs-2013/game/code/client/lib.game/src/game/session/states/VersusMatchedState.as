package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.fsm.StatePhase;
	import engine.core.logging.ILogger;
	import engine.entity.def.IEntityListDef;

	import game.session.GameState;

	import tbs.srv.battle.data.client.BattleAbortedData;
	import tbs.srv.battle.data.client.BattleCreateData;

	public class VersusMatchedState extends GameState
	{
		public var battleCreateData : BattleCreateData;

		private static const inputDataKeys : Array = [
			GameStateDataEnum.OPPONENT_ID,
			GameStateDataEnum.OPPONENT_NAME,
			GameStateDataEnum.OPPONENT_PARTY,
			GameStateDataEnum.SCENE_URL,
			GameStateDataEnum.LOCAL_PARTY
			];

		public function VersusMatchedState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			communicator.setPollTimeRequirement(this, 2000);
			battleCreateData = data.getValue(GameStateDataEnum.BATTLE_CREATE_DATA);
		}

		override protected function handleCleanup() : void
		{
			communicator.removePollTimeRequirement(this);
		}

		override protected function getRequiredInputDataKeys() : Array
		{
			return inputDataKeys;
		}

		public function get opponentName() : String
		{
			return data.getValue(GameStateDataEnum.OPPONENT_NAME);
		}

		public function get opponentId() : int
		{
			return data.getValue(GameStateDataEnum.OPPONENT_ID);
		}

		public function get opponentParty() : IEntityListDef
		{
			return data.getValue(GameStateDataEnum.OPPONENT_PARTY);
		}

		override public function handleMessage(msg : Object) : Boolean
		{
			if (msg["class"] == "tbs.srv.battle.data.client.BattleAbortedData")
			{
				var baded : BattleAbortedData = new BattleAbortedData;
				baded.parseJson(msg, logger);

				const bcd : BattleCreateData = data.getValue(GameStateDataEnum.BATTLE_CREATE_DATA);

				if (bcd && baded.battle_id == bcd.battle_id)
				{
					logger.info("VersusMatchedState GOT ABORTED " + baded);

					const lobby_id : int = data.getValue(GameStateDataEnum.BATTLE_FRIEND_LOBBY_ID);
					if (config.factions && lobby_id == config.factions.lobbyManager.current.options.lobby_id)
					{
						config.fsm.transitionTo(FriendLobbyState, null);
					}
					else
					{
						phase = StatePhase.FAILED;
					}
					return true;
				}
			}

			return false;
		}
	}
}
