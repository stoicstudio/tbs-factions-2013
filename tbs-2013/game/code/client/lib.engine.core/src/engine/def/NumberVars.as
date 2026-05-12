package engine.def
{

	public class NumberVars
	{
		public function NumberVars()
		{
		}

		public static function parse(vars : *, d : Number = 0) : Number
		{
			if (vars == undefined)
			{
				return d;
			}

			if (vars is Number)
			{
				return vars;
			}
			else if (vars is String)
			{
				return vars;
			}
			else
			{
				return d;
			}
		}
	}
}
