package engine.entity.def
{
	import engine.core.util.Enum;

	public class EntityIconType extends Enum
	{
		public static const SUBST_SRC : String = ".icon.";

		public static const INIT_ORDER : EntityIconType = new EntityIconType("INIT_ORDER", ".icon.init.order.", enumCtorKey);
		public static const INIT_ACTIVE : EntityIconType = new EntityIconType("INIT_ACTIVE", ".icon.init.active.", enumCtorKey);
		public static const PARTY : EntityIconType = new EntityIconType("PARTY", ".icon.party.", enumCtorKey);
		public static const ROSTER : EntityIconType = new EntityIconType("ROSTER", ".icon.roster.", enumCtorKey);

		private var subst : String;

		public function EntityIconType(name : String, subst : String, key : Object)
		{
			super(name, key);
			this.subst = subst;
		}

		public function transform(src : String) : String
		{
			var t : String = src.replace(SUBST_SRC, subst);
			return t;
		}

	}
}
