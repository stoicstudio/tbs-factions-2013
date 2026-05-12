package tbs.srv.util;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import org.apache.log4j.Logger;

import tbs.srv.chat.ChatRoom;
import tbs.srv.data.EntityDef;
import tbs.srv.data.LobbyData;
import tbs.srv.data.LobbyOptionsData;
import tbs.srv.data.LobbyPartyData;
import tbs.srv.data.LobbyUnitVariationData;
import tbs.srv.db.DbHelper;
import tbs.srv.db.models.UserData;

public class LobbySystem {

	private static final Logger logger = Logger.getLogger(LobbySystem.class.getSimpleName());

	public static String getChatRoomId(final long lobby_id) {
		return "lobby_" + lobby_id;
	}

	public static void invite(final GameConfig config, final LobbyOptionsData data) {
		// only 1 invite per room right now

		// / join your own lobby please

		doJoin(config, data.lobby_id, data.lobby_id);

		logger.info("invite " + data.lobby_id + " " + data.account_id);

		final List<Long> invites = getInvites(config, data.lobby_id);
		if (invites.size() > 0) {
			logger.warn("Could not " + data.lobby_id + " invite " + data.account_id + " more than " + invites.size());
			return;
		}

		final String account_display_name = addInvite(config, data.lobby_id, data.account_id, data.account_display_name);
		if (account_display_name == null) {
			logger.error("Unable to invite " + data.account_id + " due to missing name");
		}

		sendRabbit(config, data);

		// TODO for 2v2 we need to send all existing members not just the owner
		notifyParty(config, data.lobby_id, data.lobby_id, null, null);
	}

	public static void uninvite(final GameConfig config, final long lobby_id, final long account_id, final String account_display_name) {

		logger.info("uninvite " + lobby_id + " " + account_id);

		removeInvite(config, lobby_id, account_id, account_display_name);
		sendRabbit(config, new LobbyData(lobby_id, account_id, null, LobbyData.Type.UNINVITE));
	}

	public static void exit(final GameConfig config, final long lobby_id, final long account_id, final String account_display_name) {
		logger.info("exit " + lobby_id + " " + account_id);

		if (lobby_id == account_id) {
			// everybody out!
			sendRabbit(config, new LobbyData(lobby_id, 0, account_display_name, LobbyData.Type.TERMINATED));
			doFlushLobby(config, lobby_id);
			return;
		}

		removeInvite(config, lobby_id, account_id, account_display_name);
		doExit(config, lobby_id, account_id);
		sendRabbit(config, new LobbyData(lobby_id, account_id, account_display_name, LobbyData.Type.EXIT));
	}

	public static void join(final GameConfig config, final long lobby_id, final long account_id) {
		logger.info("join " + lobby_id + " " + account_id);

		doJoin(config, lobby_id, account_id);
		sendRabbit(config, new LobbyPartyData(lobby_id, account_id, null, LobbyData.Type.JOIN));

		// use current party
		notifyParty(config, lobby_id, account_id, null, null);
	}

	public static void decline(final GameConfig config, final long lobby_id, final long account_id, final String account_display_name) {

		logger.info("decline " + lobby_id + " " + account_id);

		removeInvite(config, lobby_id, account_id, account_display_name);
		sendRabbit(config, new LobbyData(lobby_id, account_id, null, LobbyData.Type.DECLINE));
	}

	public static void option(final GameConfig config, final LobbyOptionsData data) {

		logger.debug("option " + data);
		data.save(config.rdsDatasource);
		sendRabbit(config, data);
	}

	public static void ready(final GameConfig config, final long lobby_id, final long account_id) {

		logger.debug("ready " + lobby_id + " " + account_id);

		doReady(config, lobby_id, account_id, true);
		sendRabbit(config, new LobbyData(lobby_id, account_id, null, LobbyData.Type.READY));
	}

	public static void unready(final GameConfig config, final long lobby_id, final long account_id) {

		logger.debug("unready " + lobby_id + " " + account_id);

		doReady(config, lobby_id, account_id, false);
		sendRabbit(config, new LobbyData(lobby_id, account_id, null, LobbyData.Type.UNREADY));
	}

	public static void notifyParty(final GameConfig config, long lobby_id, final long account_id, EntityDef[] party, Object[] ids) {

		logger.debug("notifyParty " + lobby_id + " " + account_id);

		if (lobby_id == 0) {
			lobby_id = doGetLobbyId(config, account_id);
		}

		if (party == null) {
			party = getParty(config, account_id, ids);
		}
		sendRabbit(config, new LobbyPartyData(lobby_id, account_id, party, LobbyData.Type.PARTY));
	}

