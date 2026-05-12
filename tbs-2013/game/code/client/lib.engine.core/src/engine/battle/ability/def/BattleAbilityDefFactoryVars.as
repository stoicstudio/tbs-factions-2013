package engine.battle.ability.def
{
	import flash.errors.IllegalOperationError;
	import flash.events.Event;

	import engine.core.locale.Localizer;
	import engine.core.logging.ILogger;
	import engine.resource.ResourceManager;
	import engine.resource.def.DefResource;

	public class BattleAbilityDefFactoryVars extends BattleAbilityDefFactory
	{
		private var index : DefResource;
		private var resman : ResourceManager;

		private var completeCallback : Function;
		public var ready : Boolean;
		private var localizer : Localizer;

		protected var shouldLink : Boolean = true;
		private var refs : Vector.<BattleAbilityDefFactoryVars> = new Vector.<BattleAbilityDefFactoryVars>;

		private var waitingRefs : int = 0;

		private var url : String;
		private var embeddedFinished : Boolean;

		public function BattleAbilityDefFactoryVars(resman : ResourceManager, logger : ILogger, localizer : Localizer, completeCallback : Function, url : String = null, loadNow : Boolean = true) : void
		{
			this.resman = resman;
			this.logger = logger;
			this.completeCallback = completeCallback;
			this.localizer = localizer;
			if (!url)
			{
				url = "common/ability/_ability_index.json.z";
			}
			this.url = url;
			if (loadNow)
			{
				load();
			}
		}

		public function load() : void
		{
			if (resman)
			{
				index = resman.getResource(url, DefResource) as DefResource;
				index.addResourceListener(indexCompleteHandler);
			}
		}

		private function refCompleteCallback(factory : BattleAbilityDefFactoryVars) : void
		{
			errors += factory.errors;

			// register children up with us
			for each (var ad : BattleAbilityDef in factory.abilityDefs)
			{
				register(ad);
			}

			var where : int = refs.indexOf(factory);
			if (where < 0)
			{
				throw new IllegalOperationError("Ref not found in parent: " + factory);
			}

			--waitingRefs;

			checkReady();
		}

		private function checkReady() : void
		{
			if (ready)
			{
				return;
			}

			if (waitingRefs == 0 && embeddedFinished)
			{
				if (shouldLink)
				{
					link();
				}

				ready = true;

				completeCallback(this);

			}
		}

		private function loadRefs() : void
		{
			for each (var ref : BattleAbilityDefFactoryVars in refs)
			{
				ref.load();
			}
		}

		protected function indexCompleteHandler(event : Event) : void
		{
			// load the references
			if (index.jo.refs != undefined)
			{
				for each (var refUrl : String in index.jo.refs)
				{
					var ref : BattleAbilityDefFactoryVars = new BattleAbilityDefFactoryVars(resman, logger, localizer, refCompleteCallback, refUrl, false);
					refs.push(ref);
					ref.shouldLink = false;
					++waitingRefs;
				}
			}

			loadRefs();

			// parse the embedded abilities
			if (index.jo.abilities != undefined)
			{
				for each (var av : Object in index.jo.abilities)
				{
					registerVars(av, logger, localizer);
				}
			}

			embeddedFinished = true;

			checkReady();
		}

		private function registerVars(vars : Object, logger : ILogger, localizer : Localizer) : void
		{
			try
			{
				register(new BattleAbilityDefVars(vars, logger, localizer));
			}
			catch (e : Error)
			{
				logger.error("Failed to register " + vars.id + " : " + e.getStackTrace());
				++errors;
			}
		}

	}
}
