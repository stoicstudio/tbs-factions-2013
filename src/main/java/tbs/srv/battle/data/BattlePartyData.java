package tbs.srv.battle.data;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.data.EntityDef;
import tbs.srv.data.StatType;
import tbs.srv.db.DbHelper;
import tbs.srv.util.GameConfig;
import tbs.srv.util.VsType;

public class BattlePartyData implements Convertible {

	// private static final Logger logger = Logger.getLogger(BattlePartyData.class.getSimpleName());

	public long session_key;
	public int battle_count;
	public long user;
	public String team;
	public String display_name;
	public Object[] defs;
	public int match_handle;
	public int party_index;
	public int surrender_turn = -1;
	public int power;
	public int elo;
	public int timer;
	public int tourney_id;
	public VsType vs_type;

	public BattlePartyData() {

	}

	public BattlePartyData(final long user, final String team, final String display_name, final Object[] party, final int match_handle, final int party_index,
			final int elo, final int power, final long session_key, final int battle_count, final int timer, final int tourney_id, final VsType vs_type) {
		this.user = user;
		this.team = team;
		this.display_name = display_name;
		this.defs = party;
		this.match_handle = match_handle;
		this.party_index = party_index;
		this.elo = elo;
		this.power = power;
		this.session_key = session_key;
		this.battle_count = battle_count;
		this.timer = timer;
		this.tourney_id = tourney_id;
		this.vs_type = vs_type;
	}

	public String toString() {
		return Long.toString(user) + "/" + display_name;
	}

	public EntityDef getEntityDef(final int index) {
		return (EntityDef) defs[index];
	}

	public EntityDef getEntityDefById(final String id) {
		for (Object o : defs) {
			final EntityDef e = (EntityDef) o;
			if (e.id.equals(id)) {
				return e;
			}
		}
		return null;
	}

	public void setupCharacterClasses() {
		for (Object o : defs) {
			final EntityDef e = (EntityDef) o;
			e.setClassDef(GameConfig.instance, false);
		}
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("user", user);
		out.add("team", team);
		out.add("display_name", display_name);
		out.add("defs", defs);
		out.add("match_handle", match_handle);
		out.add("party_index", party_index);
		if (surrender_turn >= 0) {
			out.add("surrender_turn", surrender_turn);
		}
		out.add("elo", elo);
		out.add("power", power);
		out.add("session_key", session_key);
		out.add("battle_count", battle_count);
		out.add("timer", timer);
		out.add("tourney_id", tourney_id);
		out.add("vs_type", vs_type.name());
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		user = ((Number) jo.get("user")).longValue();
		team = (String) jo.get("team");
		display_name = (String) jo.get("display_name");
		defs = (Object[]) jo.get("defs");
		match_handle = ((Number) jo.get("match_handle")).intValue();
		party_index = ((Number) jo.get("party_index")).intValue();
		timer = ((Number) jo.get("timer")).intValue();
		if (jo.containsKey("surrender_turn")) {
			surrender_turn = ((Number) jo.get("surrender_turn")).intValue();
		}
		if (jo.containsKey("elo")) {
			elo = ((Number) jo.get("elo")).intValue();
		}

		if (jo.containsKey("power")) {
			power = ((Number) jo.get("power")).intValue();
		}

		if (jo.containsKey("tourney_id")) {
			tourney_id = ((Number) jo.get("tourney_id")).intValue();
		}

		session_key = ((Number) jo.get("session_key")).longValue();
		battle_count = ((Number) jo.get("battle_count")).intValue();
		vs_type = VsType.valueOf((String) jo.get("vs_type"));
	}

