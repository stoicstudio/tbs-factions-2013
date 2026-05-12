package tbs.srv.battle;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON;

import tbs.srv.battle.data.BattleCreateData;
import tbs.srv.battle.data.BattlePartyData;
import tbs.srv.battle.data.BattleQueryData;
import tbs.srv.battle.data.base.BaseBattleData;
import tbs.srv.battle.data.client.BattleAbortData;
import tbs.srv.chat.ChatRoom;
import tbs.srv.chat.ChatSystem;
import tbs.srv.db.DbHelper;
import tbs.srv.util.BattleSceneListItemDef;
import tbs.srv.util.GameConfig;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.RabbitConfig;
import tbs.srv.util.VsType;

import com.newrelic.api.agent.NewRelic;
import com.rabbitmq.client.AlreadyClosedException;
import com.rabbitmq.client.Channel;

public class BattleSystem {

	static final Logger logger = Logger.getLogger(BattleSystem.class.getSimpleName());

	public static final boolean ZIP = true;

	public static final String KEY_USER_ABORT_ALL_ = "KEY_USER_ABORT_ALL_";

	private boolean authoritative;

	private GameConfig config;

	public static final String EXCHANGE = "battle";

	public BattleSystem(GameConfig _config, boolean authoritative) throws IOException {

		this.config = _config;
		this.authoritative = authoritative;
		final Channel channel = _config.rabbit.createChannel(this);
		channel.exchangeDeclare(EXCHANGE, "direct");
		channel.close();

		if (authoritative) {
			if (config.GAME_REBOOTING) {
				purgeBattleFreezer();
			} else {
				thawBattleFreezer();
			}
		}
	}

