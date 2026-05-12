package engine.stat.def
{
	import engine.core.util.Enum;

	public class StatType extends Enum
	{
		// TODO: these need to be game-specific, not engine-specific			

		public static const STRENGTH : StatType = new StatType("STRENGTH", "STR", true, enumCtorKey);
		public static const ARMOR : StatType = new StatType("ARMOR", "ARM", true, enumCtorKey);
		public static const WILLPOWER : StatType = new StatType("WILLPOWER", "WIL", true, enumCtorKey);
		public static const MOVEMENT : StatType = new StatType("MOVEMENT", "MOV", false, enumCtorKey);
		public static const EXERTION : StatType = new StatType("EXERTION", "EXE", true, enumCtorKey);
		public static const ACTIVE_0 : StatType = new StatType("ABILITY_0", "AB0", false, enumCtorKey);
		public static const ACTIVE_1 : StatType = new StatType("ABILITY_1", "AB1", false, enumCtorKey);
		public static const ACTIVE_2 : StatType = new StatType("ABILITY_2", "AB2", false, enumCtorKey);
		public static const KILLS : StatType = new StatType("KILLS", "KIL", false, enumCtorKey);
		public static const BATTLES : StatType = new StatType("BATTLES", "BAT", false, enumCtorKey);
		public static const RANGE : StatType = new StatType("RANGE", "RNG", false, enumCtorKey);
		public static const ARMOR_BREAK : StatType = new StatType("ARMOR_BREAK", "ABK", true, enumCtorKey);
		public static const STRENGTH_ATTACK : StatType = new StatType("STRENGTH_ATTACK", "SAK", true, enumCtorKey);
		public static const MIN_STRENGTH_ATTACK : StatType = new StatType("MIN_STRENGTH_ATTACK", "MSA", true, enumCtorKey);
		public static const PUNCTURE_ATTACK_BONUS : StatType = new StatType("PUNCTURE_ATTACK_BONUS", "PAB", true, enumCtorKey);
		public static const MALICE_ATTACK_BONUS : StatType = new StatType("MALICE_ATTACK_BONUS", "MAB", true, enumCtorKey);
		public static const BRINGTHEPAIN_COUNTER_BONUS : StatType = new StatType("BRINGTHEPAIN_COUNTER_BONUS", "BCB", true, enumCtorKey);
		public static const FAKE_MISS_CHANCE : StatType = new StatType("FAKE_MISS_CHANCE", "FMC", false, enumCtorKey);
		public static const RANK : StatType = new StatType("RANK", "RNK", false, enumCtorKey);
		public static const MASTER_ABILITY_SUNDERING_IMPACT : StatType = new StatType("MASTER_ABILITY_SUNDERING_IMPACT", "SUI", true, enumCtorKey);
		public static const RESIST_STRENGTH : StatType = new StatType("RESIST_STRENGTH", "RST", true, enumCtorKey);
		public static const RESIST_ARMOR : StatType = new StatType("RESIST_ARMOR", "RAR", true, enumCtorKey);
		public static const NEVER_MISS : StatType = new StatType("NEVER_MISS", "NVM", true, enumCtorKey);
		public static const INJURY_DAYS : StatType = new StatType("INJURY_DAYS", "IJD", true, enumCtorKey);
		public static const INJURY : StatType = new StatType("INJURY", "INJ", true, enumCtorKey);

		public var volatile : Boolean;
		public var abbrev : String;

		public function StatType(name : String, abbrev : String, volatile : Boolean, key : Object)
		{
			super(name, key);
			this.abbrev = abbrev;
			this.volatile = volatile;
		}
	}
}
