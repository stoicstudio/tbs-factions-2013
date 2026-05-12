package engine.battle.board.model
{
	import engine.battle.ability.effect.model.Effect;
	import engine.battle.ability.phantasm.def.ChainPhantasmsDef;
	import engine.battle.ability.phantasm.model.ChainPhantasms;
	import engine.battle.ability.phantasm.model.ChainPhantasmsEvent;
	import engine.battle.ability.phantasm.model.PhantasmsEvent;

	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	public class BattleBoardPhantasms extends EventDispatcher
	{
		private var _board : BattleBoard;
		private var _chains : Dictionary = new Dictionary;

		public function BattleBoardPhantasms(board : BattleBoard)
		{
			this._board = board;
		}

		public function cleanup() : void
		{
			for each (var chain : ChainPhantasms in chains)
			{
				chain.removeEventListener(ChainPhantasmsEvent.STARTED, chainStartedHandler);
				chain.cleanup();
			}

			_chains = null;
			_board = null;
		}

		public function createChainForEffect(effect : Effect) : ChainPhantasms
		{
			var def : ChainPhantasmsDef = effect.def.getChainPhantasmsForResult(effect.result);

			if (def)
			{
				var chain : ChainPhantasms = new ChainPhantasms(effect, def, board.logger);
				chains[chain] = chain;
				chain.addEventListener(ChainPhantasmsEvent.STARTED, chainStartedHandler);
				return chain;
			}
			return null;
		}

		protected function chainStartedHandler(event : ChainPhantasmsEvent) : void
		{
			event.chain.removeEventListener(ChainPhantasmsEvent.STARTED, chainStartedHandler);
			dispatchEvent(new PhantasmsEvent(PhantasmsEvent.CHAIN_STARTED, event.chain));
		}

		public function get board() : IBattleBoard
		{
			return _board;
		}

		public function get chains() : Dictionary
		{
			return _chains;
		}

	}
}
