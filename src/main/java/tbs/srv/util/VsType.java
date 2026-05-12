package tbs.srv.util;

public enum VsType {
	NONE(false, true, true), //
	QUICK(false, false, false), //
	RANKED(true, true, true), //
	TOURNEY(true, true, true), //
	FRIEND(false, false, false);

	public final boolean equalPower;
	public final boolean eloWindow;
	public final boolean allowRanking;

	private VsType(final boolean _equalPower, final boolean _eloWindow, final boolean _allowRanking) {
		this.equalPower = _equalPower;
		this.eloWindow = _eloWindow;
		this.allowRanking = _allowRanking;
	}
}
