package tbs.srv.data;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashMap;
import java.util.Map;

import javax.sql.DataSource;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.db.DbHelper;
import tbs.srv.util.GameConfig;
import tbs.srv.util.ICharacterClassProvider;

import com.amazonaws.services.cloudfront_2012_03_15.model.InvalidArgumentException;

public class EntityDef implements Convertible {

	private static final Logger logger = Logger.getLogger(EntityDef.class.getSimpleName());

	public String id;
	private String _name;
	public String entityClass;
	public Map<String, Stat> stats = new HashMap<String, Stat>();
	public float autoLevel;
	private int clampCount = 0;
	public long start_date;
	private String name_token;
	public CharacterClassDef characterClassDef;
	public int appearance_acquires = 0;
	public int appearance_index = 0;

	public EntityDef() {

	}

	public EntityDef(final ResultSet rs, final ICharacterClassProvider provider) throws SQLException {

		if (provider == null) {
			throw new IllegalArgumentException("No provider");
		}

		id = rs.getString("unit_id");
		setName(rs.getString("unit_name"));
		entityClass = rs.getString("entity_class");
		start_date = rs.getLong("start_date");
		appearance_acquires = rs.getInt("appearance_acquires");
		appearance_index = rs.getInt("appearance_index");

		setClassDef(provider, false);

		for (StatType st : StatType.values()) {
			if (st.columnName != null) {
				final int val = rs.getInt(st.columnName);
				final Stat stat = setStat(st, val);
				final int clamp = stat.get() - val;
				if (clamp != 0) {
					logger.warn("STAT-CHECK CLAMPED: " + this + " " + stat + " by delta " + clamp);
				}
				clampCount += clamp;
			}
		}

		final int upg = getUpgrades();
		final int max = getMaxUpgrades();
		int fix = upg - max;
		if (fix > 0) {
			logger.warn("STAT-CHECK UPGRADE EXCESS: " + this + " " + upg + "/" + max);

			for (Stat stat : stats.values()) {
				if (fix == 0) {
					break;
				}

				final StatType st = StatType.valueOf(stat.stat);
				if (!st.purchaseable) {
					// doesn't affect upgrades
					continue;
				}

				final int s = stat.get();
				final StatRange sr = characterClassDef.getStatRangeByName(stat.stat);

				if (sr == null) {
					continue;
				}

				// how upgraded is this stat
				final int u = s - sr.min;

				// how much to reduce it by
				final int du = Math.min(u, fix);
				if (du > 0) {
					stat.set(s - du);
					fix -= du;
					logger.warn("STAT-CHECK REVOKE UPGRADE: " + this + " " + stat.stat + " " + s + " to " + stat.get());
					clampCount -= du;
				}
			}
		}

		if (clampCount != 0) {
			logger.warn("STAT-CHECK TOTAL MODIFICATION: " + this + " " + clampCount);
		}

		checkAbilityRanks();
	}

	public EntityDef duplicate(final String new_id) {
		final EntityDef d = new EntityDef();
		d.id = new_id;
		d._name = _name;
		d.entityClass = entityClass;
		d.name_token = name_token;
		d.appearance_acquires = appearance_acquires;
		d.appearance_index = appearance_index;
		d.characterClassDef = characterClassDef;
		for (Stat stat : stats.values()) {

			d.stats.put(stat.stat, stat.clone());
		}

		d.autoLevel = autoLevel;

		return d;
	}

	public int killRenown() {
		return 1;//Math.max(1, getStatValue(StatType.RANK) - 1);
	}

	@Override
	public String toString() {
		return "EntityDef [id=" + id + ", _name=" + _name + ", entityClass=" + entityClass + "]";
	}

	public EntityDef(Map<String, Object> data, final ICharacterClassProvider provider) {
		fromData(data);
		setClassDef(provider, false);
	}

	public void setClassDef(final ICharacterClassProvider provider, boolean silent) {

		final CharacterClassDef cc = provider.getCharacterClassDef(entityClass);

		if (cc == null) {
			throw new InvalidArgumentException("Invalid character class: " + entityClass);
		}

		if (characterClassDef == cc) {
			// don't re-do it
			return;
		}

		characterClassDef = cc;
		applyClassStats();
	}

	private void fromData(Map<String, Object> data) {
		id = (String) data.get("id");
		// power = ((Long) data.get("power")).intValue();

		setName((String) data.get("name"));
		entityClass = (String) data.get("entityClass");
		if (data.containsKey("start_date")) {
			start_date = ((Number) data.get("start_date")).longValue();
		}

		Object[] ss = (Object[]) data.get("stats");
		if (data.containsKey("autoLevel")) {
			autoLevel = ((Number) data.get("autoLevel")).floatValue();
		}
		if (ss != null) {
			for (int i = 0; i < ss.length; ++i) {
				@SuppressWarnings("unchecked")
				Map<String, Object> so = (Map<String, Object>) ss[i];
				Stat stat = new Stat();
				stat.fromJSON(so);
				stats.put(stat.stat, stat);
			}
		}

		if (data.containsKey("appearance_acquires")) {
			appearance_acquires = ((Number) data.get("appearance_acquires")).intValue();
		}

		if (data.containsKey("appearance_index")) {
			appearance_index = ((Number) data.get("appearance_index")).intValue();
		}

		name_token = (String) data.get("name_token");

		checkAbilityRanks();
	}

