package engine.core.cmd
{

	public class CmdExec
	{
		public var cmd : Cmd;
		private var input : *;
		/**
		 * information output by the execute, to be used by the undo if necessary
		 */
		private var inputUndo : *;

		public var param : *;

		public function CmdExec(cmd : Cmd, input : *)
		{
			this.cmd = cmd;
			this.input = input;
		}

		public function execute() : void
		{
			param = input;
			var iu : * = cmd.func(this);

			if (!inputUndo)
			{
				// cmd execution only sets the inputUndo the first time through
				inputUndo = iu;
			}
		}

		public function executeUndo() : void
		{
			param = inputUndo;
			cmd.func(this);

			// cmd undo never changes the inputUndo, only reads it
		}

		public function toString() : String
		{
			return "[CmdExec cmd=" + cmd + " input=" + input + "]";
		}
	}
}
