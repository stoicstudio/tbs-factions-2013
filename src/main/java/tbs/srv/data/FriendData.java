package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.util.steam.SteamPlayerSummary;

public class FriendData implements Convertible {

	public long id;
	public String display_name;
	public String location;
	public Boolean online;
	public long steam_id;
	public String steam_id_str;
	public String avatar128;
	public String avatar64;
	public String avatar32;
	public int wins;
	public int losses;
	public long last_battle_time;

	public FriendData() {

	}

	public FriendData(SteamPlayerSummary sps) {
		display_name = sps.personaname;
		steam_id = sps.steamid;
		steam_id_str = Long.toString(steam_id);
		avatar32 = sps.avatar;
		avatar64 = sps.avatarmedium;
		avatar128 = sps.avatarfull;
	}

	// public FriendData(ResultSet rs) throws SQLException {
	// id = rs.getLong("id");
	// display_name = rs.getString("display_name");
	// location = rs.getString("location");
	// online = rs.getBoolean("online");
	// steam_id = rs.getLong("steam_id");
	// avatar128 = rs.getString("avatar_128");
	// avatar64 = rs.getString("avatar_64");
	// avatar32 = rs.getString("avatar_32");
	// }

	public String toString() {
		return super.toString();
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("id", id);
		out.add("display_name", display_name);
		out.add("location", location);
		out.add("online", online);
		out.add("steam_id", steam_id);
		out.add("steam_id_str", steam_id_str);
		out.add("avatar128", avatar128);
		out.add("avatar64", avatar64);
		out.add("avatar32", avatar32);
		out.add("wins", wins);
		out.add("losses", losses);
		out.add("last_battle_time", last_battle_time);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		id = ((Number) jo.get("id")).longValue();
		display_name = (String) jo.get("display_name");
		location = (String) jo.get("location");
		online = (Boolean) jo.get("online");
		steam_id = ((Number) jo.get("steam_id")).longValue();
		steam_id_str = (String) jo.get("steam_id_str");
		avatar128 = (String) jo.get("avatar128");
		avatar64 = (String) jo.get("avatar64");
		avatar32 = (String) jo.get("avatar32");
		wins = ((Number) jo.get("wins")).intValue();
		losses = ((Number) jo.get("losses")).intValue();
		last_battle_time = ((Number) jo.get("last_battle_time")).intValue();
	}
}