package engine.battle.board.view.phantasm
{
	import engine.battle.ability.effect.model.Effect;
	import engine.battle.ability.effect.model.EffectEvent;
	import engine.battle.ability.phantasm.def.PhantasmDef;
	import engine.battle.ability.phantasm.def.PhantasmDefAnim;
	import engine.battle.ability.phantasm.def.PhantasmDefFlyText;
	import engine.battle.ability.phantasm.def.PhantasmDefSound;
	import engine.battle.ability.phantasm.def.PhantasmDefSprite;
	import engine.battle.ability.phantasm.model.ChainPhantasms;
	import engine.battle.ability.phantasm.model.ChainPhantasmsEvent;
	import engine.battle.ability.phantasm.model.PhantasmsEvent;
	import engine.battle.board.model.BattleBoardPhantasms;
	import engine.battle.board.view.BattleBoardView;
	import engine.core.logging.ILogger;

	public class CombatScenePhantasmsView
	{
		private var sceneView : BattleBoardView;

		private var views : Vector.<PhantasmView> = new Vector.<PhantasmView>;

		private var boardPhantasms : BattleBoardPhantasms;

		private var logger : ILogger;

		public function CombatScenePhantasmsView(sceneView : BattleBoardView)
		{
			this.sceneView = sceneView;
			this.logger = sceneView.board.logger;
			boardPhantasms = sceneView.board.phantasms;
			boardPhantasms.addEventListener(PhantasmsEvent.CHAIN_STARTED, chainStartedHandler);
		}

		public function cleanup() : void
		{
			boardPhantasms.removeEventListener(PhantasmsEvent.CHAIN_STARTED, chainStartedHandler);

			for each (var view : PhantasmView in views)
			{
				view.cleanup();
				view.chain.removeEventListener(ChainPhantasmsEvent.PHANTASM, phantasmHandler);
			}

			views = null;
			boardPhantasms = null;
			sceneView = null;

		}

		public function update(delta : int) : void
		{
			var rem : Vector.<PhantasmView>;
			var last : int = views.length - 1;
			for (var i : int = 0; i <= last; )
			{
				const view : PhantasmView = views[i];
				const needed : Boolean = view.needsRemove || view.needsUpdate;
				if (!needed || (view.needsUpdate && !view.update(delta)))
				{
					view.cleanup();

					// swap last
					if (last > i)
					{
						views[i] = views[last];
					}
					--last;
				}
				else
				{
					++i;
				}
			}

			if (last < (views.length - 1))
			{
				views.splice(last + 1, (views.length - 1 - last));
			}
		}

		protected function chainStartedHandler(event : PhantasmsEvent) : void
		{
			event.chain.addEventListener(ChainPhantasmsEvent.PHANTASM, phantasmHandler);
			event.chain.effect.addEventListener(EffectEvent.REMOVED, effectRemovedHandler);
		}

		private function effectRemovedHandler(event : EffectEvent) : void
		{

			const effect : Effect = event.target as Effect;
			effect.removeEventListener(EffectEvent.REMOVED, effectRemovedHandler);

			for each (var view : PhantasmView in views)
			{
				if (view.effect == effect)
				{
					view.chain.removeEventListener(ChainPhantasmsEvent.PHANTASM, phantasmHandler);
					view.remove();
					view.needsRemove = false;
				}
			}
		}

		protected function phantasmHandler(event : ChainPhantasmsEvent) : void
		{
			var chain : ChainPhantasms = event.chain;
			var pd : PhantasmDef = event.phantasmDef;
			var view : PhantasmView = createView(chain, pd);

			if (view)
			{
				view.execute();
				if (view.needsUpdate || view.needsRemove)
				{
					views.push(view);
				}
			}
		}

		public function createView(chain : ChainPhantasms, pd : PhantasmDef) : PhantasmView
		{
			var view : PhantasmView;

			if (pd is PhantasmDefSprite)
			{
				view = new PhantasmViewSprite(sceneView, chain, pd as PhantasmDefSprite, false);
			}
			else if (pd is PhantasmDefFlyText)
			{
				view = new PhantasmViewFlyText(sceneView, chain, pd as PhantasmDefFlyText);
			}
			else if (pd is PhantasmDefAnim)
			{
				view = new PhantasmViewAnim(sceneView, chain, pd as PhantasmDefAnim);
			}
			else if (pd is PhantasmDefSound)
			{
				view = new PhantasmViewSound(sceneView, chain, pd as PhantasmDefSound);
			}

			if (!view)
			{
				//cry because we didn't get our effect
				sceneView.board.logger.error("createView failed to create PhantasmView for " + pd);
			}
			return view;
		}
	}
}
