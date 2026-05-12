package game.session.states.tutorial
{
	import engine.core.fsm.Fsm;

	import game.session.GameFsm;
	import game.session.states.TownLoadState;

	public class RegisterTutorialStates
	{
		public static function register(fsm : GameFsm) : void
		{
			fsm.registerState(TutorialStartState);
			fsm.registerState(TutorialLoadPartyState);
			fsm.registerState(TutorialVideoPart1State);
			fsm.registerState(TutorialVideoPart2State);
			fsm.registerState(TutorialBattleLoadState);
			fsm.registerState(TutorialBattleLoadDirectState);
			fsm.registerState(TutorialBattleState);
			fsm.registerState(TutorialTownState);
			fsm.registerState(TutorialTownLoadState);
			fsm.registerState(TutorialTownFinishState);
			fsm.registerState(TutorialMeadHouseState);
			fsm.registerState(TutorialProvingGroundsState);

			fsm.registerState(TutorialEndState);

			fsm.registerTransition(TutorialStartState, TutorialLoadPartyState, Fsm.TRANS_COMPLETE);
			fsm.registerTransition(TutorialLoadPartyState, TutorialBattleLoadState, Fsm.TRANS_COMPLETE);
			fsm.registerTransition(TutorialBattleLoadState, TutorialVideoPart1State, Fsm.TRANS_COMPLETE);
			fsm.registerTransition(TutorialVideoPart1State, TutorialBattleState, Fsm.TRANS_COMPLETE);
			fsm.registerTransition(TutorialBattleLoadDirectState, TutorialBattleState, Fsm.TRANS_COMPLETE);
			fsm.registerTransition(TutorialBattleState, TutorialVideoPart2State, Fsm.TRANS_COMPLETE);
			fsm.registerTransition(TutorialVideoPart2State, TutorialTownLoadState, Fsm.TRANS_COMPLETE);
			fsm.registerTransition(TutorialTownLoadState, TutorialTownState, Fsm.TRANS_COMPLETE);
			fsm.registerTransition(TutorialTownState, TutorialMeadHouseState, Fsm.TRANS_COMPLETE);
			fsm.registerTransition(TutorialMeadHouseState, TutorialProvingGroundsState, Fsm.TRANS_COMPLETE);
			fsm.registerTransition(TutorialProvingGroundsState, TutorialTownFinishState, Fsm.TRANS_COMPLETE);
			fsm.registerTransition(TutorialTownFinishState, TutorialEndState, Fsm.TRANS_COMPLETE);

			fsm.registerTransition(TutorialEndState, TownLoadState, Fsm.TRANS_ALL);

			fsm.registerTransition(TutorialStartState, TutorialEndState, Fsm.TRANS_FAILED);
			fsm.registerTransition(TutorialLoadPartyState, TutorialEndState, Fsm.TRANS_FAILED);
			fsm.registerTransition(TutorialBattleLoadState, TutorialEndState, Fsm.TRANS_FAILED);
			fsm.registerTransition(TutorialVideoPart1State, TutorialEndState, Fsm.TRANS_FAILED);
			fsm.registerTransition(TutorialBattleLoadDirectState, TutorialEndState, Fsm.TRANS_FAILED);
			fsm.registerTransition(TutorialBattleState, TutorialEndState, Fsm.TRANS_FAILED);
			fsm.registerTransition(TutorialVideoPart2State, TutorialEndState, Fsm.TRANS_FAILED);
			fsm.registerTransition(TutorialTownLoadState, TutorialEndState, Fsm.TRANS_FAILED);
			fsm.registerTransition(TutorialTownState, TutorialEndState, Fsm.TRANS_FAILED);
			fsm.registerTransition(TutorialMeadHouseState, TutorialEndState, Fsm.TRANS_FAILED);
			fsm.registerTransition(TutorialProvingGroundsState, TutorialEndState, Fsm.TRANS_FAILED);
			fsm.registerTransition(TutorialTownFinishState, TutorialEndState, Fsm.TRANS_FAILED);

			
		}
	}
}
