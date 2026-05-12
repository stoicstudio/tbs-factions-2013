package engine.core.fsm
{

	public class StatePhase
	{
		/**
		 * A newly created state prior to configuration
		 */
		public static const INIT : StatePhase = new StatePhase(0, "INIT");
		/**
		 * The state has become active on the Fsm and is waiting on any necessary input data and conditions.
		 * This phase may persist indefinitely, or advance immediately to ENTERED for most simple states.
		 */
		public static const ENTERING : StatePhase = new StatePhase(1, "ENTERING");
		/**
		 * The state has aquired all necessary input and is operating normally.
		 * This phase may persist indefinitely, and may be interrupted by a force state transition.
		 */
		public static const ENTERED : StatePhase = new StatePhase(2, "ENTERED");
		/**
		 * The state is trying to complete and waiting on any necessary activity to finish
		 */
		public static const COMPLETING : StatePhase = new StatePhase(3, "COMPLETING");
		/**
		 * The state has completed.  When a state enters this phase, a new state transition is automatically triggered on the Fsm
		 */
		public static const COMPLETED : StatePhase = new StatePhase(4, "COMPLETED");
		/**
		 * The state has failed.  When a state enters this phase, a new state transition is automatically triggered on the Fsm
		 */
		public static const FAILED : StatePhase = new StatePhase(5, "FAILED");
		/**
		 * The state was interrupted by a forced transition.
		 */
		public static const INTERRUPTED : StatePhase = new StatePhase(6, "INTERRUPTED");

		private var m_value : int;
		public var name : String;

		public function StatePhase(value : int, name : String)
		{
			this.m_value = value;
			this.name = name;
		}

		public function get value() : int
		{
			return m_value;
		}

		public function toString() : String
		{
			return name;
		}
	}
}
