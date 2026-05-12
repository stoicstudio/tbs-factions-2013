package engine.core.fsm
{
	import avmplus.getQualifiedClassName;

	import engine.core.IUpdateable;
	import engine.core.cmd.CmdExec;
	import engine.core.cmd.ShellCmdManager;
	import engine.core.logging.ILogger;

	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;

	/**
	 * A State is insantiated by the Fsm whenever a transition in occurs.
	 * The State object is released after a transition out occurs.
	 * A State is capable of requiring additional input data, in which case, the state remains in the ENTERING phase until the data is satisfied.
	 * @author johnwatson
	 *
	 */
	public class State extends EventDispatcher implements IUpdateable
	{
		private var m_phase : StatePhase = StatePhase.INIT;
		private var m_queuedPhase : StatePhase;
		private var m_inputDataReady : Boolean = false;
		private var m_data : StateData;
		private var m_phaseLocked : Boolean;
		private var m_interrupted : Boolean;
		public var fsm : Fsm;
		private var _percentLoaded : Number = 0;
		private var _loading : Boolean;
		public var logger : ILogger;
		public var name : String;
		public var shell : ShellCmdManager;
		private var cleanedup : Boolean;

		public function State(_data : StateData, fsm : Fsm, logger : ILogger)
		{
			this.logger = logger;
			this.fsm = fsm;

			if (_data)
			{
				m_data = _data;
			}
			else
			{
				m_data = new StateData();
			}

			name = avmplus.getQualifiedClassName(this);
			var colon : int = name.lastIndexOf(":");
			name = name.substr(colon + 1);

			shell = new ShellCmdManager(logger);
			shell.add("data", shellCmdFuncState);
		}

		final public function cleanup() : void
		{
			if (cleanedup)
			{
				return;
			}
			cleanedup = true;
			handleCleanup();
		}

		public function handleMessage(msg : Object) : Boolean
		{
			return false;
		}

		/**
		 * Subclass implements this to handle what happens once we get fully into the entered state.
		 * All required input data is guaranteed to be available before this is called
		 *
		 */
		protected function handleEnteredState() : void
		{
			// subclass implement if we want to immediately start completing			
		}

		internal function internalHandleEnteredState() : void
		{
			handleEnteredState();
		}

		/**
		 *
		 */
		protected function handleInterrupted() : void
		{
			// subclass implement if we want to need to deal with interruption			
		}

		/**
		 *
		 */
		protected function handleCleanup() : void
		{
			// subclass implement if we want to need to deal with interruption			
		}

		/**
		 * Subclass implements this to indicate the array of property names (keys) which _must_ exist on the state data before it is ready for ENTERED phase
		 * This is typically implemented by the subclass returning a statically allocated array
		 * @return
		 *
		 */
		protected function getRequiredInputDataKeys() : Array
		{
			// subclass implement
			return null;
		}

		internal function enterState() : void
		{
			logger.debug("State.enterState " + fsm + " " + this);

			// the phase change will trigger callbacks that will allow listeners to add data to the data object if necessary

			phase = StatePhase.ENTERING;

			// see if changing phase made us ready, which results in entering the ENTERED state if so
			checkInputDataReady();
		}

		private function checkEnterState() : void
		{
			if (phase == StatePhase.ENTERING)
			{
				if (inputDataReady)
				{
					phase = StatePhase.ENTERED;
				}
			}
		}

		public function checkInputDataReady() : void
		{
			var req : Array = getRequiredInputDataKeys();
			if (null != req)
			{
				for each (var key : StateDataEnum in req)
				{
					if (!m_data.hasValue(key))
					{
						logger.debug("State " + fsm + " " + this + " unready to due missing data " + key);
						inputDataReady = false;
						return;
					}
				}
			}

			inputDataReady = true;
		}

		private function get inputDataReady() : Boolean
		{
			return m_inputDataReady;
		}

		private function set inputDataReady(b : Boolean) : void
		{
			if (m_inputDataReady != b)
			{
				m_inputDataReady = b;
				if (m_inputDataReady)
				{
					checkEnterState();
				}
			}
		}

		public function set phase(value : StatePhase) : void
		{
			//logger.debug("State.phase " + fsm + " " + this + " " + m_phase + " -> " + value);
			if (m_phaseLocked)
			{
				m_queuedPhase = value;
				return;
			}

			if (value != m_phase)
			{
				if (value.value < m_phase.value)
				{
					throw new IllegalOperationError("cannot phase backwards in the lifecycle from " + m_phase + " to " + value);
				}

				var from : StatePhase = m_phase;
				m_phase = value;
				if (fsm)
				{
					fsm.onStatePhaseChanged(this, from);
				}
			}
		}

		public function get phase() : StatePhase
		{
			return m_phase;
		}

		public function get data() : StateData
		{
			return m_data;
		}

		public function isPhase(s : StatePhase) : Boolean
		{
			return m_phase == s;
		}

		internal function set lockPhase(b : Boolean) : void
		{
			if (b == m_phaseLocked)
			{
				return;
			}

			if (m_phaseLocked && b)
			{
				throw new IllegalOperationError("already locked");
			}

			m_phaseLocked = b;

			if (!m_phaseLocked)
			{
				if (m_queuedPhase)
				{
					var qp : StatePhase = m_queuedPhase;
					m_queuedPhase = null;
					phase = qp;
				}
			}
		}

		internal function get lockPhase() : Boolean
		{
			return m_phaseLocked;
		}

		public function get interrupted() : Boolean
		{
			return m_interrupted;
		}

		public function interrupt() : void
		{
			if (m_phase == StatePhase.COMPLETED || m_phase == StatePhase.INTERRUPTED || m_phase == StatePhase.FAILED)
			{
				// can't interrupt this
				return;
			}

			logger.debug("State.interrupt " + fsm + " " + this);
			handleInterrupted();
			phase = StatePhase.INTERRUPTED;
			lockPhase = true;
		}

//		public function set data(value : Object) : void
//		{
//			m_data = value;
//		}

		override public function toString() : String
		{
			return name;
		}

		public function get percentLoaded() : Number
		{
			return _percentLoaded;
		}

		public function set percentLoaded(value : Number) : void
		{
			if (_percentLoaded != value)
			{
				_percentLoaded = value;

				if (fsm)
				{
					fsm.onStateLoadingChanged(this);
				}
			}
		}

		public function get loading() : Boolean
		{
			return _loading;
		}

		public function set loading(value : Boolean) : void
		{
			if (_loading != value)
			{
				_loading = value;

				if (fsm)
				{
					fsm.onStateLoadingChanged(this);
				}
			}
		}

		public function update(delta : int) : void
		{

		}

		private function shellCmdFuncState(c : CmdExec) : *
		{
			var argv : Array = c.param;
			logger.info(this.toString());
			logger.info("data: " + this.data);

			if (data)
			{
				for (var key : String in data.values)
				{
					logger.info("    " + key + ": " + data.values[key]);
				}
			}
		}
	}
}