	public static void notifyVariation(long lobby_id, final long account_id, final String unit_id, final int variation) {
		logger.debug("notifyVariation " + lobby_id + " " + account_id);

		if (lobby_id == 0) {
			lobby_id = doGetLobbyId(GameConfig.instance, account_id);
		}

		sendRabbit(GameConfig.instance, new LobbyUnitVariationData(lobby_id, account_id, null, unit_id, variation));
	}

	public static void terminateSession(final GameConfig config, final long account_id, final String account_display_name) {
		logger.debug("terminateSession " + account_id);
		sendRabbit(config, new LobbyData(account_id, 0, null, LobbyData.Type.TERMINATED));
		doTerminateSession(config, account_id, account_display_name);
	}

	private static EntityDef[] getParty(final GameConfig config, final long account_id, Object[] ids) {

		UserData ud = null;
		try {
			ud = new UserData(config.rdsDatasource, config, account_id);
		} catch (SQLException e) {
			logger.error("getParty FAILED " + account_id + ": " + e);
			e.printStackTrace();
			return null;
		}

		if (ids == null) {
			ids = ud.party;
		}

		if (ids.length == 0) {
			logger.warn("Need more than 1 to enter battle");
		}

		EntityDef[] party = new EntityDef[ids.length];

		for (int i = 0; i < ids.length; ++i) {
			String pid = (String) ids[i];
			EntityDef def = ud.getRosterDef((String) pid);
			if (def == null) {
				throw new IllegalArgumentException("No such party member: " + pid);
			}

			party[i] = def;
		}

		return party;
	}

	private static void sendRabbit(final GameConfig config, final LobbyData msg) {

		// logger.info("-------sendRabbit " + msg);

		final List<Long> invites = getInvites(config, msg.lobby_id);

		final String lq = MsgSystem.getUserQueue(msg.lobby_id);
		GameConfig.instance.msg.send("", msg, MsgSystem.ZIP, lq);

		// logger.info("_______sendRabbit " + lq);

		for (Long l : invites) {
			final String uq = MsgSystem.getUserQueue(l);
			GameConfig.instance.msg.send("", msg, MsgSystem.ZIP, uq);
			// logger.info("_______sendRabbit " + uq);
		}

	}

	// //////////////////
	// db hooks
	// //////////////////

