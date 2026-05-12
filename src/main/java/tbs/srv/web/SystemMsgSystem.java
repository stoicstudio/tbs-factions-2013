package tbs.srv.web;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.apache.log4j.Logger;

import tbs.srv.db.DbHelper;
import tbs.srv.util.GameConfig;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.SystemMsg;

public class SystemMsgSystem {

	public static final String KEY = "key_system_msg";

	public static final Logger logger = Logger.getLogger(SystemMsgSystem.class);
	private String _systemMessage;
	private GameConfig config;

	public SystemMsgSystem(GameConfig config) {
		this.config = config;
		loadSystemMessage(config);
	}

	private void saveSystemMessage(final GameConfig config, final String msg) {
		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = config.rdsDatasource.getConnection();
			ps = con.prepareStatement("INSERT INTO system_msg (system_msg_time, system_msg_text) VALUES (?,?)");
			ps.setLong(1, System.currentTimeMillis());
			ps.setString(2, msg);
			ps.executeUpdate();

		} catch (SQLException e) {
			logger.error("saveSystemMessage :" + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}

	}

	private void loadSystemMessage(final GameConfig config) {
		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = config.rdsDatasource.getConnection();

			ps = con.prepareStatement("SELECT system_msg_text FROM system_msg ORDER BY system_msg_key DESC LIMIT 1");
			final ResultSet rs = ps.executeQuery();

			if (rs.next()) {
				setSystemMessage(rs.getString("system_msg_text"), false);
			}

		} catch (SQLException e) {
			logger.error("loadSystemMessage :" + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}

	}

	public String getSystemMessage() {
		return _systemMessage;
	}

	public void setSystemMessage(final String s, final boolean broadcast) {
		if (_systemMessage != null && s != null && _systemMessage.equals(s)) {
			return;
		}

		if (_systemMessage == null && s == null) {
			return;
		}

		_systemMessage = s;

		logger.info("setSystemMessage " + s);

		if (broadcast) {
			final SystemMsg msg = new SystemMsg(s);
			config.msg.send("amq.fanout", msg, MsgSystem.ZIP, KEY);
			save();
		}
	}
	
	public void save()
	{
		saveSystemMessage(GameConfig.instance, _systemMessage);
	}
}
