package engine.def
{

	public class BooleanVars
	{
		public function BooleanVars()
		{
		}

		public static function parse(vars : *, d : Boolean = false) : Boolean
		{
			if (vars == undefined)
			{
				return d;
			}

			if (vars is Boolean)
			{
				return vars;
			}
			else if (vars == "false" || vars == "0")
			{
				return false;
			}
			else
			{
				return true;
			}
		}
	}
}
