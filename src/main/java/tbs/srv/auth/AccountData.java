package tbs.srv.auth;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;

import javax.sql.DataSource;

import org.apache.log4j.Logger;

import tbs.srv.db.DbHelper;
import tbs.srv.util.GameConfig;

import com.newrelic.api.agent.Trace;

public class AccountData {

	public static Logger logger = Logger.getLogger(AccountData.class.getSimpleName());

	public long account_id;
	public long steam_id;
	public long vbb_id;
	public long create_date;
	public String vbb_name;
	public long parent_id;
	public int child_number;
	public boolean enabled = true;
	public String display_name;
	public boolean start;
	public boolean superuser;

	public AccountData(long account_id, final String display_name, long steam_id, long vbb_id, long create_date, String vbb_name, long parent_id,
			int child_number, boolean superuser) {
		super();
		this.account_id = account_id;
		this.display_name = display_name;
		this.steam_id = steam_id;
		this.vbb_id = vbb_id;
		this.create_date = create_date;
		this.vbb_name = vbb_name;
		this.parent_id = parent_id;
		this.child_number = child_number;
		this.superuser = superuser;
	}

	public String toString() {
		return "[" + account_id + "/" + steam_id + "/" + vbb_id + "/" + vbb_name + "/" + display_name + "]";
	}

	public AccountData(ResultSet rs) throws SQLException {
		this(//
				rs.getLong("account_id"), //
				rs.getString("display_name"), //
				rs.getLong("steam_id"), //
				rs.getLong("vbb_id"), //
				rs.getTimestamp("create_date").getTime(), //
				rs.getString("vbb_name"), //
				rs.getLong("parent_id"), //
				rs.getInt("child_number"), //
				rs.getBoolean("superuser"));

		enabled = rs.getBoolean("enabled");
	}

	public boolean canChildAccount() {
		return superuser;
	}

	public boolean isAdmin() {
		return superuser;
	}

	@Trace
	public boolean create(DataSource ds) {

		if (account_id != 0) {
			throw new IllegalAccessError("Don't create twice");
		}

		start = true;

		Connection con = null;
		PreparedStatement s = null;
		try {

			con = ds.getConnection();

			{
				create_date = System.currentTimeMillis();

				final String sql = //
				"INSERT INTO auth_account " + //
						"(steam_id,display_name,vbb_id,create_date,vbb_name,parent_id,child_number) " + //
						"VALUES " + //
						"(?,?,?,?,?,?,?)";

				s = con.prepareStatement(sql);
				int index = 0;
				s.setLong(++index, steam_id);
				s.setString(++index, display_name);
				s.setLong(++index, vbb_id);
				// TODO make this unixtime
				s.setTimestamp(++index, new Timestamp(create_date));
				s.setString(++index, vbb_name);
				s.setLong(++index, parent_id);
				s.setInt(++index, child_number);

				s.executeUpdate();
				s.close();
			}

			s = con.prepareStatement("SELECT LAST_INSERT_ID()");
			ResultSet rs = s.executeQuery();
			rs.beforeFirst();

			if (rs.next()) {
				account_id = rs.getLong(1);
				return true;
			} else {
				throw new IllegalAccessError("Did not update account id");
			}

		} catch (SQLException e) {
			logger.error("create: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return false;
	}

	@Trace
	public void updateDisplayName(final DataSource ds, final String displayName) {

		if (display_name != null && display_name.equals(displayName) && displayName != null) {
			return;
		}

		logger.info("AccountData.updateDisplayName " + this + " changing to " + displayName);
		display_name = displayName;

		Connection con = null;
		PreparedStatement ps = null;
		try {

			con = ds.getConnection();
			final String sql = "UPDATE auth_account SET display_name=? WHERE account_id=?;";
			ps = con.prepareStatement(sql);
			ps.setString(1, display_name);
			ps.setLong(2, account_id);
			ps.executeUpdate();

		} catch (SQLException e) {
			logger.error("updateDisplayName: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

	public AccountData getChild(DataSource ds, int theChild) {
		return get(ds, "parent_id = " + account_id + " AND child_number = " + theChild);
	}

	@Trace
	public static AccountData getSteam(DataSource ds, long steam_id) {
		return get(ds, "steam_id", steam_id);
	}

	public static AccountData getVbb(DataSource ds, long vbb_id) {
		return get(ds, "vbb_id", vbb_id);
	}

	public static AccountData getAccount(DataSource ds, long account_id) {
		return get(ds, "account_id", account_id);
	}

	private static AccountData get(DataSource ds, String index, Object value) {
		return get(ds, index + " = '" + value + "'");
	}

	private static AccountData get(Statement s, String query) {

		try {

			s.execute(query);
			ResultSet rs = s.getResultSet();
			rs.beforeFirst();

			if (rs.next()) {
				return new AccountData(rs);
			}

		} catch (SQLException e) {
			logger.error("get statement: " + e);
			e.printStackTrace();
		}
		return null;
	}

	private static AccountData get(DataSource ds, String where) {
		Connection con = null;
		Statement s = null;
		try {

			con = ds.getConnection();
			s = con.createStatement();
			return get(s, "SELECT * FROM auth_account WHERE " + where);

		} catch (SQLException e) {
			logger.error("get where: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return null;
	}

	public static String getDisplayName(final long account_id) {
		Connection con = null;
		PreparedStatement s = null;
		try {

			con = GameConfig.instance.rdsDatasource.getConnection();
			s = con.prepareStatement("SELECT display_name from auth_account WHERE account_id=?");
			s.setLong(1, account_id);
			final ResultSet rs = s.executeQuery();
			if (rs.next()) {
				return rs.getString("display_name");
			}

		} catch (SQLException e) {
			logger.error("getDisplayName: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return null;
	}

	public static long getSteamId(final long account_id) {
		Connection con = null;
		PreparedStatement s = null;
		try {

			con = GameConfig.instance.rdsDatasource.getConnection();
			s = con.prepareStatement("SELECT steam_id from auth_account WHERE account_id=?");
			s.setLong(1, account_id);
			final ResultSet rs = s.executeQuery();
			if (rs.next()) {
				return rs.getLong(1);
			}

		} catch (SQLException e) {
			logger.error("getSteamId: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return 0;
	}
}