	public void applyClassStats() {
		// if Stats number more than 32, then this will break
		int allowedStats = 0x000000;

		for (int i = 0; i < characterClassDef.statRanges.length; ++i) {
			final StatRange sr = (StatRange) characterClassDef.statRanges[i];
			// only set the class stat if the stats does not already have the stat
			Stat stat = stats.get(sr.stat);
			final StatType st = StatType.valueOf(sr.stat);
			if (stat == null) {
				stat = new Stat(sr.stat, sr.min);
				stats.put(sr.stat, stat);
				allowedStats |= (1 << st.ordinal());
			}

			// clamp the stats to the class
			stat.set(Math.max(sr.min, Math.min(sr.max, stat.get())));
		}

		final int nnn = getMaxUpgrades() + getUpgrades();
		int additionalStats = (int) (nnn * autoLevel);

		while (additionalStats > 0) {
			boolean found = false;

			for (StatType statType : StatType.values()) {

				if (!statType.purchaseable) {
					continue;
				}

				if ((allowedStats & (1 << statType.ordinal())) == 0) {
					// this stat was not set from the class defaults, meaning it was set explicitly already. we can't autolevel it
					continue;
				}
				final StatRange sr = characterClassDef.getStatRangeByName(statType.name());
				final Stat stat = stats.get(sr.stat);

				if (stat.get() < sr.max) {
					found = true;
					stat.set(stat.get() + 1);
					--additionalStats;
				}

				if (additionalStats <= 0) {
					break;
				}
			}

			if (!found) {
				// no stats to allocate, just give up
				break;
			}
		}

		checkAbilityRanks();
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("id", id);
		out.add("entityClass", entityClass);

		if (autoLevel > 0) {
			out.add("autoLevel", autoLevel);
		}

		if (_name != null && !_name.isEmpty()) {
			out.add("name", _name);
		}

		if (stats != null && stats.size() > 0) {
			out.add("stats", stats.values().toArray());
		}

		out.add("start_date", start_date);

		if (name_token != null) {
			out.add("name_token", name_token);
		}

		out.add("appearance_acquires", appearance_acquires);

		out.add("appearance_index", appearance_index);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {

		id = (String) object.get("id");
		setName((String) object.get("name"));
		entityClass = (String) object.get("entityClass");
		Object[] ss = (Object[]) object.get("stats");
		name_token = (String) object.get("name_token");
		if (object.containsKey("start_date")) {
			start_date = ((Number) object.get("start_date")).longValue();
		}

		if (ss != null) {
			for (int i = 0; i < ss.length; ++i) {
				Stat stat = (Stat) ss[i];
				stats.put(stat.stat, stat);
			}
		}

		if (object.containsKey("autoLevel")) {
			autoLevel = ((Number) object.get("autoLevel")).floatValue();
		}

		if (object.containsKey("appearance_acquires")) {
			appearance_acquires = ((Number) object.get("appearance_acquires")).intValue();
		}

		if (object.containsKey("appearance_index")) {
			appearance_index = ((Number) object.get("appearance_index")).intValue();
		}

		checkAbilityRanks();

	}

	public boolean hasStat(final String name) {
		return stats.containsKey(name);
	}

	public int getStatValue(final StatType stat) {
		return getStatValue(stat.name());
	}

	public int getStatValue(final String name) {
		final Stat stat = stats.get(name);
		if (stat != null) {
			return stat.get();
		} else {
			return 0;
		}
	}

	private void checkAbilityRank(StatType stat) {
		if (characterClassDef == null) {
			return;
		}
		final int r = getStatValue(StatType.RANK);
		final StatRange sr = characterClassDef.getStatRangeByName(stat.name());
		if (sr != null) {
			final int ability_rank = Math.max(sr.min, Math.min(sr.max, r - 1));
			setStat(stat, ability_rank);
		}
	}

	private void checkAbilityRanks() {
		checkAbilityRank(StatType.ABILITY_0);
		checkAbilityRank(StatType.ABILITY_1);
		checkAbilityRank(StatType.ABILITY_2);
	}

	public Stat setStat(final StatType stat, final int value) {
		final Stat s = setStat(stat.name(), value);
		if (s != null) {
			if (stat == StatType.RANK) {
				checkAbilityRanks();
			}
		}
		return s;
	}

	public Stat setStat(final String name, final int value) {

		if (characterClassDef == null) {
			throw new IllegalAccessError("No characterClassDef yet");
		}

		final StatRange sr = characterClassDef.getStatRangeByName(name);

		int clamped = value;

		if (sr != null) {
			clamped = sr.clamp(value);

			if (value != clamped) {
				logger.info("Clamped " + this + " " + name + " " + value + " to " + clamped);
			}
		}

		Stat stat = stats.get(name);
		if (stat != null) {
			stat.set(clamped);
		} else {
			stat = new Stat(name, clamped);
			stats.put(stat.stat, stat);
		}

		return stat;
	}

	public String getName() {
		return _name;
	}

	public void setName(String rhs) {

		this._name = rhs;
	}

	public void resetStats() {
		autoLevel = 0;
		stats = new HashMap<String, Stat>();
		applyClassStats();
	}

	public int getPower() {
		final int rnk = getStatValue(StatType.RANK) - 1; // one based rank
		return rnk;
	}

	public int getMaxUpgrades() {
		final int rnk = getStatValue(StatType.RANK);
		return 9 + rnk;
	}

	public int getUpgrades() {

		int u = 0;
		for (Stat stat : stats.values()) {
			final StatType st = StatType.valueOf(stat.stat);

			if (!st.purchaseable) {
				continue;
			}

			final int s = stat.get();
			final StatRange sr = characterClassDef.getStatRangeByName(stat.stat);

			if (sr != null) {
				if (s < sr.min) {
					throw new IllegalAccessError("Found a stat beneath its minimum for " + this + ", stat=" + stat + ", range=" + sr);
				}
				u += (s - sr.min);
			}
		}

		return u;
	}

	public int getSinglePower(final StatType stat) {
		return getStatValue(stat) - characterClassDef.getStatRangeByName(stat.name()).min;
	}

	public String getUnitKey(final long account_id) {
		return getUnitKey(account_id, id);
	}

	public static String getUnitKey(final long account_id, final String entity) {
		return Long.toString(account_id) + "_" + entity;
	}

	synchronized public void saveDirty(final DataSource ds, final long account_id) {
		StringBuilder sql = new StringBuilder("UPDATE `unit_roster` SET ");

		boolean found = false;
		for (Stat stat : stats.values()) {
			if (stat.isDirty()) {

				StatType st = StatType.valueOf(stat.stat);
				if (st.columnName != null) {
					if (found) {
						sql.append(",");
					}
					found = true;
					sql.append(st.columnName);
					sql.append("=");
					sql.append(stat.get());
				}

				stat.clearDirty();
			}
		}

		if (!found) {
			return;
		}

		final String unit_key = getUnitKey(account_id);
		sql.append(" WHERE `unit_key` = '" + unit_key + "';");

		Connection con = null;
		Statement s = null;
		try {
			con = ds.getConnection();

			// logger.info("EXECUTING " + sql.toString());
			s = con.createStatement();
			s.executeUpdate(sql.toString());
			s.close();

		} catch (SQLException e) {
			logger.error("EntityDef.saveDirty :" + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	public void incrementKills(final long account_id) {
		setStat(StatType.KILLS, getStatValue(StatType.KILLS) + 1);
		incrementKills(GameConfig.instance.rdsDatasource, account_id, id);
	}

	public static void incrementKills(final DataSource ds, final long userid, final String entity) {

		final String key = getUnitKey(userid, entity);
		logger.debug("incrementKills " + userid + " " + entity);
		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = ds.getConnection();
			ps = con.prepareStatement("UPDATE unit_roster SET stat_kil=(stat_kil+1) WHERE unit_key=?");
			ps.setString(1, key);
			ps.executeUpdate();
			ps.close();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

	public static void incrementBattles(final DataSource ds, final long userid, final String entity) {

		final String key = getUnitKey(userid, entity);
		logger.debug("incrementBattles " + userid + " " + entity);
		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = ds.getConnection();
			ps = con.prepareStatement("UPDATE unit_roster SET stat_bat=(stat_bat+1) WHERE unit_key=?");
			ps.setString(1, key);
			ps.executeUpdate();
			ps.close();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

	public static void saveName(final DataSource ds, final long userid, final String entity, final String name) {

		logger.debug("saveName " + userid + " " + entity + " " + name);
		Connection con = null;
		PreparedStatement ps = null;
		final String key = getUnitKey(userid, entity);
		try {
			con = ds.getConnection();
			ps = con.prepareStatement("UPDATE unit_roster SET `unit_name`=? WHERE unit_key=?");
			ps.setString(1, name);
			ps.setString(2, key);
			ps.executeUpdate();
			ps.close();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

	public boolean hasAppearanceAcquired(final int variation) {
		if (variation == 0) {
			return true;
		}

		return (appearance_acquires & (1 << variation)) != 0;
	}

	public void acquireAppearance(final int variation) {
		appearance_acquires |= (1 << variation);
	}

	public void saveAppearance(final long account_id) {

		Connection con = null;
		PreparedStatement ps = null;
		final String key = getUnitKey(account_id, id);
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();
			ps = con.prepareStatement("UPDATE unit_roster SET appearance_acquires=?, appearance_index=? WHERE unit_key=?");
			ps.setInt(1, appearance_acquires);
			ps.setInt(2, appearance_index);
			ps.setString(3, key);
			ps.executeUpdate();
			ps.close();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}
}
