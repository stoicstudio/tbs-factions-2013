package engine.session
{
	import engine.core.util.Enum;

	public class AlertStyleType extends Enum
	{
		public static const NORMAL : AlertStyleType = new AlertStyleType("NORMAL", enumCtorKey);
		public static const TOURNEY : AlertStyleType = new AlertStyleType("TOURNEY", enumCtorKey);
		public static const VS_QUICK : AlertStyleType = new AlertStyleType("VS_QUICK", enumCtorKey);
		public static const VS_RANKED : AlertStyleType = new AlertStyleType("VS_RANKED", enumCtorKey);
		public static const VS_TOURNEY : AlertStyleType = new AlertStyleType("VS_TOURNEY", enumCtorKey);

		public function AlertStyleType(name : String, key : Object)
		{
			super(name, key);
		}
	}
}
