package engine.core.fsm
{
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import engine.core.cmd.CmdExec;
	import engine.core.cmd.ShellCmdManager;
	import engine.core.logging.ILogger;

	public class Fsm extends EventDispatcher
	{
		public static const TRANS_COMPLETE : uint = 0x1;
		public static const TRANS_FAILED : uint = 0x2;
		public static const TRANS_ALL : uint = 0x3;

		public var states : Dictionary = new Dictionary();
		public var transitionsComplete : Dictionary = new Dictionary();
		public var transitionsFailed : Dictionary = new Dictionary();
		private var m_current : State;
		public var logger : ILogger;
		public var entering : State;
		public var name : String;
		public var errors : Vector.<String> = new Vector.<String>;
		public var ok : Boolean = true;
		public var shell : ShellCmdManager;
		private var msgQueue : FsmMsgQueue;

		public function Fsm(name : String, logger : ILogger)
		{
			if (!logger)
			{
				throw new ArgumentError("All Fsms need a logger");
			}
			this.name = name;
			this.logger = logger;
			this.shell = new ShellCmdManager(logger);
			shell.add("get", shellFuncGetFsm);
			shell.add("state", shellFuncStateFsm);
		}

		protected function useMsgQueue() : void
		{
			if (!msgQueue)
			{
				msgQueue = new FsmMsgQueue(this);
			}
		}

		protected function cleanup() : void
		{

		}

		final public function handleMessages(msgs : Array) : Boolean
		{
			var result : Boolean = true;
			for each (var msg : Object in msgs)
			{
				if (!handleMessage(msg))
				{
					result = false;
				}
			}

			return result;
		}

		final public function handleMessage(msg : Object) : Boolean
		{
			if (msg == null)
			{
				return false;
			}

			if (msg is Array)
			{
				return handleMessages(msg as Array);
			}

			logger.debug("Fsm HANDLE MSG " + current + ": " + msg["class"]);

			if (!handleMsgReceived(msg))
			{
				logger.debug("FSM IGNORE DUPE " + msg);
			}

			if (msgQueue)
			{
				return msgQueue.pushMessage(msg);
			}
			else
			{
				return handleOneMessage(msg);
			}
		}

		protected function handleMsgReceived(msg : Object) : Boolean
		{
			return true;
		}

		public function handleOneMessage(msg : Object) : Boolean
		{
			if (msg == null)
			{
				return false;
			}

			if (current && current.phase.value < StatePhase.COMPLETING.value)
			{
				return current.handleMessage(msg);
			}
			return false;
		}

		override public function toString() : String
		{
			return "[" + name + "/" + m_current + "]";
		}

		private function clazzName(clazz : Class) : String
		{
			var qcn : String = getQualifiedClassName(clazz);
			return qcn;
		}

		public function registerState(clazz : Class) : void
		{
			//logger.debug("Fsm.registerState " + this + " + " + clazzName(clazz));

			if (states[clazz])
			{
				throw new ArgumentError("state already registered: " + clazzName(clazz));
			}

			states[clazz] = clazz;
		}

		public function registerTransition(from : Class, to : Class, flags : uint) : void
		{
			//logger.debug("Fsm.registerTransition " + this + " " + from + " -> " + to + " (" + flags + ")");

			if (from == to)
			{
				throw new ArgumentError("transitioning to yourself is pretty fail");
			}

			if (from)
			{
				findState(from, true);
			}

			findState(to, true);

			if (flags & TRANS_COMPLETE)
			{
				transitionsComplete[from] = to;
			}

			if (flags & TRANS_FAILED)
			{
				transitionsFailed[from] = to;
			}
		}

		private var m_initialState : Class;

		public function set initialState(value : Class) : void
		{
			//logger.debug("Fsm.initialState " + this + " " + value);

			if (!findState(value, true))
			{
				throw new IllegalOperationError("Can't set initial state before registering it!");
			}

			m_initialState = value;
		}

		public function startFsm(data : Object) : void
		{
			//logger.debug("Fsm.startFsm " + this);

			if (current)
			{
				throw new IllegalOperationError("Already started!");
			}

			if (m_initialState == null)
			{
				throw new IllegalOperationError("Attempt to startFsm with no initial state");
			}

			setCurrentState(data, m_initialState);
		}

		public var stopping : Boolean;

		public function stopFsm(ok : Boolean) : void
		{
			logger.info("Fsm.stopFsm " + this + " " + ok);

			this.ok = ok;

			if (!current)
			{
				throw new IllegalOperationError("Not started!");
			}

			stopping = true;
			setCurrent(null);

			if (!ok)
			{
				dispatchEvent(new FsmEvent(FsmEvent.FAIL));
			}

			dispatchEvent(new FsmEvent(FsmEvent.STOP));

			cleanup();
		}

		public function startInitialState(clazz : Class, data : Object) : void
		{
			initialState = clazz;
			startFsm(data);
		}

		public function transitionTo(clazz : Class, data : Object) : void
		{
			if (stopping)
			{
				// we are shutting down, don't fool around with transitioning states
				return;
			}

			//logger.debug("Fsm.transitionTo " + this + " to=" + clazzName(clazz));
			const statClazz : Class = findState(clazz, true);
			setCurrentState(data, statClazz);
		}

		private function setCurrentState(data : Object, clazz : Class) : void
		{
			//logger.debug("Fsm.setCurrentState " + this + " to=" + clazzName(clazz));

			if (clazz == null)
			{
				throw new ArgumentError("invalid clazz");
			}

			if (currentClass == clazz)
			{
				logger.info("Fsm.setCurrentState Already in state " + clazz);
				return;
			}

			// if we have been provided with data, go ahead and set it
			// otherwise, if the state needs data, it must wait for it to arrive
			var state : State = new clazz(data, this, logger) as State;
			setCurrent(state);
			state.enterState();
		}

		public function onStateLoadingChanged(s : State) : void
		{
			if (s == current)
			{
				dispatchEvent(new FsmEvent(FsmEvent.LOADING));
			}
		}

		public function onStatePhaseChanged(s : State, from : StatePhase) : void
		{
			if (s != current)
			{
				logger.debug("Ignoring state phase change on non-current state " + s);
				return;
///				throw new IllegalOperationError("We don't care about this state anymore!  Why is it sending messages!? " + s);
			}

			s.lockPhase = true;

			// notify anyone who cares about this
			// for instance on ENTERING, listeners may need to fill out required input data fields
			// listeners must not change the phase of the state, or cause a transition
			dispatchEvent(new StatePhaseEvent(s, from));

			if (s.isPhase(StatePhase.ENTERING))
			{
				// the state is waiting for required input data fields
				// a forced transition from this phase will result in a failed state
				entering = s;
			}
			else
			{
				// we are no longer waiting on the entering state
				entering = null;
			}

			switch (s.phase)
			{
				case StatePhase.COMPLETING:
					// the state is attempting to reach completion and we must wait on it
					// a forced transition from this phase will result in a failed state
					break;
				case StatePhase.COMPLETED:
					// look for the completed transition and activate it
					dispatchEvent(new FsmEvent(FsmEvent.COMPLETED));

					// if we're still current...
					if (s == current)
					{
						performCompletedTransition();
					}
					
					break;
				case StatePhase.FAILED:
					// look for the failed transition and activate it
					performFailedTransition();
					break;
				case StatePhase.ENTERED:
					s.internalHandleEnteredState();
					popMessages();
					handleCurrentChanged();
					dispatchEvent(new FsmEvent(FsmEvent.CURRENT));

					// now we will sit and wait something to happen, a transition request, whatever
					// a forced transition from this phase will result in a completed state
					break;
				case StatePhase.INTERRUPTED:
					// just ignore an interrupt
					break;
			}

			s.lockPhase = false;
		}

		public function get currentClass() : Class
		{
			if (current)
			{
				return getDefinitionByName(getQualifiedClassName(current)) as Class;
			}
			{
				return null;
			}
		}

		private function performCompletedTransition() : void
		{
			var to : Class = transitionsComplete[currentClass];
			if (to)
			{
				transitionTo(to, current.data);
			}
		}

		private function performFailedTransition() : void
		{
			var to : Class = transitionsFailed[currentClass];
			if (to)
			{
				transitionTo(to, current.data);
			}
			else
			{
				to = transitionsFailed[null];
				if (to)
				{
					transitionTo(to, current.data);
				}
			}
		}

		public function update(delta : Number) : void
		{
			if (entering)
			{
				// this check could trigger a call to our callback
				entering.checkInputDataReady();
			}

			if (current)
			{
				current.update(delta);
			}
		}

		private function findState(clazz : Class, strict : Boolean) : Class
		{
			var found : Class = states[clazz];

			if (!found || found != clazz)
			{
				if (strict)
				{
					throw new ArgumentError("no such state registered: " + clazzName(clazz));
				}
			}

			return found;
		}

		public function get current() : State
		{
			return m_current;
		}

		private function setCurrent(value : State) : void
		{
			if (m_current)
			{
				m_current.interrupt();

				var old : State = m_current;
				m_current.cleanup();
			}
			m_current = value;

		}

		protected function handleCurrentChanged() : void
		{
		}

		public function popMessages() : void
		{
			if (msgQueue)
			{
				msgQueue.popMessages();
			}
		}

		public function addErrorMsg(msg : String) : void
		{
			errors.push(msg);
		}

		public function shellFuncGetFsm(c : CmdExec) : void
		{
			logger.info(this.toString());
		}

		public function shellFuncStateFsm(c : CmdExec) : void
		{
			var argv : Array = c.param;
			if (current && current.shell)
			{
				current.shell.execArgv(argv.slice(1));
			}
			else
			{
				logger.info("Current has no shell handler");
			}
		}
	}
}