	private static boolean doReady(final GameConfig config, final long lobby_id, final long account_id, final boolean ready) {

		Connection con = null;
		PreparedStatement s = null;
		try {
			con = config.rdsDatasource.getConnection();
			final String sql = "UPDATE `account_info` SET `lobby_ready`=? WHERE `account_id`=? AND `lobby_id`=?";
			s = con.prepareStatement(sql);
			s.setBoolean(1, ready);
			s.setLong(2, account_id);
			s.setLong(3, lobby_id);
			s.executeUpdate();
			s.close();
			return true;
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return false;
	}

	private static boolean doJoin(final GameConfig config, final long lobby_id, final long account_id) {

		Connection con = null;
		PreparedStatement s = null;
		try {
			con = config.rdsDatasource.getConnection();
			final String sql = "UPDATE `account_info` SET `lobby_id`=? WHERE `account_id`=?";
			s = con.prepareStatement(sql);
			s.setLong(1, lobby_id);
			s.setLong(2, account_id);

			s.executeUpdate();
			s.close();
			return true;
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return false;
	}

	private static long doGetLobbyId(final GameConfig config, final long account_id) {

		long lobby_id = 0;
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = config.rdsDatasource.getConnection();
			final String sql = "SELECT `lobby_id` FROM `account_info` WHERE `account_id`=?";
			s = con.prepareStatement(sql);
			s.setLong(1, account_id);

			final ResultSet rs = s.executeQuery();
			if (rs.next()) {
				lobby_id = rs.getLong("lobby_id");
			}
			s.close();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return lobby_id;
	}

	private static boolean doExit(final GameConfig config, final long lobby_id, final long account_id) {

		Connection con = null;
		PreparedStatement s = null;
		try {
			con = config.rdsDatasource.getConnection();
			final String sql = "UPDATE `account_info` SET `lobby_id`=NULL WHERE `account_id`=? AND `lobby_id`=?";
			s = con.prepareStatement(sql);
			s.setLong(1, lobby_id);
			s.setLong(2, account_id);

			s.executeUpdate();
			s.close();
			return true;
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return false;
	}

	private static void doFlushLobby(final GameConfig config, final long lobby_id) {

		List<Long> invites = new ArrayList<Long>();

		// ///

		Connection con = null;
		PreparedStatement s = null;
		try {

			con = config.rdsDatasource.getConnection();

			s = con.prepareStatement("SELECT `invite_id` FROM `lobby_invite` WHERE `lobby_id`=?");
			s.setLong(1, lobby_id);
			final ResultSet rs = s.executeQuery();
			while (rs.next()) {
				invites.add(rs.getLong("invite_id"));
			}

			s = con.prepareStatement("UPDATE `account_info` SET `lobby_id`=NULL, `lobby_ready`=0 WHERE `lobby_id`=?");
			s.setLong(1, lobby_id);
			s.executeUpdate();
			s.close();

			s = con.prepareStatement("DELETE FROM `lobby_invite` WHERE `lobby_id`=?");
			s.setLong(1, lobby_id);
			s.executeUpdate();
			s.close();

			s.close();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		final ChatRoom chatRoom = config.chat.getRoom(getChatRoomId(lobby_id), true);
		for (Long ll : invites) {
			chatRoom.removeMember(ll, null);
		}

	}

	private static boolean doTerminateSession(final GameConfig config, final long account_id, final String account_display_name) {

		final String chatroomId = LobbySystem.getChatRoomId(account_id);
		final ChatRoom room = GameConfig.instance.chat.getAuthoritativeRoom(chatroomId);

		if (room != null) {
			room.removeMember(account_id, account_display_name);
			try {
				room.destroy();
			} catch (IOException e) {
				logger.warn("doTerminateSession " + account_id + "/" + account_display_name + ": " + e);
			}
		}

		List<Long> lobbies = new ArrayList<Long>();

		Connection con = null;
		PreparedStatement s = null;
		try {
			con = config.rdsDatasource.getConnection();
			s = con.prepareStatement("UPDATE `account_info` SET `lobby_id`=NULL, `lobby_ready`=0 WHERE `lobby_id`=?");
			s.setLong(1, account_id);
			s.executeUpdate();
			s.close();

			s = con.prepareStatement("DELETE FROM `lobby_invite` WHERE `lobby_id`=?");
			s.setLong(1, account_id);
			s.executeUpdate();
			s.close();

			s = con.prepareStatement("DELETE FROM `lobby` WHERE `lobby_id`=?");
			s.setLong(1, account_id);
			s.executeUpdate();
			s.close();

			s = con.prepareStatement("SELECT `lobby_id` FROM `lobby_invite` WHERE `invite_id`=?");
			s.setLong(1, account_id);
			final ResultSet rs = s.executeQuery();
			while (rs.next()) {
				lobbies.add(rs.getLong("lobby_id"));
			}
			s.close();
		} catch (SQLException e) {
			e.printStackTrace();
			return false;
		} finally {
			DbHelper.cleanup(con, s);
		}

		for (Long ll : lobbies) {
			exit(config, ll, account_id, account_display_name);
		}

		return true;
	}

	private static boolean removeInvite(final GameConfig config, final long lobby_id, final long account_id, final String display_name) {

		config.chat.getRoom(getChatRoomId(lobby_id), false).removeMember(account_id, display_name);
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = config.rdsDatasource.getConnection();
			final String sql = "DELETE FROM `lobby_invite` WHERE `lobby_id`=? AND  `invite_id`=?";
			s = con.prepareStatement(sql);
			s.setLong(1, lobby_id);
			s.setLong(2, account_id);

			s.executeUpdate();
			s.close();
			return true;
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return false;
	}

	private static String addInvite(final GameConfig config, final long lobby_id, final long account_id, final String display_name) {

		config.chat.getRoom(getChatRoomId(lobby_id), false).addMember(account_id, display_name);
		Connection con = null;
		PreparedStatement s = null;
		String account_display_name = null;
		try {
			con = config.rdsDatasource.getConnection();

			s = con.prepareStatement("SELECT `display_name` from `auth_account` WHERE `account_id`=?");
			s.setLong(1, account_id);
			final ResultSet rs = s.executeQuery();
			if (!rs.next()) {
				return null;
			}
			account_display_name = rs.getString("display_name");
			s.close();

			final String sql = "REPLACE INTO `lobby_invite` (`lobby_id`, `invite_id`, `invite_time`) VALUES (?,?,?)";
			s = con.prepareStatement(sql);
			s.setLong(1, lobby_id);
			s.setLong(2, account_id);
			s.setLong(3, System.currentTimeMillis());
			s.executeUpdate();

			s.close();

			return account_display_name;
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return null;
	}

	private static List<Long> getInvites(final GameConfig config, final long lobby_id) {
		final ArrayList<Long> results = new ArrayList<Long>();
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = config.rdsDatasource.getConnection();
			final String sql = "SELECT * FROM `lobby_invite` WHERE `lobby_id` = ?";
			s = con.prepareStatement(sql);
			s.setLong(1, lobby_id);
			final ResultSet rs = s.executeQuery();

			while (rs.next()) {
				final long invite = rs.getLong("invite_id");
				results.add(invite);
			}
			s.close();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return results;
	}

}