	private void purgeBattleFreezer() {
		Connection con = null;
		PreparedStatement ps = null;
		try {

			logger.info("purgeBattleFreezer...");
			con = config.rdsDatasource.getConnection();
			{
				ps = con.prepareStatement("UPDATE battle SET end_time=?, aborted=1 where end_time IS NULL");
				ps.setLong(1, System.currentTimeMillis());
				final int count = ps.executeUpdate();
				logger.info("purgeBattleFreeze PURGED " + count);
				ps.close();
			}

			for (String t : BattleMonitor.cleanup_tables) {
				ps = con.prepareStatement("TRUNCATE TABLE " + t);
				ps.executeUpdate();
				ps.close();
			}
			
			{
				ps = con.prepareStatement("UPDATE battle SET battle_create_data=NULL");
				ps.executeUpdate();
				ps.close();
			}
		} catch (SQLException e) {
			logger.error("purgeBattleFreezer: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}

	}

	private void thawBattleFreezer() {

		Map<String, String> thaws = new HashMap<String, String>();

		Connection con = null;
		PreparedStatement ps = null;
		try {

			logger.info("thawBattleFreezer...");
			con = config.rdsDatasource.getConnection();
			{
				ps = con.prepareStatement("SELECT battle_id, battle_create_data FROM battle WHERE end_time IS NULL");
				final ResultSet rs = ps.executeQuery();

				while (rs.next()) {
					final String battle_id = rs.getString("battle_id");
					final String bcd_str = rs.getString("battle_create_data");

					logger.info("thawBattleFreezer depersisting " + battle_id);
					thaws.put(battle_id, bcd_str);
				}

				ps.close();
			}

		} catch (SQLException e) {
			logger.error("thawBattleFreezer: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}

		for (String battle_id : thaws.keySet()) {
			final String bcd_str = thaws.get(battle_id);
			try {
				final BattleCreateData bcd = (BattleCreateData) JSON.parse(bcd_str);
				logger.info("thawBattleFreezer recreating " + bcd.battleId);
				initializeBattle(bcd, false);
			} catch (Exception e) {
				logger.error("thawBattleFreezer FAILED " + battle_id + ": " + e);
				e.printStackTrace();
			}
		}
	}

	public static String generateBattleId(BattlePartyData... parties) {
		StringBuilder sb = new StringBuilder();
		// generate a new id for this
		final long cur = (new Date()).getTime();
		sb.append(Long.toString(cur, 16));
		for (BattlePartyData party : parties) {
			sb.append(":");
			sb.append(Long.toString(party.user, 16));
		}

		return sb.toString();
	}

	public BattleCreateData createBattle(MsgSystem msgSystem, String scene, final boolean friendly, final int tourney_id, BattlePartyData... parties)
			throws Exception {

		if (!authoritative) {
			throw new IllegalAccessError("Not authoritative");
		}

		String id = generateBattleId(parties);

		if (scene == null) {

			final BattleSceneListItemDef item = config.battle_scene_list.getRandom();
			scene = item.id;
		}

		final BattleCreateData bd = new BattleCreateData(id, scene, friendly, tourney_id, parties);

		initializeBattle(bd, true);

		msgSystem.send(EXCHANGE, bd, ZIP, bd.battleId);

		return bd;
	}

	private void initializeBattle(final BattleCreateData bd, final boolean save) throws Exception {
		// create the chat room
		final ChatRoom room = config.chat.getAuthoritativeRoom(bd.battleId);

		final Channel c = config.rabbit.createTemporaryChannel(this, RabbitConfig.Consume.NO);

		for (int i = 0; i < bd.parties.length; ++i) {
			final BattlePartyData party = bd.getPartyByIndex(i);
			party.setupCharacterClasses();
			bindUserToBattle(c, party.user, bd);
			room.addMember(party.user, party.display_name);
		}

		c.close();
		new BattleMonitor(bd, config, room, save);
	}

	private static void bindUserToBattle(final Channel channel, final long user, final BattleCreateData bcd) throws Exception {

		final String q = MsgSystem.getUserQueue(user);

		MsgSystem.declareUserQueue(channel, q, false);

		// bind the user to the battle's stuffs by user
		for (Object po : bcd.parties) {
			BattlePartyData other = (BattlePartyData) po;

			if (other.user != user) {
				final String key = getUserBattleKey(bcd.battleId, other.user);
				channel.queueBind(q, EXCHANGE, key);
			}
		}

		channel.queueBind(q, EXCHANGE, bcd.battleId, null);
	}

	public static String getUserBattleKey(final String battle_id, final long account_id) {
		if (battle_id == null || battle_id.isEmpty()) {
			throw new IllegalArgumentException("invalid battle_id for account " + account_id);
		}
		if (account_id == 0) {
			throw new IllegalArgumentException("invalid account_id");
		}

		return "key_b_" + battle_id + "_" + account_id;
	}

	public static void unbindUserFromBattle(ChatSystem chat, final long user, final String display_name, final BattleCreateData bcd) {

		try {
			final String q = MsgSystem.getUserQueue(user);
			for (Object po : bcd.parties) {
				BattlePartyData other = (BattlePartyData) po;
				if (other.user != user) {
					final String key = getUserBattleKey(bcd.battleId, other.user);
					logger.debug(bcd.battleId + " unbinding user " + user + " from " + other.user + " key=" + key);
					// stop listening to the other users via the battle exchange
					try {
						final Channel channel = GameConfig.instance.rabbit.createTemporaryChannel("unbindUserFromBattle_" + user, RabbitConfig.Consume.NO);
						channel.queueUnbind(q, BattleSystem.EXCHANGE, key);
						channel.close();
					} catch (Exception e) {
						logger.warn("unbindUserFromBattle failed to unbind user q " + q + " from " + key);
					}
				}
			}

			try {
				final Channel channel = GameConfig.instance.rabbit.createTemporaryChannel("unbindUserFromBattle_" + user, RabbitConfig.Consume.NO);
				channel.queueUnbind(q, BattleSystem.EXCHANGE, bcd.battleId);
				channel.close();
			} catch (Exception e) {
				logger.warn("unbindUserFromBattle failed to unbind user q " + q + " from " + bcd.battleId);
			}

			final ChatRoom room = chat.getAuthoritativeRoom(bcd.battleId);
			room.removeMember(user, display_name);
		} catch (AlreadyClosedException exp) {
			logger.error("unbindUserFromBattle failed generally for " + user + "/" + display_name + ": " + exp);
		}
	}

	public static boolean send(BaseBattleData msg) {
		// TODO the battle worker should watch for users sending invalid messages to battles not their own and kick them

		logger.debug("BATTLE SEND " + msg);

		if (msg instanceof BattleQueryData) {
			return GameConfig.instance.msg.send("", msg, ZIP, BattleMonitor.getMonitorQueue(msg.battleId));
		}

		if (msg instanceof BattleAbortData) {
			if (msg.battleId == null || msg.battleId.isEmpty()) {
				return GameConfig.instance.msg.send(EXCHANGE, msg, ZIP, KEY_USER_ABORT_ALL_ + msg.user);
			}
		}

		final String key = getUserBattleKey(msg.battleId, msg.user);
		return GameConfig.instance.msg.send(EXCHANGE, msg, ZIP, key);
	}

	public static void recordBattleConcurrency() {
		HashMap<VsType, Integer> r = getBattleConcurrency();
		int total = 0;
		
		for (int i = 0; i < VsType.values().length; ++i)
		{
			VsType t = VsType.values()[i];
			int n  = 0;
			if (r.containsKey(t))
			{
				n = r.get(t);
			}
			
			total += n;
			NewRelic.recordMetric("Custom/battle/count/type/" + t.name(), n);			
		}
		NewRelic.recordMetric("Custom/battle/count/total", total);
	}

	public static HashMap<VsType, Integer> getBattleConcurrency() {
		Statement s = null;
		Connection con = null;
		
		HashMap<VsType, Integer> r = new HashMap<VsType, Integer>();
		try {
			con = GameConfig.instance.rdsDatasource.getConnection();

			{
				s = con.createStatement();
				final ResultSet rs = s.executeQuery("select battle_party.vs_type, count(distinct battle.battle_id) num from battle join battle_party using (battle_id) where battle.end_time IS NULL group by battle_party.vs_type");

				while (rs.next()) {
					int ti = rs.getInt(1);
					int n = rs.getInt(2);
					VsType t = VsType.values()[ti];
					r.put(t, n);				
				}
				s.close();
			}
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
		return r;
	}

}
