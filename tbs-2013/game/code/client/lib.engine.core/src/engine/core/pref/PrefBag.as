package engine.core.pref
{

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.net.SharedObject;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	import engine.core.logging.ILogger;

	public class PrefBag extends EventDispatcher implements IPrefsOwner
	{
		private static const VERSION : String = "VERSION";

		private var m_store : SharedObject;
		private var prefs : Dictionary = new Dictionary;
		private var defaults : Dictionary = new Dictionary;
		private var latestVersion : int;
		private var dirty : Boolean;
		private var internallyValid : Boolean;
		private var saveTimer : Timer = new Timer(1000, 1);
		private var logger : ILogger;

		public function PrefBag(name : String, latestVersion : int, logger : ILogger, defaultsArray : Array)
		{
			if (!logger)
			{
				throw new ArgumentError("no logger? please!");
			}

			m_store = SharedObject.getLocal(name);

			this.logger = logger;

			if (defaultsArray)
			{
				for each (var d : Object in defaultsArray)
				{
					defaults[d.key] = d.value;
				}
			}

			// what version _should_ our data be?
			this.latestVersion = latestVersion;

			internallyValid = true;
			// our data will be loaded if it is new enough, otherwise ignored
			add(VERSION, latestVersion);

			internallyValid = false;

			if (getPref(VERSION) != latestVersion)
			{
				logger.info("Upgrading prefbag " + name + " from version " + getPref(VERSION) + " to " + latestVersion);
			}
			loadDefaults();
			loadPrefs();

			saveTimer.addEventListener(TimerEvent.TIMER_COMPLETE, timerCompleteHandler);
		}

		protected function timerCompleteHandler(event : TimerEvent) : void
		{
			savePrefs();
		}

		private function loadDefaults() : void
		{
			if (!defaults)
			{
				return;
			}

			for (var k : Object in defaults)
			{
				var v : * = defaults[k];
				add(k as String, v);
			}
		}

		private function loadPrefs() : void
		{
			for (var k : Object in m_store.data)
			{
				var v : * = defaults[k];
				if (!(k in prefs))
				{
					add(k as String, v);
				}
			}
		}

		public function get store() : SharedObject
		{
			return m_store;
		}

		public function prefsChangeListener(event : Event) : void
		{
			// if the timer is already runing, let it complete in the time it expected
			if (!saveTimer.running)
			{
				saveTimer.reset();
				saveTimer.start();
			}

			dirty = true;

			var p : Pref = event.target as Pref;
			dispatchEvent(new PrefEvent(PrefEvent.PREF_CHANGED, p.key, p.value));
		}

		public function get valid() : Boolean
		{
			return internallyValid || getPref(VERSION) == latestVersion;
		}

		protected function add(key : String, v : *) : Pref
		{
			var clazz : Class;
			if (v is String)
			{
				clazz = PrefString;
			}
			else if (v is Number)
			{
				clazz = PrefNumber;
			}
			else if (v is Boolean)
			{
				clazz = PrefBoolean;
			}
			else
			{
				clazz = Pref;
			}

			prefs[key] = new clazz(this, key, v);
			return prefs[key];
		}

		public function setPref(key : String, v : *) : *
		{
			var p : Pref = prefs[key];

			if (!p && v != null)
			{
				add(key, v).forceSet(v);
				return;
			}

			var old : * = p ? p.value : null;

			if (v == null)
			{
				delete prefs[key];
			}
			else if (p) 
			{
				p.value = v;
			}

			return old;
		}

		public function getPref(key : String, clazz : Class = null) : *
		{
			var p : Pref = prefs[key];
			if (!p)
			{
				return null;
			}

			if (clazz && !(p.value is clazz))
			{
				throw new ArgumentError("Invalid class");
			}

			return p.value;
		}

		public function getDefault(key : String, clazz : Class = null) : *
		{
			var v : * = defaults[key];
			if (!v)
			{
				return null;
			}

			if (clazz && !(v is clazz))
			{
				throw new ArgumentError("Invalid class");
			}

			return v;
		}

		public function reset() : void
		{
			m_store.clear();

			// start with fresh pref cache
			prefs = new Dictionary();

			// a version of zero will cause all the defaults to take effect rather than be ignored
			add(VERSION, 0);
			loadDefaults();
		}

		public function savePrefs() : void
		{
			setPref(VERSION, latestVersion);

			if (dirty)
			{
				logger.info("Saving Prefs");
				dirty = false;
				m_store.flush();
				dispatchEvent(new PrefEvent(PrefEvent.PREF_BAG_CHANGED, null, null));
			}
		}
	}
}
