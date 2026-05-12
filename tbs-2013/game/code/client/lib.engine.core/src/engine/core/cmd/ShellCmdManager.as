package engine.core.cmd
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	import engine.core.logging.ILogger;

	public class ShellCmdManager extends Cmder
	{
		private var cmdlist : Vector.<String> = new Vector.<String>;
		private var lowerCmds : Dictionary = new Dictionary;
		protected var logger : ILogger;
		public var shellCmdHistory : ShellCmdHistory;

		public function ShellCmdManager(logger : ILogger)
		{
			this.logger = logger;
			add("", shellCmdFuncHelp);
			add("?", shellCmdFuncHelp);
			add("help", shellCmdFuncHelp);
			add("history", shellCmdFuncHistory);
		}

		public function cleanup() : void
		{
			dispatchEvent(new Event(Event.COMPLETE));
			cmdlist = null;
			lowerCmds = null;
			logger = null;
			shellCmdHistory = null;
		}

		public function add(name : String, func : Function) : Cmd
		{
			var ln : String = name.toLowerCase();
			if (ln in lowerCmds)
			{
				throw new ArgumentError("Attempt to double add cmd " + name);
			}

			var cmd : ShellCmd = new ShellCmd(name, func);
			lowerCmds[ln] = cmd;
			cmdlist.push(name);
			registerCmd(cmd);
			return cmd;
		}

		public function removeShell(name : String) : void
		{
			var ln : String = name.toLowerCase();
			var cmd : Cmd = lowerCmds[ln];
			delete lowerCmds[ln];

			if (cmd)
			{
				unregisterCmd(cmd);
			}

			var index : int = cmdlist.indexOf(name);
			if (index >= 0)
			{
				cmdlist.splice(index, 1);
			}
		}

		public function addShell(name : String, shell : ShellCmdManager) : void
		{
			shell.addEventListener(Event.COMPLETE, function(e : Event) : void
			{
				removeShell(name);
			});

			var func : Function = function(c : CmdExec) : void
			{
				var argv : Array = c.param;
				argv = argv.slice(1);
				if (!shell.execArgv(argv))
				{
					if (argv.length > 0)
					{
						logger.info("No such subcommand for " + c.cmd.name + ": " + argv[0]);
					}
					else
					{
						logger.info("Empty subcommand not supported by " + c.cmd.name);
					}
				}
			}

			add(name, func);
		}

		public function execSubShell(c : CmdExec) : void
		{
			var argv : Array = c.param;
			argv = argv.slice(1);
			execArgv(argv);
		}

		public function execArgv(argv : Array) : Boolean
		{
			var lower : String = "";
			if (argv.length > 0)
			{
				lower = (argv[0] as String).toLowerCase();
			}

			var cmd : ShellCmd = lowerCmds[lower];
			if (!cmd)
			{
				return false;
			}

			this.execute(cmd, argv);

			return true;
		}

		public function exec(cmdline : String) : Boolean
		{
			if (!cmdline)
			{
				return false;
			}

			if (shellCmdHistory)
			{
				shellCmdHistory.insert(cmdline);
			}
			logger.info("> " + cmdline);

			// TODO allow quoted stuff
			var argv : Array = cmdline.split(" ");
			return execArgv(argv);

		}

		private function shellCmdFuncHelp(c : CmdExec) : void
		{
			logger.info("[" + c.cmd.name + "] Available Commands: ");
			for each (var s : String in cmdlist)
			{
				logger.info("    " + s);
			}
		}

		private function shellCmdFuncHistory(c : CmdExec) : void
		{
			logger.info("History: ");
			if (!shellCmdHistory)
			{
				return;
			}

			for (var i : int = 0; i < shellCmdHistory.cmdlines.length; ++i)
			{
				var s : String = shellCmdHistory.cmdlines[i];
				logger.info(i.toString() + " " + s);
			}
		}
	}
}
