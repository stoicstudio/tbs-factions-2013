package engine.core.locale
{
	import engine.core.util.Enum;

	public class LocaleCategory extends Enum
	{
		public static const IAP : LocaleCategory = new LocaleCategory("IAP", enumCtorKey);
		public static const ENTITY : LocaleCategory = new LocaleCategory("ENTITY", enumCtorKey);
		public static const ABILITY : LocaleCategory = new LocaleCategory("ABILITY", enumCtorKey);
		public static const GUI : LocaleCategory = new LocaleCategory("GUI", enumCtorKey);
		public static const TAUNT : LocaleCategory = new LocaleCategory("TAUNT", enumCtorKey);
		public static const ACHIEVEMENT : LocaleCategory = new LocaleCategory("ACHIEVEMENT", enumCtorKey);
		public static const TUTORIAL : LocaleCategory = new LocaleCategory("TUTORIAL", enumCtorKey);

		public function LocaleCategory(name : String, key : *)
		{
			super(name, key);
		}
	}
}
