package game.session.states
{
	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;
	import engine.scene.model.SceneEvent;

	import game.gui.IGuiDialog;

	public class TownState extends SceneState
	{
		public function TownState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);

			data.setValue(GameStateDataEnum.LOCAL_PARTY, null);
		}

		override protected function sceneExitHandler(event : SceneEvent) : void
		{
			// Supress superclass handling of town loading
		}

		override protected function handleEnteredState() : void
		{
			gameFsm.updateGameLocation("loc_strand");

			super.handleEnteredState();
		}

		private function onDialogClose(buttonName : String) : void
		{
			if (buttonName == "Yes")
			{
				config.context.appInfo.exitGame("Firetower");
			}
		}

		override public function handleLandscapeClick(name : String) : Boolean
		{
			if (super.handleLandscapeClick(name))
			{
				return true;
			}

			switch (name)
			{
				case "click_hall_of_valor":
					config.fsm.transitionTo(HallOfValorState, data);
					return true;
				case "click_greathall":
					config.fsm.transitionTo(GreatHallState, data);
					return true;
				case "click_trophytower":
					return true;
				case "click_weavershut":
					return true;
				case "click_meadhouse":
					config.fsm.transitionTo(MeadHouseState, data);
					return true;
				case "click_provinggrounds":
					config.fsm.transitionTo(ProvingGroundsState, data);
					return true;
				case "click_marketplace":
					config.pageManager.showMarketplace(true, null, null, null);
					return true;
				case "click_firetower":
					if (config.runMode.mainMenu)
					{
						// TODO the main menu state should handle any unloading of the loaders
						config.fsm.transitionTo(MainMenuState, data);
					}
					else
					{
						var dialog : IGuiDialog;
						dialog = config.gameGuiContext.createDialog();
						dialog.openTwoBtnDialog("Quit game", "Are you sure you want to quit?", "Yes", "No", onDialogClose);
					}
					return true;
			}

			return false;
		}
	}
}
