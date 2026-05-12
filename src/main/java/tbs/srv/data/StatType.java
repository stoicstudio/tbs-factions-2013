package tbs.srv.data;

public enum StatType {
	STRENGTH("stat_str", true), //
	ARMOR("stat_arm", true), //
	WILLPOWER("stat_wil", true), //
	EXERTION("stat_exe", true), //
	ARMOR_BREAK("stat_brk", true), //
	RANK("stat_rnk", false), //
	RANGE(null, false), //
	MOVEMENT(null, false), //
	ABILITY_0(null, false), //
	ABILITY_1(null, false), //
	ABILITY_2(null, false), //
	KILLS("stat_kil", false), //
	BATTLES("stat_bat", false);

	// //////////////////////////////////////////////////////////////////////

	public final String columnName;
	public final boolean purchaseable;

	private StatType(final String columnName, final boolean purchaseable) {
		this.columnName = columnName;
		this.purchaseable = purchaseable;
	}
}
