package engine.battle.ability.phantasm.model
{
	import engine.battle.ability.effect.model.BattleFacing;
	import engine.battle.ability.effect.model.Effect;
	import engine.battle.ability.event.TargetAnimEvent;
	import engine.battle.ability.phantasm.def.ChainPhantasmsDef;
	import engine.battle.ability.phantasm.def.PhantasmAnimTriggerDef;
	import engine.battle.ability.phantasm.def.PhantasmDef;
	import engine.battle.ability.phantasm.def.PhantasmTargetMode;
	import engine.battle.board.model.IBattleEntity;
	import engine.core.logging.ILogger;

	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getTimer;

	public class ChainPhantasms extends EventDispatcher implements IChainPhantasms
	{
		private var cursor : int;
		private var startTimer : Timer = new Timer(0, 1);
		private var timer : Timer = new Timer(0, 1);
		private var applyTimer : Timer = new Timer(0, 1);
		private var endTimer : Timer = new Timer(0, 1);

		private var startedTime : int = 0;
		private var _ended : Boolean;
		private var _applied : Boolean;
		public var effect : Effect;
		public var def : ChainPhantasmsDef;
		private var started : Boolean;
		private var starting : Boolean;
		private var allowRotation : Boolean = true;
		private var allowTargetRotation : Boolean = true;
		private var waitingForEffectPhase : Boolean;
		private var waitingForAbilityComplete : Boolean;

		public var logger : ILogger;

		public function ChainPhantasms(effect : Effect, def : ChainPhantasmsDef, logger : ILogger)
		{
			if (effect.def.phantasms == null)
			{
				throw new ArgumentError("no def for chain phantasms");
			}

			this.logger = logger;
			this.effect = effect;
			this.def = def;

			effect.chain = this;

			var caster : IBattleEntity = effect.ability.caster;
			caster.animEventDispatcher.addEventListener(TargetAnimEvent.EVENT, animEvent);
			var target : IBattleEntity = effect.target;
			target.animEventDispatcher.addEventListener(TargetAnimEvent.EVENT, animEvent);

			timer.addEventListener(TimerEvent.TIMER_COMPLETE, timerCompleteHandler);
			applyTimer.addEventListener(TimerEvent.TIMER_COMPLETE, applyTimerCompleteHandler);
			endTimer.addEventListener(TimerEvent.TIMER_COMPLETE, endTimerCompleteHandler);
			startTimer.addEventListener(TimerEvent.TIMER_COMPLETE, startTimerCompleteHandler);
		}

		override public function toString() : String
		{
			return effect.ability.def.id + ":" + effect.def.name;
		}

		public function cleanup() : void
		{
			if (!effect || !effect.ability)
			{
				return;
			}

			//logger.debug("ChainPhantasms.cleanup " + this);

			var caster : IBattleEntity = effect.ability.caster;
			var target : IBattleEntity = effect.target;

			caster.animEventDispatcher.removeEventListener(TargetAnimEvent.EVENT, animEvent);

			target.animEventDispatcher.removeEventListener(TargetAnimEvent.EVENT, animEvent);

			timer.removeEventListener(TimerEvent.TIMER_COMPLETE, timerCompleteHandler);
			applyTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, applyTimerCompleteHandler);
			endTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, endTimerCompleteHandler);
			startTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, startTimerCompleteHandler);

			this.effect = null;
			this.def = null;
		}

		private var hasTriggeredPhantasms : Dictionary = new Dictionary;

		public function animEvent(event : TargetAnimEvent) : void
		{
			var key : String = "";
			if (event.entity == effect.ability.caster)
			{
				key = PhantasmAnimTriggerDef.getKey(PhantasmTargetMode.CASTER, event.animId, event.eventId);
			}
			else
			{
				key = PhantasmAnimTriggerDef.getKey(PhantasmTargetMode.TARGET, event.animId, event.eventId);
			}

			var triggered : Vector.<PhantasmDef> = def.animTriggerEntriesMap[key];

			if (triggered)
			{
				for each (var pd : PhantasmDef in triggered)
				{
					//logger.debug("ChainPhantasms.animEvent " + key + " triggered " + pd);

					const delayMs : int = pd.animTrigger ? pd.animTrigger.deltaMs : 0;
					executePhantasm(pd, delayMs, true);
				}
			}

			for each (var applyTrigger : PhantasmAnimTriggerDef in def.applyTriggers)
			{
				if (applyTrigger.key == key)
				{
					//logger.debug("ChainPhantasms.animEvent " + key + " applyTrigger delta " + applyTrigger.deltaMs);

					applyTimer.stop();
					applyTimer.reset();
					applyTimer.delay = applyTrigger.deltaMs;
					applyTimer.start();
					break;
				}
			}

			for each (var endTrigger : PhantasmAnimTriggerDef in def.endTriggers)
			{
				if (endTrigger.key == key)
				{
					//logger.debug("ChainPhantasms.animEvent " + key + " endTrigger delta " + endTrigger.deltaMs);

					endTimer.stop();
					endTimer.reset();
					endTimer.delay = endTrigger.deltaMs;
					endTimer.start();
					break;
				}
			}
		}

		public function get applied() : Boolean
		{
			return _applied;
		}

		public function set applied(value : Boolean) : void
		{
			if (_applied != value)
			{
				_applied = value;

				logger.debug("ChainPhantasms.applied " + this + " " + _applied);

				// sync apply phantasms
				var synctag : String = "apply";
				executeSynced(synctag, null);

				dispatchEvent(new ChainPhantasmsEvent(ChainPhantasmsEvent.APPLIED, this, null));
			}
		}

		private function executeSynced(synctag : String, from : PhantasmDef) : void
		{
			if (!synctag)
			{
				return;
			}

			//logger.debug("ChainPhantasms.executeSynced " + synctag + " from " + from);

			// target faces attack on sync
			// JU_TODO: eventually will want to make this datadriven from the ablities file
			if (def.rotation && allowTargetRotation && synctag == "apply")
			{
				if (effect.target)
				{
					var caster : IBattleEntity = effect.ability.caster;

					if (caster != effect.target)
					{
						if (!effect.target.mobility.moving)
						{
							if (!effect.target.ignoreTargetRotation)
							{
								effect.target.facing = BattleFacing.findFacing(caster.centerX - effect.target.centerX, caster.centerY - effect.target.centerY);
							}
						}
					}
				}
			}

			for each (var pd : PhantasmDef in def.entries)
			{
				if (pd == from)
				{
					return;
				}

				if (pd.sync == synctag)
				{
					executePhantasm(pd, 0, false);
				}
			}
		}

		private var delayedPhantasms : Dictionary = new Dictionary;

		private function executePhantasm(pd : PhantasmDef, delay : int, doSync : Boolean) : void
		{
			if (pd.casterTagReqs != null)
			{
				if (pd.casterTagReqs.checkTags(this.effect.ability.caster.effects) == false)
				{
					//logger.debug("[][][] casterTagReqs failed on " + this + " pd = " + pd);
					return;
				}
				else
				{
					//logger.debug("[][][] casterTagReqs SUCCESS on " + this + " pd = " + pd);
				}
			}
			if (delay > 0)
			{
				const timer : Timer = new Timer(delay, 1);
				timer.addEventListener(TimerEvent.TIMER_COMPLETE, phantasmDelayTimerCompleteHandler);
				delayedPhantasms[timer] = {pd: pd, delay: delay, doSync: doSync};
				timer.start();
				return;
			}

			hasTriggeredPhantasms[pd] = pd;
			//logger.debug("ChainPhantasms.executePhantasm [" + pd + "] sync=" + pd.sync);
			dispatchEvent(new ChainPhantasmsEvent(ChainPhantasmsEvent.PHANTASM, this, pd));

			if (doSync && pd.sync)
			{
				executeSynced(pd.sync, pd);
			}
		}

		private function phantasmDelayTimerCompleteHandler(event : TimerEvent) : void
		{
			const timer : Timer = event.target as Timer;
			timer.removeEventListener(TimerEvent.TIMER_COMPLETE, phantasmDelayTimerCompleteHandler);
			const param : Object = delayedPhantasms[timer];
			const pd : PhantasmDef = param.pd;
			const doSync : Boolean = param.doSync;
			delete delayedPhantasms[timer];
			executePhantasm(pd, 0, doSync);
		}

		public function get ended() : Boolean
		{
			return _ended;
		}

		public function set ended(value : Boolean) : void
		{
			if (_ended != value)
			{
				///logger.debug("ChainPhantasms.ending... " + this);

				var wasApplied : Boolean = _applied;
				if (value && !wasApplied)
				{
					logger.info("ChainPhantasms.ended force-APPLY " + this);
					// make sure we are applied!
					applied = true;
				}

				//logger.debug("ChainPhantasms.ended " + this);

				_ended = value;

				handleGuaranteedTriggers();

				dispatchEvent(new ChainPhantasmsEvent(ChainPhantasmsEvent.ENDED, this, null));

			}
		}

		private function handleGuaranteedTriggers() : void
		{
			for (var timero : Object in delayedPhantasms)
			{
				var timer : Timer = timero as Timer;
				timer.stop();
				timer.removeEventListener(TimerEvent.TIMER_COMPLETE, phantasmDelayTimerCompleteHandler);

				const param : Object = delayedPhantasms[timer];
				const pd : PhantasmDef = param.pd;

				executePhantasm(pd, 0, false);
			}

			for each (var entry : PhantasmDef in def.entries)
			{
				if (entry.animTrigger && entry.animTrigger.guaranteed)
				{
					if (!(entry in hasTriggeredPhantasms))
					{
						logger.info("ChainPhantasms.handleGuaranteedTriggers FULFILLING GUARANTEE for " + entry);
						executePhantasm(entry, 0, false);
					}
				}
			}
		}

		protected function timerCompleteHandler(event : TimerEvent) : void
		{
			process();
		}

		protected function applyTimerCompleteHandler(event : TimerEvent) : void
		{
			applied = true;
		}

		protected function endTimerCompleteHandler(event : TimerEvent) : void
		{
			ended = true;
		}

		protected function startTimerCompleteHandler(event : TimerEvent) : void
		{
			internalStart();
		}

		public function start(delay : int, allowRotation : Boolean, allowTargetRotation : Boolean) : void
		{
			if (started)
			{
				throw new IllegalOperationError("already started");
			}

			this.allowRotation = allowRotation;
			this.allowTargetRotation = allowTargetRotation;
			timer.stop();
			timer.reset();
			cursor = 0;

			starting = true;

			if (delay > 0)
			{
				startTimer.delay = delay;
				startTimer.start();
				return;
			}

			if (def.waitEffect)
			{
				var waitEffect : Effect = effect.ability.getEffectByDef(def.waitEffect);
				if (!waitEffect || waitEffect.phase.index < def.waitEffectPhase.index)
				{
					waitingForEffectPhase = true;
				}
			}

			if (effect.waitForAbility)
			{
				if (!effect.waitForAbility.completed)
				{
					logger.info("Chain waiting for ability " + effect.waitForAbility);
					waitingForAbilityComplete = true;
				}
			}

			internalStart();
		}

		private function internalStart() : void
		{
			if (started)
			{
				throw new IllegalOperationError("already started");
			}
			else if (!starting)
			{
				throw new IllegalOperationError("not starting");
			}

			if (startTimer.running)
			{
				// waiting on some action here
				return;
			}

			if (waitingForAbilityComplete || waitingForEffectPhase)
			{
				// waiting on something to happen
				return;
			}

			starting = false;
			started = true;
			startedTime = getTimer();

			dispatchEvent(new ChainPhantasmsEvent(ChainPhantasmsEvent.STARTED, this, null));

			applyTimer.delay = def.applyTime;
			endTimer.delay = def.endTime;

			// turn to face
			if (def.rotation)
			{
				var caster : IBattleEntity = effect.ability.caster;

				if (allowRotation)
				{
					if (effect.target && caster != effect.target)
					{
						caster.facing = BattleFacing.findFacing(effect.target.centerX - caster.centerX, effect.target.centerY - caster.centerY);
					}
					else if (effect.tile)
					{
						caster.facing = BattleFacing.findFacing(effect.tile.centerX - caster.centerX, effect.tile.centerY - caster.centerY);
					}
				}
			}

			process();

			if (def.applyTime == 0)
			{
				applied = true;
			}
			else
			{
				applyTimer.start();
			}

			if (def.endTime == 0)
			{
				ended = true;
			}
			else
			{
				endTimer.start();
			}
		}

		public function process() : void
		{
			var now : int = getTimer();
			var dt : Number = now - startedTime;

			for (; cursor < def.timedEntries.length; ++cursor)
			{
				var entry : PhantasmDef = def.timedEntries[cursor];
				if (entry.time >= 0 && entry.time <= dt)
				{
					executePhantasm(entry, 0, true);
					// execute the entry and keep going
					continue;
				}

				// this one happens in the future so give up on it
				break;
			}

			// do we have any entries remaining
			if (cursor < def.timedEntries.length)
			{
				var nextEntry : PhantasmDef = def.timedEntries[cursor];
				var nextTimer : int = Math.max(nextEntry.time - dt);
				timer.delay = nextTimer;
				timer.start();
			}
		}

		public function onEffectPhaseChange(e : Effect) : void
		{
			if (!starting)
			{
				return;
			}

			if (def.waitEffect == e.def)
			{
				if (e.phase.index >= def.waitEffectPhase.index)
				{
					waitingForEffectPhase = false;
					internalStart();
				}
			}

		}

		public function onWaitAbilityComplete() : void
		{
			if (!starting)
			{
				return;
			}

			logger.info("Chain ability complete " + effect.waitForAbility);
			waitingForAbilityComplete = false;
			internalStart();
		}
	}
}
