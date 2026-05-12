package engine.stat.model
{

	import engine.stat.def.StatType;

	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;

	public class Stat extends EventDispatcher
	{
		private var _type : StatType;
		private var _value : int;
		private var _base : int;
		private var _original : int;
		public var provider : IStatsProvider;
		private var _mods : Vector.<StatMod> = new Vector.<StatMod>;
		private var consuming : Boolean;
		private var locked : Boolean = true;

		public function Stat(type : StatType, value : int, locked : Boolean)
		{
			if (type == StatType.INJURY)
			{
				locked = false;
			}

			_base = value;
			_value = value;
			_type = type;
			_original = value;
			this.locked = locked;
		}

		/**
		 * This strips off the mods.
		 * @return
		 *
		 */
		public function clone() : Stat
		{
			var stat : Stat = new Stat(type, base, locked);

			for each (var mod : StatMod in _mods)
			{
				stat.addMod(mod.provider, mod.amount, mod.charges);
			}
			stat.setValue(this.value);
			stat.internalSetOriginal(_original);
			return stat;
		}

		private function internalSetOriginal(value : int) : void
		{
			_original = value;
		}

		public function get type() : StatType
		{
			return _type;
		}

		public function get value() : int
		{
			return _value;
		}

		public function modify(delta : int) : void
		{
			setValue(value + delta);
		}

		public function setValue(value : int) : void
		{
			if (_value != value)
			{
				if (locked && value != _base)
				{
					throw new IllegalOperationError("Cannot modify locked stat value!.  Set the base instead");
				}

				var d : int = value - _value;
				_value = value;
				dispatchEvent(new StatEvent(StatEvent.CHANGE, d));
			}
		}

		public function get mods() : Vector.<StatMod>
		{
			return _mods;
		}

		override public function toString() : String
		{
			return "[" + provider + " " + _value + "]";
		}

		public function addMod(provider : IStatModProvider, amount : int, charges : int) : void
		{
			var mod : StatMod = new StatMod(this, provider, amount, charges);
			mods.push(mod);
		}

		public function removeMods(provider : IStatModProvider) : void
		{
			for (var i : int = 0; i < mods.length; ++i)
			{
				var mod : StatMod = mods[i];
				if (mod.provider == provider)
				{
					mod.internalConsume();
				}
			}

			if (consuming)
			{
				return;
			}

			purgeMods();
		}

		public function get modDelta() : int
		{
			return value - base;
		}

		public function get consume() : int
		{
			var old : int = value;

			consuming = true;

			for (var i : int = 0; i < mods.length; ++i)
			{
				var mod : StatMod = mods[i];
				mod.consume();
			}
			consuming = false;

			purgeMods();

			return old;
		}

		public function purgeMods() : void
		{
			for (var i : int = 0; i < mods.length; )
			{
				var mod : StatMod = mods[i];
				if (mod.consumed || mod.provider.removed)
				{
					mods.splice(i, 1);
				}
				else
				{
					++i;
				}
			}
		}

		public function get original() : int
		{
			return _original;
		}

		public function get base() : int
		{
			return _base;
		}

		/**
		 * This is the unmodified stat.  For entity defs, value always equals base.  In combat, they can diverge (buffs, damage, etc...)
		 * @param b
		 *
		 */
		public function set base(b : int) : void
		{
			if (b == _base)
			{
				return;
			}

			var d : int = b - _base;
			_base = b;
			setValue(value + d);
			if (locked)
			{
				_original = base;
			}

			dispatchEvent(new StatEvent(StatEvent.BASE_CHANGE, d));
		}

	}
}
