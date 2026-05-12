package engine.core.fsm
{
	import flash.utils.Dictionary;

	public class StateData
	{
		public var values : Dictionary = new Dictionary;

		public function StateData()
		{
		}

		public function getValue(key : StateDataEnum) : *
		{
			return values[key];
		}

		public function setValue(key : StateDataEnum, value : *) : void
		{
			values[key] = value;
		}

		public function hasValue(key : StateDataEnum) : Boolean
		{
			return values[key];
		}

		public function removeValue(key : StateDataEnum) : void
		{
			delete values[key];
		}
	}
}
