package tbs.srv.db.models;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashSet;

import javax.sql.DataSource;

import net.sf.ehcache.Element;
import tbs.srv.db.DbHelper;
import tbs.srv.web.WebConfig;

public class AuthDataVbb {
	public static class Attr {
	};

	public String username;
	public String passwordHash;
	public String passwordSalt = "";
	public long id;
	public long userGroupId;
	public HashSet<Long> memberGroupIds = new HashSet<Long>();

	public AuthDataVbb() {

	}

	public boolean hasGroup(long gid) {
		return userGroupId == gid || memberGroupIds.contains(Long.valueOf(gid));
	}

	public boolean hasGroup(long[] gids) {
		for (long gid : gids) {
			if (hasGroup(gid)) {
				return true;
			}
		}

		return false;

	}

	public static AuthDataVbb get(String username, boolean remove) {
		if (remove) {
			WebConfig.instance.authVbbCache.remove(username);
		}

		if (WebConfig.instance.authVbbCache != null) {
			Element e = WebConfig.instance.authVbbCache.get(username);
			return (e != null) ? (AuthDataVbb) e.getObjectValue() : null;
		}

		return null;
	}

	public AuthDataVbb(DataSource ds, String username) {

		this.username = username;

		Connection con = null;
		Statement s = null;
		try {

			con = ds.getConnection();

			s = con.createStatement();
			s.execute("SELECT * FROM vbbuser WHERE username = '" + username + "'");
			ResultSet rs = s.getResultSet();

			rs.beforeFirst();

			if (rs.next()) {
				this.passwordHash = rs.getString("password");
				this.passwordSalt = rs.getString("salt");
				this.id = rs.getInt("userid");
				String mgis = rs.getString("membergroupids");
				if (mgis.length() > 0) {
					String[] mgiv = mgis.split(",");
					for (String mgi : mgiv) {
						Long l = Long.parseLong(mgi);
						this.memberGroupIds.add(l);
					}
				}
				this.userGroupId = rs.getInt("usergroupid");
			}

		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	public boolean validatePassword(String plaintext) {
		if (passwordSalt == null || plaintext == null) {
			return false;
		}

		String p0 = MD5(plaintext);
		String p1 = p0 + passwordSalt;
		String p2 = MD5(p1);

		return this.passwordHash != null && this.passwordHash.equals(p2);
	}

	/**
	 * http://m2tec.be/blog/2010/02/03/java-md5-hex-0093
	 * 
	 * @author Tom Vervoort
	 * @param md5
	 * @return
	 */
	public static String MD5(String md5) {
		try {
			java.security.MessageDigest md = java.security.MessageDigest.getInstance("MD5");
			byte[] array = md.digest(md5.getBytes());
			StringBuffer sb = new StringBuffer();
			for (int i = 0; i < array.length; ++i) {
				sb.append(Integer.toHexString((array[i] & 0xFF) | 0x100).substring(1, 3));
			}
			return sb.toString();
		} catch (java.security.NoSuchAlgorithmException e) {
			e.printStackTrace();
		}
		return null;
	}

	public static long MD5_sum(String md5) {
		try {
			java.security.MessageDigest md = java.security.MessageDigest.getInstance("MD5");
			byte[] array = md.digest(md5.getBytes());
			long sum = 0;
			for (int i = 0; i < array.length; ++i) {
				sum += 128 + array[i];
			}
			return sum;
		} catch (java.security.NoSuchAlgorithmException e) {
			e.printStackTrace();
		}
		return 0;
	}
}
