package engine.battle.ability.model
{
	import engine.battle.ability.def.BattleAbilityDefFactory;
	import engine.core.logging.ILogger;
	import engine.math.Rng;

	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	public class BattleAbilityManager extends EventDispatcher
	{
		public var logger : ILogger;
		public var factory : BattleAbilityDefFactory;
		private var _lastId : int = 0;
		private var _lastExecutedId : int = 0;
		private var _lastFakeExecutedId : int = 0;
		private var lastFakeId : int = 0;
		public var faking : Boolean;
		private var _rng : Rng;
		private var _fakeRng : Rng;
		private var _numIncompleteAbilities : int;
		private var _incompleteAbilities : Dictionary = new Dictionary;
		public var enabled : Boolean = true;

		private const DEBUG_INCOMPLETES : Boolean = false;

		public function BattleAbilityManager(logger : ILogger, factory : BattleAbilityDefFactory)
		{
			this.logger = logger;
			this.factory = factory;
		}

		public function cleanup() : void
		{
			enabled = false;
		}

		public function get numIncompleteAbilities() : int
		{
			return _numIncompleteAbilities;
		}

		public function get lastExecutedId() : int
		{
			return _lastExecutedId;
		}

		public function get nextId() : int
		{
			if (faking)
			{
				return --lastFakeId;
			}
			return ++_lastId;
		}

		public function get nextExecutedId() : int
		{
			if (faking)
			{
				return --_lastFakeExecutedId;
			}
			return ++_lastExecutedId;
		}

		public function handleStartTurn() : void
		{

		}

		public function get debugIncompletes() : String
		{
			var str : String = "";
			for each (var abl : BattleAbility in _incompleteAbilities)
			{
				str += "\n            " + abl;
			}
			return str;
		}

		public function onAbilityExecuting(abl : BattleAbility) : void
		{
			if (!(abl in _incompleteAbilities))
			{
				++_numIncompleteAbilities;
				_incompleteAbilities[abl] = abl;
			}

			if (!faking)
			{
				if (DEBUG_INCOMPLETES)
				{
					logger.debug("BattleAbilityManager.onAbilityExecuting " + abl + ", incompletes=" + _numIncompleteAbilities + " " + debugIncompletes);
				}
			}

			dispatchEvent(new BattleAbilityEvent(BattleAbilityEvent.EXECUTING, abl));
		}

		public function onAbilityPreComplete(abl : BattleAbility) : void
		{
			if (!faking)
			{
				if (DEBUG_INCOMPLETES)
				{
					logger.debug("BattleAbilityManager.onAbilityPreComplete " + abl);
				}
			}
			dispatchEvent(new BattleAbilityEvent(BattleAbilityEvent.ABILITY_PRE_COMPLETE, abl));
		}

		public function onAbilityPostComplete(abl : BattleAbility) : void
		{
			if (!faking)
			{
				if (DEBUG_INCOMPLETES)
				{
					logger.debug("BattleAbilityManager.onAbilityPostComplete " + abl);
				}
			}
			dispatchEvent(new BattleAbilityEvent(BattleAbilityEvent.ABILITY_POST_COMPLETE, abl));
		}

		public function onAbilityFinalComplete(abl : BattleAbility) : void
		{
			if (!faking)
			{
				if (DEBUG_INCOMPLETES)
				{
					logger.debug("BattleAbilityManager.onAbilityFinalComplete " + abl);
				}
			}

			dispatchEvent(new BattleAbilityEvent(BattleAbilityEvent.FINAL_COMPLETE, abl));

			if (abl in _incompleteAbilities)
			{
				--_numIncompleteAbilities;
				delete _incompleteAbilities[abl];

				if (!faking)
				{
					if (DEBUG_INCOMPLETES)
					{
						logger.debug("BattleAbilityManager.onAbilityFinalComplete " + abl + ", incompletes=" + _numIncompleteAbilities + " " + debugIncompletes);
					}
				}
				if (!_numIncompleteAbilities)
				{
					dispatchEvent(new BattleAbilityEvent(BattleAbilityEvent.INCOMPLETES_EMPTY, abl));
				}
			}
		}

		public function onAbilityAndChildrenComplete(abl : BattleAbility) : void
		{
			if (!faking)
			{
				if (DEBUG_INCOMPLETES)
				{
					logger.debug("BattleAbilityManager.onAbilityAndChildrenComplete " + abl);
				}
			}

			dispatchEvent(new BattleAbilityEvent(BattleAbilityEvent.ABILITY_AND_CHILDREN_COMPLETE, abl));
		}

		public function get rng() : Rng
		{
			// if this gets called before the rng is seeded, the rngs will be null!

			if (faking)
			{
				return _fakeRng;
			}

			return _rng;
		}

		public function set seedRng(value : int) : void
		{
			_rng = new Rng(value);
			_fakeRng = new Rng(value);
		}

	}
}
