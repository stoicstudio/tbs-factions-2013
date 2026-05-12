package tbs.srv.battle.data;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON;
import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.battle.data.base.BaseBattleData;
import tbs.srv.db.DbHelper;
import tbs.srv.util.GameConfig;

public class BattleCreateData extends BaseBattleData {

	private static final Logger logger = Logger.getLogger(BattleCreateData.class.getSimpleName());
	public Object[] parties;
	public String scene = null;
	public boolean friendly;
	public long create_time;
	public String starting_team;
	public int tourney_id;

	public BattleCreateData() {
	}

	public BattleCreateData(String battleId, String scene, final boolean friendly, int tourney_id, BattlePartyData... parties) {
		super(null, 0, battleId);
		this.parties = parties;
		this.scene = scene;
		this.friendly = friendly;
		this.tourney_id = tourney_id;
	}

	protected String constructReliableMsgId() {
		return battleId + "_create";
	}

	public String toString() {
		return super.toString() + " scene=" + scene;
	}

	public List<BattlePartyData> getTeam(final String team, final boolean match, List<BattlePartyData> results) {
		for (Object po : parties) {
			BattlePartyData bpd = (BattlePartyData) po;
			if (bpd.team.equals(team) == match) {
				if (results == null) {
					results = new ArrayList<BattlePartyData>();
				}

				results.add(bpd);
			}
		}

		return results;
	}

	public int getTeamEloDelta(final String team) {
		int elo = 0;
		if (team == null || team.isEmpty()) {
			return elo;
		}

		for (Object po : parties) {
			BattlePartyData bpd = (BattlePartyData) po;
			if (bpd.team.equals(team)) {
				elo += bpd.elo;
			} else {
				elo -= bpd.elo;
			}
		}
		return elo;
	}

	public int getTeamElo(final String team) {
		int elo = 0;
		for (Object po : parties) {
			BattlePartyData bpd = (BattlePartyData) po;
			if (bpd.team.equals(team)) {
				elo += bpd.elo;
			}
		}
		return elo;
	}

	public int getTeamPower(final String team) {
		int power = 0;
		for (Object po : parties) {
			BattlePartyData bpd = (BattlePartyData) po;
			if (bpd.team.equals(team)) {
				power += bpd.power;
			}
		}
		return power;
	}

	public int getTeamPowerDelta(final String team) {
		int power = 0;
		if (team == null || team.isEmpty()) {
			return power;
		}
		for (Object po : parties) {
			final BattlePartyData bpd = (BattlePartyData) po;
			if (bpd.team.equals(team)) {
				power += bpd.power;
			} else {
				power -= bpd.power;
			}
		}
		return power;
	}

	public Set<String> getTeams(Set<String> results) {
		if (results == null) {
			results = new HashSet<String>();
		}

		for (Object po : parties) {
			BattlePartyData bpd = (BattlePartyData) po;
			results.add(bpd.team);
		}

		return results;
	}

	public Map<String, List<String>> getTeamMembers(Map<String, List<String>> results) {
		if (results == null) {
			results = new HashMap<String, List<String>>();
		}

		for (Object po : parties) {
			BattlePartyData bpd = (BattlePartyData) po;

			List<String> members = results.get(bpd.team);
			if (members == null) {
				members = new ArrayList<String>();
				results.put(bpd.team, members);
			}

			members.add(bpd.display_name);
		}

		return results;
	}

	public BattlePartyData getPartyById(final long id) {
		for (Object po : parties) {
			BattlePartyData bpd = (BattlePartyData) po;
			if (bpd.user == id) {
				return bpd;
			}
		}
		return null;
	}

	public BattlePartyData getPartyByIndex(final int index) {
		return (BattlePartyData) parties[index];
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);
		out.add("parties", parties);
		out.add("scene", scene);
		out.add("friendly", friendly);
		out.add("tourney_id", tourney_id);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {
		super.fromJSON(object);
		parties = (Object[]) object.get("parties");
		scene = (String) object.get("scene");
		friendly = ((Boolean) object.get("friendly")).booleanValue();
		tourney_id = ((Number) object.get("tourney_id")).intValue();
	}

	public void save(GameConfig config) {

		create_time = System.currentTimeMillis();
		starting_team = this.getPartyByIndex(0).team;

		Connection con = null;
		PreparedStatement ps = null;
		try {

			con = config.rdsDatasource.getConnection();

			final String sql = "INSERT INTO battle (battle_id, scene, create_time, battle_create_data, starting_team,friendly, tourney_id) VALUES (?,?,?,?,?,?,?)";

			ps = con.prepareStatement(sql);
			ps.setString(1, battleId);
			ps.setString(2, scene);
			ps.setLong(3, create_time);
			ps.setString(4, JSON.toString(this));
			ps.setString(5, starting_team);
			ps.setBoolean(6, this.friendly);
			ps.setInt(7, tourney_id);
			ps.executeUpdate();
		} catch (SQLException e) {
			logger.error("save :" + e);
			e.printStackTrace();
			return;
		} finally {
			DbHelper.cleanup(con, ps);
		}

		for (Object po : parties) {
			BattlePartyData bpd = (BattlePartyData) po;
			bpd.save(config, this);
		}
	}
}
