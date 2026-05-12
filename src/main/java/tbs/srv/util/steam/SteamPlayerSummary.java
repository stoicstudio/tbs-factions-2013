package tbs.srv.util.steam;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class SteamPlayerSummary implements Convertible {
	public long steamid;
	public String personaname;
	public String profileurl;
	public String avatar;
	public String avatarmedium;
	public String avatarfull;
	public String realname;
	public String loccountrycode;
	public String locstatecode;
	public int loccityid;

	public void save(final Connection con) throws SQLException {

		final String sql = "replace into `steam_player_summary` (`steamid`, `personaname`, `profileurl`, `avatar`, `avatarmedium`, `avatarfull`, `realname`) VALUES (?,?,?,?,?,?,?)";
		final PreparedStatement ps = con.prepareStatement(sql);
		int index = 0;
		ps.setLong(++index, steamid);
		ps.setString(++index, personaname);
		ps.setString(++index, profileurl);
		ps.setString(++index, avatar);
		ps.setString(++index, avatarmedium);
		ps.setString(++index, avatarfull);
		ps.setString(++index, realname);
		ps.executeUpdate();
		ps.close();
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("steamid", steamid);
		out.add("personaname", personaname);
		out.add("profileurl", profileurl);
		out.add("avatar", avatar);
		out.add("avatarmedium", avatarmedium);
		out.add("avatarfull", avatarfull);
		out.add("realname", realname);
		out.add("loccountrycode", loccountrycode);
		out.add("locstatecode", locstatecode);
		out.add("loccityid", loccityid);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {
		steamid = ((Number) object.get("steamid")).longValue();
		personaname = (String) object.get("personaname");
		profileurl = (String) object.get("profileurl");
		avatar = (String) object.get("avatar");
		avatarmedium = (String) object.get("avatarmedium");
		avatarfull = (String) object.get("avatarfull");
		realname = (String) object.get("realname");
		loccountrycode = (String) object.get("loccountrycode");
		locstatecode = (String) object.get("locstatecode");
		final Number n = (Number) object.get("loccityid");
		loccityid = n != null ? n.intValue() : 0;
	}

	public void fromSteamJson(Map<String, Object> object) {
		steamid = Long.parseLong((String) object.get("steamid"));
		personaname = (String) object.get("personaname");
		profileurl = (String) object.get("profileurl");
		avatar = (String) object.get("avatar");
		avatarmedium = (String) object.get("avatarmedium");
		avatarfull = (String) object.get("avatarfull");
		realname = (String) object.get("realname");
		loccountrycode = (String) object.get("loccountrycode");
		locstatecode = (String) object.get("locstatecode");
		final Number n = (Number) object.get("loccityid");
		loccityid = n != null ? n.intValue() : 0;
	}

}