	public void save(GameConfig config, final BattleCreateData bcd) {

		Connection con = null;
		PreparedStatement ps = null;
		try {

			con = config.rdsDatasource.getConnection();

			{
				final String sql = "INSERT INTO battle_party (battle_id, battle_team, battle_party_index, account_id, display_name, match_handle, `elo`, `power`, create_time, on_starting_team, session_key, battle_count, friendly, timer, tourney_id, vs_type) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
				ps = con.prepareStatement(sql);
				int index = 0;
				ps.setString(++index, bcd.battleId);
				ps.setString(++index, team);
				ps.setLong(++index, party_index);
				ps.setLong(++index, user);
				ps.setString(++index, display_name);
				ps.setInt(++index, match_handle);
				ps.setInt(++index, elo);
				ps.setInt(++index, power);
				ps.setLong(++index, bcd.create_time);
				ps.setBoolean(++index, bcd.starting_team.equals(team));
				ps.setLong(++index, session_key);
				ps.setInt(++index, battle_count);
				ps.setBoolean(++index, bcd.friendly);
				ps.setInt(++index, timer);
				ps.setInt(++index, tourney_id);
				ps.setInt(++index, vs_type.ordinal());
				ps.executeUpdate();
				ps.close();
			}

			final String sql0 = "INSERT INTO battle_party_def (battle_id, account_id, unit_id, entity_class, unit_name, stat_str, stat_arm, stat_wil, stat_exe, stat_brk, stat_rnk, stat_kil) VALUES ";
			final String sql1 = "(?,?,?,?,?,?,?,?,?,?,?,?) ";

			StringBuilder sb = new StringBuilder(sql0);

			for (int i = 0; i < defs.length; ++i) {
				if (i > 0) {
					sb.append(",");
				}
				sb.append(sql1);
			}

			ps = con.prepareStatement(sb.toString());

			int index = 0;
			for (Object edo : defs) {
				EntityDef ed = (EntityDef) edo;

				ps.setString(++index, bcd.battleId);
				ps.setLong(++index, user);
				ps.setString(++index, ed.id);
				ps.setString(++index, ed.entityClass);
				ps.setString(++index, ed.getName());
				ps.setInt(++index, ed.getStatValue(StatType.STRENGTH.name()));
				ps.setInt(++index, ed.getStatValue(StatType.ARMOR.name()));
				ps.setInt(++index, ed.getStatValue(StatType.WILLPOWER.name()));
				ps.setInt(++index, ed.getStatValue(StatType.EXERTION.name()));
				ps.setInt(++index, ed.getStatValue(StatType.ARMOR_BREAK.name()));
				ps.setInt(++index, ed.getStatValue(StatType.RANK.name()));
				ps.setInt(++index, ed.getStatValue(StatType.KILLS.name()));
			}

			ps.executeUpdate();

		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

	public void saveSurrenderTurn(GameConfig config, final String battle_id, final int turn) {
		this.surrender_turn = turn;

		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = config.rdsDatasource.getConnection();
			ps = con.prepareStatement("UPDATE `battle_party` SET `battle_surrender_turn`=? WHERE `battle_id`=? AND `account_id`=?");
			ps.setInt(1, turn);
			ps.setString(2, battle_id);
			ps.setLong(3, user);
			ps.executeUpdate();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

	public void saveComplete(GameConfig config, final String battle_id, final long end_time, final boolean is_victor, final int renown, final int elo_result,
			final boolean complete) {

		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = config.rdsDatasource.getConnection();
			ps = con.prepareStatement("UPDATE `battle_party` SET `complete`=?, `end_time`=?, `is_victor`=?, `renown`=?, `elo_result`=? WHERE `battle_id`=? AND `account_id`=?");
			int index = 0;
			ps.setBoolean(++index, complete);
			ps.setLong(++index, end_time);
			ps.setBoolean(++index, is_victor);
			ps.setInt(++index, renown);
			ps.setInt(++index, elo_result);
			ps.setString(++index, battle_id);
			ps.setLong(++index, user);
			ps.executeUpdate();			
			ps.close();
			
			ps = con.prepareStatement("REPLACE INTO battle_party_history SELECT * FROM battle_party WHERE battle_id=? AND account_id=?");
			index = 0;
			ps.setString(++index, battle_id);
			ps.setLong(++index, user);
			ps.executeUpdate();
			ps.close();
			
			ps = con.prepareStatement("DELETE FROM battle_party WHERE battle_id=? AND account_id=?");
			index = 0;
			ps.setString(++index, battle_id);
			ps.setLong(++index, user);
			ps.executeUpdate();
			ps.close();
			
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

}