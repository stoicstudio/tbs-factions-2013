package engine.battle.fsm.state.turn.cmd
{
	import flash.errors.IllegalOperationError;

	public class TurnSeqCmds
	{
		protected var _cmds : Vector.<TurnCmd> = new Vector.<TurnCmd>;
		protected var _executingCmd : TurnCmd;
		protected var _lastCmdOrdinal : int;
		private var _autoSequence : Boolean;
		private var _completing : Boolean;

		public function TurnSeqCmds(autoSequence : Boolean)
		{
			this._autoSequence = autoSequence;
		}

		public function cleanup() : void
		{
			completing();
			if (_executingCmd)
			{
				_executingCmd.cleanup();
			}
		}

		public function get numCmds() : int
		{
			return _cmds.length;
		}

		public function hasOrdinal(value : int) : Boolean
		{
			for each (var c : TurnCmd in _cmds)
			{
				if (c.ordinal == value)
				{
					return true;
				}
			}
			return false;
		}

		public function addCmd(cmd : TurnCmd) : void
		{
			if (!_autoSequence && cmd.requiresOrdering)
			{
				throw new ArgumentError("cannot autosequence " + cmd);
			}

			if (_autoSequence && cmd.ordinal != 0)
			{
				throw new ArgumentError("must autosequence " + cmd);
			}

			if (!_cmds || _completing)
			{
				throw new IllegalOperationError("Already completing");
			}

			if (!_autoSequence)
			{
				if (cmd.ordinal <= _lastCmdOrdinal)
				{
					// this one is a duplicate of something we have already done
					return;
				}
			}

			_cmds.push(cmd);

			checkCmds();
		}

		private function checkCmds() : void
		{
			if (_completing || !_cmds)
			{
				return;
			}

			if (!_executingCmd)
			{
				for (var i : int = 0; i < _cmds.length; ++i)
				{
					const cmd : TurnCmd = _cmds[i];
					if (_autoSequence || cmd.ordinal == (_lastCmdOrdinal + 1))
					{
						_cmds.splice(i, 1);
						executeCmd(cmd);
						return;
					}
				}
			}
		}

		private function executeCmd(cmd : TurnCmd) : void
		{
			if (_executingCmd)
			{
				throw new IllegalOperationError("already executing");
			}

			if (!_autoSequence)
			{
				_lastCmdOrdinal = cmd.ordinal;
			}

			_executingCmd = cmd;

			if (_autoSequence)
			{
				if (_executingCmd.ordinal == 0 && _executingCmd.requiresOrdering)
				{
					_executingCmd.ordinal = ++_lastCmdOrdinal;
				}
			}

			_executingCmd.execute();
		}

		internal function onCmdComplete(cmd : TurnCmd) : void
		{
			if (cmd != _executingCmd)
			{
				throw new ArgumentError("invalid cmd complete");
			}

			_executingCmd.cleanup();
			_executingCmd = null;
			checkCmds();
		}

		public function completing() : void
		{
			if (!_completing)
			{
				_completing = true;

				for each (var cmd : TurnCmd in _cmds)
				{
					cmd.cleanup();
				}
				_cmds = null;
			}
		}
	}
}
