package engine.def
{
	import flash.errors.IllegalOperationError;

	import engine.core.logging.ILogger;

	public class EngineJsonDef
	{
		public static var _validate : Function;

		public static function validateThrow(vars : Object, schema : Object, logger : ILogger) : void
		{
			if (_validate == null)
			{
				return;
//				throw new IllegalOperationError("EngineJsonDef was not configured");
			}

			if (!_validate(vars, schema, logger).isValid())
			{
				throw new ArgumentError("failed to parse " + schema.name);
			}
		}

	}
}
