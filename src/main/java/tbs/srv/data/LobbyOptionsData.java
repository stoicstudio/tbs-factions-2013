package tbs.srv.data;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Map;

import javax.sql.DataSource;

import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.db.DbHelper;

public class LobbyOptionsData extends LobbyData {

	public String display_name;
	public String scene;
	public int timer;
	public String msg;

	public LobbyOptionsData() {
		super.type = Type.OPTIONS.name();
	}

	public LobbyOptionsData(final Connection con, final long lobby_id) throws SQLException {
		PreparedStatement s = con.prepareStatement("SELECT * from `lobby` WHERE `lobby_id` = ?");
		s.setLong(1, lobby_id);

		final ResultSet rs = s.executeQuery();

		if (rs.next()) {
			this.display_name = rs.getString("display_name");
			this.scene = rs.getString("scene");
			this.timer = rs.getInt("timer");
		}
		s.close();
	}

	public String toString() {
		return super.toString();
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);
		out.add("display_name", display_name);
		out.add("scene", scene);
		out.add("timer", timer);
		out.add("msg", msg);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		super.fromJSON(jo);
		display_name = (String) jo.get("display_name");
		scene = (String) jo.get("scene");
		timer = ((Number) jo.get("timer")).intValue();
		msg = (String) jo.get("msg");
	}

	public void save(final DataSource ds) {
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = ds.getConnection();
			final String sql = "REPLACE INTO `lobby` (`lobby_id`,`display_name`,`scene`,`timer`) VALUES (?,?,?,?)";
			s = con.prepareStatement(sql);
			s.setLong(1, lobby_id);
			s.setString(2, display_name);
			s.setString(3, scene);
			s.setInt(4, timer);

			s.executeUpdate();
			s.close();

		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

	}
}