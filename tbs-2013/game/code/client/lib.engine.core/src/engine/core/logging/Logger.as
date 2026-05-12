package engine.core.logging
{
	import flash.utils.getTimer;

	public class Logger implements ILogger
	{
		private var _name : String;
		private var targets : Vector.<ILogTarget> = new Vector.<ILogTarget>;
		private var _debugEnabled : Boolean = false;
		private var _frameNumber : int = 0;

		public function Logger(name : String)
		{
			this._name = name;
		}

		public function debug(str : String) : void
		{
			if (!str)
			{
				return;
			}

			if (_debugEnabled)
			{
				var time : int = getTimer();
				for each (var target : ILogTarget in targets)
				{
					target.debug(this, time, str);
				}
			}
		}

		public function info(str : String) : void
		{
			if (!str)
			{
				return;
			}

			var time : int = getTimer();
			for each (var target : ILogTarget in targets)
			{
				target.info(this, time, str);
			}
		}

		public function error(str : String) : void
		{
			if (!str)
			{
				return;
			}

			var time : int = getTimer();
			for each (var target : ILogTarget in targets)
			{
				target.error(this, time, str);
			}
		}

		public function addTarget(target : ILogTarget) : ILogger
		{
			if (!target)
			{
				throw new ArgumentError("null target");
			}
			targets.push(target);
			return this;
		}

		public function get debugEnabled() : Boolean
		{
			return _debugEnabled;
		}

		public function set debugEnabled(value : Boolean) : void
		{
			_debugEnabled = value;
		}

		public function get name() : String
		{
			return _name;
		}

		public function get frameNumber() : int
		{
			return _frameNumber;
		}

		public function set frameNumber(value : int) : void
		{
			_frameNumber = value;
		}

	}
}
