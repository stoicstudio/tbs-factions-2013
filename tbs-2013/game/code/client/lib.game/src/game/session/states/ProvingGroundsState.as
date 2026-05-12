package game.session.states
{
	import flash.events.Event;

	import engine.core.fsm.Fsm;
	import engine.core.fsm.StateData;
	import engine.core.logging.ILogger;
	import engine.entity.def.IEntityDef;
	import engine.entity.def.Legend;

	import game.gui.page.GuiProvingGroundsConfig;
	import game.session.GameState;
	import game.session.actions.ArrangePartyTxn;

	public class ProvingGroundsState extends GameState
	{
		public static const EVENT_AUTO_NAME : String = "ProvingGroundsState.EVENT_AUTO_NAME";
		public static const EVENT_SHOW_CLASS : String = "ProvingGroundsState.EVENT_SHOW_CLASS";

		public var txn : ArrangePartyTxn;
		public var auto_name : Boolean;
		public var show_class_id : String;
		public var use_unit_name : String;

		public var guiConfig : GuiProvingGroundsConfig = new GuiProvingGroundsConfig;

		private var legend : Legend;

		public function ProvingGroundsState(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			super(_data, fsm, logger);
		}

		override protected function handleEnteredState() : void
		{
			gameFsm.updateGameLocation("loc_proving_grounds");

			legend = config.legend;
			if (legend)
			{
				legend.party.addEventListener(Event.CHANGE, partyChangeHandler);
			}
		}

		override protected function handleCleanup() : void
		{
			if (legend)
			{
				legend.party.removeEventListener(Event.CHANGE, partyChangeHandler);
			}
			legend = null;
			guiConfig.reset();
		}

		protected function partyChangeHandler(event : Event) : void
		{
			if (txn)
			{
				txn.abort();
			}

			if (!config.accountInfo.tutorial)
			{
				const SEND_ARRANGE_DELAY_MS : int = 2000;
				var lobby_id : int = 0;

				if (config.factions)
				{
					config.factions.lobbyManager.current.options.lobby_id;

					if (config.legend.party.numMembers == 0)
					{
						config.factions.lobbyManager.current.ready = false;
					}

					txn = new ArrangePartyTxn(config.fsm.credentials, null, logger, config.legend.party.copyMemberIds, lobby_id);
					txn.send(config.fsm.communicator, null, SEND_ARRANGE_DELAY_MS);
				}
			}
		}

		public function handleDisplayCharacterDetails(e : IEntityDef) : void
		{

		}

		public function handleDisplayPromotion(e : IEntityDef) : void
		{

		}

		public function handlePromotion(e : IEntityDef) : void
		{

		}

		protected function promotionAutoName(value : Boolean) : void
		{
			auto_name = value;
			dispatchEvent(new Event(EVENT_AUTO_NAME));
		}

		protected function promotionShowClass(id : String, name : String) : void
		{
			use_unit_name = name;
			show_class_id = id;
			dispatchEvent(new Event(EVENT_SHOW_CLASS));
		}

		public function handleProvingGroundsCloseQuestionPages() : void
		{

		}

		public function handleProvingGroundsQuestionClick() : void
		{

		}

		public function handleProvingGroundsNamingAccept() : void
		{
		}

		public function handleProvingGroundsNamingMode() : void
		{
		}

		public function handleProvingGroundsVariationOpened() : void
		{
		}

		public function handleProvingGroundsVariationSelected() : void
		{
		}

	}
}
