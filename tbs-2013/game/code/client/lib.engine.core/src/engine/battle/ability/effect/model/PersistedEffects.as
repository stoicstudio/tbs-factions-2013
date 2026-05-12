package engine.battle.ability.effect.model
{
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	import engine.battle.ability.model.BattleAbilityRetargetInfo;
	import engine.battle.ability.model.IBattleAbility;
	import engine.battle.board.model.IBattleEntity;
	import engine.core.logging.ILogger;

	public class PersistedEffects extends EventDispatcher implements IPersistedEffects
	{
		public var target : IBattleEntity;
		public var _effects : Vector.<IEffect> = new Vector.<IEffect>;
		public var casted : Vector.<IEffect> = new Vector.<IEffect>;
		private var _locked : Boolean;
		private var effectsNeedPurge : Boolean;
		private var castedEffectsNeedPurge : Boolean;
		private var logger : ILogger;
		private var deferredEffectAdds : Vector.<IEffect> = new Vector.<IEffect>;
		private var tags : Dictionary = new Dictionary;
		private var addingDeferred : Boolean;

		public function PersistedEffects(target : IBattleEntity, logger : ILogger)
		{
			this.target = target;
			this.logger = logger;
		}

		public function get effects() : Vector.<IEffect>
		{
			return _effects;
		}

		public function cleanup() : void
		{
			locked = true;
			for (var i : int = 0; i < effects.length; ++i)
			{
				effects[i].cleanup();
			}
			locked = false;
		}

		public function addCastedEffect(effect : IEffect) : void
		{
			if (locked)
			{
				throw new IllegalOperationError("figure out how to add effects re-entrantly");
			}
			casted.push(effect);
		}

		public function findCastedChildEffects(parent : IBattleAbility, target : IBattleEntity) : IEffect
		{
			for each (var e : IEffect in casted)
			{
				if (e.target == target && e.ability.parent == parent)
				{
					return e;
				}
			}

			return null;
		}

		public function addEffect(effect : IEffect) : void
		{
			if (locked)
			{
				deferredEffectAdds.push(effect);
				return;
			}
			effects.push(effect);
			effect.ability.caster.effects.addCastedEffect(effect);

			for each (var tag : EffectTag in effect.tags)
			{
				addTag(tag);
			}

			dispatchEvent(new PersistedEffectsEvent(PersistedEffectsEvent.CHANGED));
		}

		private function removeCastedEffect(effect : IEffect) : void
		{
			var index : int = casted.indexOf(effect);
			if (index >= 0)
			{
				casted.splice(index, 1);
			}
		}

		public function handleEndTurn() : void
		{
			var p : IEffect;

			for each (p in casted)
			{
				if (p.phase == EffectPhase.APPLIED || p.phase == EffectPhase.COMPLETED)
				{
					(p as Effect).checkExpiration();
				}
			}

			for each (p in effects)
			{
				if (p.phase == EffectPhase.APPLIED || p.phase == EffectPhase.COMPLETED)
				{
					(p as Effect).checkExpiration();
				}
			}

		}

		public function handleStartTurn() : void
		{
			if (_locked)
			{
				throw new IllegalOperationError("not re-entrant (yet)");
			}

			locked = true;

			var p : IEffect;

			for each (p in casted)
			{
				if (p.phase == EffectPhase.APPLIED || p.phase == EffectPhase.COMPLETED)
				{
					p.casterStartTurn();
				}
			}

			for each (p in effects)
			{
				if (p.phase == EffectPhase.APPLIED || p.phase == EffectPhase.COMPLETED)
				{
					p.targetStartTurn();
				}
			}

			locked = false;

		}

		private function purgeRemovedEffects() : void
		{
			if (castedEffectsNeedPurge)
			{
				castedEffectsNeedPurge = false;
				purgeRemovedEffectsFrom(casted);
			}

			if (effectsNeedPurge)
			{
				effectsNeedPurge = false;
				purgeRemovedEffectsFrom(effects);
				dispatchEvent(new PersistedEffectsEvent(PersistedEffectsEvent.CHANGED));
			}
		}

		static private function purgeRemovedEffectsFrom(v : Vector.<IEffect>) : void
		{
			var p : IEffect;
			var n : int = v.length;
			for (var i : int = 0; i < n; )
			{
				p = v[i];
				if (p.phase == EffectPhase.REMOVED)
				{
					// put the removing one on the end
					--n;
					v[i] = v[n];
					v[n] = p;
				}
				else
				{
					++i;
				}
			}

			// now actually remove them
			if (n < v.length)
			{
				v.splice(n, v.length - n);
			}
		}

		public function onCasterEffectPhaseChange(effect : IEffect) : void
		{
			if (effect.phase == EffectPhase.REMOVED)
			{
				if (hasCastedEffect(effect))
				{
					castedEffectsNeedPurge = true;
				}
			}
		}

		public function onTargetEffectPhaseChange(effect : IEffect) : void
		{
			if (effect.phase == EffectPhase.REMOVED)
			{
				if (hasEffect(effect))
				{
					for each (var tag : EffectTag in effect.tags)
					{
						if (target.effects.hasTag(tag)) // tag could just be on an effect, not a persisted effect
						{
							target.effects.removeTag(tag);
						}
					}

					effectsNeedPurge = true;
					dispatchEvent(new PersistedEffectsEvent(PersistedEffectsEvent.CHANGED));
				}
			}

		}

		public function onAbilityExecutingOnTarget(abl : IBattleAbility) : BattleAbilityRetargetInfo
		{
			locked = true;

			var p : IEffect;

			for each (p in effects)
			{
				if (p.phase == EffectPhase.APPLIED || p.phase == EffectPhase.COMPLETED)
				{
					var ari : BattleAbilityRetargetInfo = p.onAbilityExecutingOnTarget(abl);
					if (ari)
					{
						locked = false;
						return ari;
					}
				}
			}

			locked = false;

			return null;
		}

		public function get locked() : Boolean
		{
			return _locked;
		}

		public function set locked(value : Boolean) : void
		{
			if (_locked != value)
			{
				_locked = value;

				if (_locked)
				{
					if (addingDeferred)
					{
						throw new IllegalOperationError("locked while addingDeferred");
					}
					if (deferredEffectAdds.length > 0)
					{
						throw new IllegalOperationError("locked while deferredEffectAdds.length=" + deferredEffectAdds.length)
					}
				}
				else
				{
					addingDeferred = true;
					for each (var e : IEffect in deferredEffectAdds)
					{
						addEffect(e);
					}
					deferredEffectAdds.splice(0, deferredEffectAdds.length);
					addingDeferred = false;

					purgeRemovedEffects();
				}

			}
		}

		public function hasEffect(e : IEffect) : Boolean
		{
			return effects.indexOf(e) >= 0;
		}

		public function hasCastedEffect(e : IEffect) : Boolean
		{
			return casted.indexOf(e) >= 0;
		}

		private function tagCount(tag : EffectTag) : int
		{
			var v : * = tags[tag];
			return v != undefined ? int(v) : 0;
		}

		public function hasTag(tag : EffectTag) : Boolean
		{
			return tagCount(tag) > 0;
		}

		public function removeTag(tag : EffectTag) : void
		{
			var c : int = tagCount(tag);
			if (c <= 0)
			{
				throw new IllegalOperationError("fail tag count");
			}
			tags[tag] = c - 1;
		}

		public function addTag(tag : EffectTag) : void
		{
			tags[tag] = tagCount(tag) + 1;
		}

		public function clearTag(tag : EffectTag) : void
		{
			if (hasTag(tag))
			{
				tags[tag] = 0;
			}
		}
	}
}
