package tbs.srv.battle;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON;

import tbs.srv.battle.data.BattleCreateData;
import tbs.srv.battle.data.BattlePartyData;
import tbs.srv.battle.data.BattleQueryData;
import tbs.srv.battle.data.base.BaseBattleData;
import tbs.srv.battle.data.client.BattleAbortData;
import tbs.srv.battle.data.client.BattleAbortedData;
import tbs.srv.battle.data.client.BattleActionData;
import tbs.srv.battle.data.client.BattleExitData;
import tbs.srv.battle.data.client.BattleFinishedData;
import tbs.srv.battle.data.client.BattleKilledData;
import tbs.srv.battle.data.client.BattleMoveData;
import tbs.srv.battle.data.client.BattleReadyData;
import tbs.srv.battle.data.client.BattleRenownAwardType;
import tbs.srv.battle.data.client.BattleRewardData;
import tbs.srv.battle.data.client.BattleSurrenderData;
import tbs.srv.battle.data.client.BattleSyncData;
import tbs.srv.chat.ChatRoom;
import tbs.srv.chat.ChatSystem;
import tbs.srv.data.EntityDef;
import tbs.srv.data.StatType;
import tbs.srv.db.DbHelper;
import tbs.srv.db.models.SessionData;
import tbs.srv.db.models.UserData;
import tbs.srv.util.AchievementListItemDef;
import tbs.srv.util.AchievementProgressData;
import tbs.srv.util.AchievementSystem;
import tbs.srv.util.AchievementType;
import tbs.srv.util.GameConfig;
import tbs.srv.util.LeaderboardDirtyData;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.RabbitConfig;
import tbs.srv.util.RenownReason;
import tbs.srv.util.Tourney;
import tbs.srv.util.steam.Steam;

import com.newrelic.api.agent.NewRelic;
import com.newrelic.api.agent.Trace;
import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.AMQP.Queue.UnbindOk;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;
import com.rabbitmq.client.ShutdownSignalException;

public class BattleMonitor {

	public final Logger logger;

	// starting and core data
	private BattleCreateData battleCreateData;
	private GameConfig config;
	private String monitorQueue;
	private Channel consumerChannel;
	private BattleConsumer battleConsumer;
	private ChatRoom chatroom;

	// dynamic data
	private BattleFinishedData finished;

	final private HashMap<Long, PartiesKills> kills;
	private int totalKills = 0;

	private HashSet<Long> readies = new HashSet<Long>();
	private HashSet<Long> aborts = new HashSet<Long>();
	private HashSet<Long> surrenders = new HashSet<Long>();
	private HashSet<Long> exits = new HashSet<Long>();
	private HashSet<Long> disconnects = new HashSet<Long>();

	private HashSet<String> waitingAchievementProgressHandles = new HashSet<String>();
	// private ArrayList<String> achievements = new ArrayList<String>();
	private HashMap<Long, ArrayList<String>> achievements = new HashMap<Long, ArrayList<String>>();
	private BattleFinishedData finishing;
	private int achievementProgressHandleIncValue = 0;

	private int numTurns;
	private int numTurnsComplete;
	public boolean diverged;
	public int divergenceTurn;

	private boolean readyForCleanup;
	private boolean cleanedup;
	private boolean aborted;

	// public static final String KEY_ = "monitor_";

	private HashMap<Integer, PartiesSync> turnSyncs = new HashMap<Integer, PartiesSync>();

	private final RabbitConfig rabbit;

	public String toString() {
		return "BattleMonitor_" + battleCreateData.battleId;
	}

	private class PartiesKills {
		public HashMap<String, Integer> reports = new HashMap<String, Integer>();
		public final int MASK;
		public final long partyId;

		public PartiesKills(final long partyId) {
			this.partyId = partyId;
			int bitmask = 0;
			for (int i = 0; i < battleCreateData.parties.length; ++i) {
				bitmask |= (1 << i);
			}
			MASK = bitmask;
		}

		public boolean reportKill(final BattleKilledData msg) {
			if (partyId != msg.killedparty) {
				throw new IllegalArgumentException("bad party");
			}
			final BattlePartyData p = battleCreateData.getPartyById(msg.user);

			int bits = 0;

			if (reports.containsKey(msg.entity)) {
				bits = reports.get(msg.entity);

				// TODO check killer info

				if (bits == MASK) {
					logger.warn("Kill redundancy of " + msg.entity + " by " + msg.killer);
					return true;
				}
			}

			bits |= (1 << p.party_index);
			reports.put(msg.entity, bits);

			if (bits == MASK) {
				logger.info("Kill complete of " + msg.entity + " by " + msg.killer);
				return true;
			}

			return false;
		}

		public boolean isKilled(final String entityId) {
			final Integer i = reports.get(entityId);
			if (i != null) {
				return i == MASK;
			}

			return false;
		}

		public int getKillCount() {

			int k = 0;

			for (Integer bits : reports.values()) {
				if (bits != null && bits.intValue() == MASK) {
					++k;
				}
			}

			return k;
		}

		public boolean isKilled(final BattleKilledData msg) {
			if (partyId != msg.killedparty) {
				throw new IllegalArgumentException("bad party");
			}
			final Integer i = reports.get(msg.entity);
			if (i != null) {
				return i == MASK;
			}

			return false;
		}
	}

	private class PartiesSync {
		public HashMap<Long, Long> partyHashes = new HashMap<Long, Long>();
		public boolean complete;
		public boolean divergence;
		public long hash = 0;
		public int turn;

		private void save() {
			Connection con = null;
			PreparedStatement ps = null;
			try {

				final Map<String, Object> syncsm = new HashMap<String, Object>();
				for (Long key : partyHashes.keySet()) {
					syncsm.put(key.toString(), partyHashes.get(key));
				}

				final String parties_str = JSON.toString(syncsm);

				con = config.rdsDatasource.getConnection();

				{
					ps = con.prepareStatement("REPLACE INTO battle_sync (battle_id, turn, complete, divergence, hash, party_syncs) VALUES (?,?,?,?,?,?)");

					int index = 0;

					ps.setString(++index, battleCreateData.battleId);
					ps.setInt(++index, turn);
					ps.setBoolean(++index, complete);
					ps.setBoolean(++index, divergence);
					ps.setLong(++index, hash);
					ps.setString(++index, parties_str);
					ps.executeUpdate();
					ps.close();
				}

			} catch (SQLException e) {
				logger.error("PartiesSync.save: " + e);
				e.printStackTrace();
			} finally {
				DbHelper.cleanup(con, ps);
			}

		}

		public PartiesSync(final int turn) {
			this.turn = turn;
		}

		public void addSync(BattleSyncData sync) {

			final Long old = partyHashes.get(sync.user);

			if (old != null && old.longValue() != sync.hash) {
				throw new IllegalArgumentException("Already synced party old=" + old + ", new=" + sync);
			}

			if (complete) {
				logger.warn("Already completed sync " + this + ", sync=" + sync);
				return;
			}

			partyHashes.put(sync.user, sync.hash);

			if (hash != 0) {
				if (hash != sync.hash) {
					logger.error("PartiesSync.addSync DIVERGENCE detected: " + sync);
					NewRelic.noticeError("BATTLE DIVERGENCE detected: " + sync);
					divergence = true;
				}
			} else {
				hash = sync.hash;
			}

			for (int i = 0; i < battleCreateData.parties.length; ++i) {
				final BattlePartyData bpd = battleCreateData.getPartyByIndex(i);
				if (!partyHashes.containsKey(bpd.user)) {
					save();
					return;
				}
			}

			logger.debug("PartiesSync.addSync COMPLETE " + sync);
			complete = true;
			save();
		}
	}

	public PartiesSync addSync(BattleSyncData sync) {
		PartiesSync ps = turnSyncs.get(sync.turn);
		if (ps == null) {
			ps = new PartiesSync(sync.turn);
			turnSyncs.put(sync.turn, ps);
		}

		ps.addSync(sync);
		return ps;
	}

	class BattleConsumer extends DefaultConsumer {

		public BattleConsumer(Channel channel) {
			super(channel);
		}

		private HashSet<String> unbinds = new HashSet<String>();

		private void unbindFromUser(final long account_id, final boolean alsoUnbindUser) {

			if (cleanedup) {
				return;
			}

			if (null == battleCreateData.getPartyById(account_id)) {
				logger.error("No such user in battle: " + account_id);
				return;
			}

			final String key = BattleSystem.getUserBattleKey(battleCreateData.battleId, account_id);
			if (!unbinds.contains(key)) {
				unbinds.add(key);
				logger.debug("UNBINDING " + monitorQueue + ", " + BattleSystem.EXCHANGE + ", " + key);

				Channel c = null;
				UnbindOk ok = null;
				try {
					c = rabbit.createTemporaryChannel(this, RabbitConfig.Consume.NO);
					c.queueBind(monitorQueue, BattleSystem.EXCHANGE, key);
					ok = c.queueUnbind(monitorQueue, BattleSystem.EXCHANGE, key);
					c.close();
				} catch (Exception e) {
					e.printStackTrace();
				}

				if (ok == null) {
					logger.error("FAILED UNBIND");
				}

				if (unbinds.size() >= battleCreateData.parties.length) {
					logger.debug("Unbound from all users");
				}

				if (!exits.contains(account_id)) {
					exits.add(account_id);
					if (alsoUnbindUser) {
						unbindUserFromBattle(account_id, null);
					}
				}

				checkBattleFinished();
				checkCleanup();
			}
		}

		@Override
		public void handleShutdownSignal(String consumerTag, ShutdownSignalException sig) {
			if (!sig.isInitiatedByApplication()) {
				logger.error("handleShutdownSignal: " + sig);
				sig.printStackTrace();
			}
		}

		@Override
		synchronized public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) {

			if (cleanedup) {
				return;
			}

			try {
				Object msg = MsgSystem.parseResponseConsume(body, properties, consumerTag);

				logger.debug("handleDelivery " + msg);

				if (msg instanceof BaseBattleData) {
					final BaseBattleData base = (BaseBattleData) msg;
					if (base.battleId != null && !battleCreateData.battleId.equals(base.battleId)) {
						logger.warn("handleDelivery for another battle: " + msg);
						if (battleCreateData.getPartyById(base.user) == null) {
							unbindFromUser(base.user, false);
						}
						return;
					}
					recordMsg(base);
				}
				handleMessage(msg);

			} catch (Exception exp) {
				logger.error("handleDelivery fail: " + exp);
				exp.printStackTrace();
			}
		}

		public void handleMessage(final Object msg) {
			if (msg instanceof BattleAbortData) {
				final BattleAbortData bfd = (BattleAbortData) msg;
				handleBattleAbort(bfd);
			} else if (msg instanceof BattleSyncData) {
				handleBattleSync((BattleSyncData) msg);
			} else if (msg instanceof BattleSurrenderData) {
				handleBattleSurrender((BattleSurrenderData) msg);
			} else if (msg instanceof BattleActionData) {
				handleBattleAction((BattleActionData) msg);
			} else if (msg instanceof BattleMoveData) {
				handleBattleMove((BattleMoveData) msg);
			} else if (msg instanceof BattleExitData) {
				handleBattleExit((BattleExitData) msg);
			} else if (msg instanceof BattleReadyData) {
				handleBattleReady((BattleReadyData) msg);
			} else if (msg instanceof BattleKilledData) {
				handleBattleKilled((BattleKilledData) msg);
			} else if (msg instanceof AchievementProgressData) {
				handleAchievementProgress((AchievementProgressData) msg);
			} else if (msg instanceof BattleQueryData) {
				handleQuery((BattleQueryData) msg);
			}
		}

		private int numTeamsRemaining() {
			final HashSet<String> teams = new HashSet<String>();
			for (int i = 0; i < battleCreateData.parties.length; ++i) {
				BattlePartyData bpd = (BattlePartyData) battleCreateData.parties[i];
				if (!aborts.contains(bpd.user) && !surrenders.contains(bpd.user)) {
					teams.add(bpd.team);
				}
			}

			return teams.size();
		}

		private int numTeamsAlive() {
			final HashSet<String> teams = new HashSet<String>();
			for (int i = 0; i < battleCreateData.parties.length; ++i) {
				final BattlePartyData bpd = (BattlePartyData) battleCreateData.parties[i];
				final PartiesKills pk = kills.get(bpd.user);
				for (int j = 0; j < bpd.defs.length; ++j) {
					final EntityDef def = bpd.getEntityDef(j);
					if (!pk.isKilled(def.id)) {
						teams.add(bpd.team);
						break;
					}
				}
			}

			return teams.size();
		}

		private void handleBattleSync(final BattleSyncData sync) {

			final int oldNumTurns = numTurns;
			final int oldNumTurnsComplete = numTurnsComplete;
			final boolean oldDiverged = diverged;

			logger.debug("handleBattleSync " + sync + " " + sync.hash_str);

			numTurns = Math.max(numTurns, sync.turn);

			final PartiesSync ps = addSync(sync);

			if (ps.complete) {
				numTurnsComplete = Math.max(numTurnsComplete, ps.turn);
			}

			if (ps.divergence) {
				if (!diverged) {
					diverged = true;
					divergenceTurn = ps.turn;
				}
			}

			if (oldNumTurns != numTurns || oldNumTurnsComplete != numTurnsComplete || oldDiverged != diverged) {
				persistTurns();
			}
		}

		private void handleBattleSurrender(final BattleSurrenderData surrender) {

			// TODO once we get a surrender from a player, we should not require
			// any further messages

			BattlePartyData bpd = battleCreateData.getPartyById(surrender.user);
			if (surrenders.contains(surrender.user)) {
				logger.debug("handleBattleSurrender already handled at turn " + bpd.surrender_turn);
				return;
			}

			if (!readies.contains(surrender.user)) {
				logger.debug("Surrender too early, converting to ABORT: " + surrender);
				emitAbortUser(surrender.user, bpd.match_handle);
				return;
			}

			surrenders.add(surrender.user);

			bpd.saveSurrenderTurn(config, battleCreateData.battleId, surrender.turn);

			checkBattleFinished();

			if (numTeamsRemaining() <= 0) {
				logger.debug("SURRENDER NO TEAMS REMAINING");
				// no more battle left to do
				setReadyForCleanup();
			}
		}

		private void handleBattleAction(final BattleActionData action) {

			NewRelic.incrementCounter("Custom/battle/action/" + action.action);
			action.save(config);
		}

		private void handleBattleMove(final BattleMoveData move) {
			move.save(config);
		}

		private void handleBattleExit(final BattleExitData exit) {
			unbindFromUser(exit.user, true);
			// unbindUserFromBattle(exit.user, null);
			checkCleanup();
		}

		private void handleQuery(final BattleQueryData msg) {
			logger.debug("handleQuery " + msg);

			if (!msg.battleId.equals(battleCreateData.battleId)) {
				return;
			}

			final String q = MsgSystem.getUserQueue(msg.user);

			final BattleMoveData move = loadBattleMoveData(msg.turn);

			if (move != null) {
				config.msg.send("", move, MsgSystem.ZIP, q);
			}

			final BattleActionData action = loadBattleActionData(msg.turn);

			if (action != null) {
				config.msg.send("", action, MsgSystem.ZIP, q);
			}

			if (finished != null) {
				config.msg.send("", finished, MsgSystem.ZIP, q);
			}

		}

		synchronized private BattleMoveData loadBattleMoveData(final int turn) {
			Connection con = null;
			PreparedStatement ps = null;
			try {
				con = config.rdsDatasource.getConnection();

				{
					ps = con.prepareStatement("SELECT * from battle_move where battle_id=? AND battle_turn=?");
					ps.setString(1, battleCreateData.battleId);
					ps.setInt(2, turn);
					final ResultSet rs = ps.executeQuery();
					if (rs.next()) {
						final BattleMoveData msg = new BattleMoveData();
						msg.battleId = battleCreateData.battleId;
						msg.user = rs.getLong("account_id");
						msg.entity = rs.getString("entity_id");
						msg.turn = rs.getInt("battle_turn");
						msg.ordinal = rs.getInt("ordinal");

						final String tilesj = rs.getString("battle_tiles");
						msg.tiles = (Object[]) JSON.parse(tilesj);
						msg.validateTilesJson();

						return msg;
					}

					ps.close();
				}

			} catch (SQLException e) {
				logger.error("loadBattleMoveData: " + e);
				e.printStackTrace();
			} finally {
				DbHelper.cleanup(con, ps);
			}

			return null;
		}

		synchronized private BattleActionData loadBattleActionData(final int turn) {
			Connection con = null;
			PreparedStatement ps = null;
			try {
				con = config.rdsDatasource.getConnection();

				{
					ps = con.prepareStatement("SELECT * from battle_action where battle_id=? AND battle_turn=?");
					ps.setString(1, battleCreateData.battleId);
					ps.setInt(2, turn);
					final ResultSet rs = ps.executeQuery();
					if (rs.next()) {
						final BattleActionData msg = new BattleActionData();
						msg.battleId = battleCreateData.battleId;
						msg.user = rs.getLong("account_id");
						msg.entity = rs.getString("entity_id");
						msg.turn = rs.getInt("battle_turn");

						msg.action = rs.getString("battle_action");
						msg.level = rs.getInt("battle_action_level");
						msg.executed_id = rs.getInt("battle_action_executed_id");
						msg.ordinal = rs.getInt("ordinal");
						msg.terminator = rs.getBoolean("terminator");

						final String tilesj = rs.getString("battle_tiles");
						if (tilesj != null) {
							msg.tiles = (Object[]) JSON.parse(tilesj);
						}
						msg.validateTilesJson();

						final String targetsj = rs.getString("battle_target_ids");
						if (targetsj != null) {
							msg.target_ids = (Object[]) JSON.parse(targetsj);
						}
						return msg;
					}

					ps.close();
				}

			} catch (SQLException e) {
				logger.error("loadBattleMoveData: " + e);
				e.printStackTrace();
			} finally {
				DbHelper.cleanup(con, ps);
			}

			return null;
		}

		private void handleBattleKilled(final BattleKilledData data) {

			logger.info("handleBattleKilled " + data.killedparty + "/" + data.entity + " BY " + data.killerparty + "/" + data.killer + " VIA " + data.user);
			final PartiesKills pk = kills.get(data.killedparty);
			if (pk.isKilled(data)) {
				logger.info("handleBattleKilled ALREADY KILLED " + data.entity);
			} else if (!pk.reportKill(data)) {
				logger.info("handleBattleKilled incomplete report " + data.entity + " VIA " + data.user);
			} else {
				logger.info("handleBattleKilled fully killed " + data.entity + " VIA " + data.user);
				// fresh kill, report
				if (data.killerparty > 0 && data.killer != null) {

					final BattlePartyData killedparty = battleCreateData.getPartyById(data.killedparty);
					final BattlePartyData killerparty = battleCreateData.getPartyById(data.killerparty);

					// only against opposing teams
					if (!killerparty.team.equals(killedparty.team)) {

						// don't count kills in friend battles
						if (!battleCreateData.friendly) {
							final EntityDef e = killerparty.getEntityDefById(data.killer);
							e.incrementKills(killerparty.user);
							NewRelic.incrementCounter("Custom/battle/party/killer/" + e.entityClass);
						}

						if (++totalKills == 1) {
							saveFirstBlood();
						}
					}

					final EntityDef killed = killedparty.getEntityDefById(data.entity);
					NewRelic.incrementCounter("Custom/battle/party/killed/" + killed.entityClass);
				}
			}

			checkBattleFinished();
		}

		private void handleBattleReady(final BattleReadyData ready) {

			final BattlePartyData bpd = battleCreateData.getPartyById(ready.user);
			if (!GameConfig.instance.BATTLE_GLOBAL_CHAT) {
				GameConfig.instance.chat.getRoom(ChatSystem.ROOM_GLOBAL, true).removeMember(bpd.user, bpd.display_name);
			}

			readies.add(ready.user);
		}

		private void handleBattleAbort(final BattleAbortData abort) {

			logger.debug("handleBattleAbort " + abort);

			final BattlePartyData bpd = battleCreateData.getPartyById(abort.user);
			// zero match_handle means match all
			if (bpd == null || (bpd.match_handle != abort.match_handle && abort.match_handle != 0)) {
				logger.debug("handleBattleAbort wrong battle, skipping " + abort);
				// this is an abort for another battle
				return;
			}

			unbindFromUser(abort.user, true);
			if (abort.battleId == null || abort.battleId.isEmpty()) {
				disconnects.add(abort.user);
			}

			if (finished != null) {
				logger.debug("handleBattleAbort already finished, skipping " + abort);
				// already finished
				return;
			}

			if (readies.contains(abort.user)) {
				logger.info("ABORT " + abort + " too late for ready user converting to SURRENDER");
				final BattleSurrenderData surrender = new BattleSurrenderData(abort.user, battleCreateData.battleId, numTurns);
				config.msg.send(BattleSystem.EXCHANGE, surrender, MsgSystem.ZIP, surrender.battleId);
				// let this trickle through to battle finishing if necessary
			} else if (!aborts.contains(abort.user)) {
				aborts.add(abort.user);

				final int remains = numTeamsRemaining();
				logger.debug("ABORT " + abort + " with numTeamsRemaining=" + remains);

				if (abort.battleId == null || abort.battleId.isEmpty()) {
					// re-send the message with the correct battleId
					final BattleAbortData reabort = new BattleAbortData(abort.user, battleCreateData.battleId, abort.match_handle);
					logger.debug("ABORT RESEND " + reabort);
					config.msg.send(BattleSystem.EXCHANGE, reabort, MsgSystem.ZIP, reabort.battleId);
				}

				if (remains <= 1) {
					final BattleAbortedData aborted = new BattleAbortedData(battleCreateData.battleId);
					logger.debug("ABORT ABORTING ENTIRE BATTLE " + aborted);
					config.msg.send(BattleSystem.EXCHANGE, aborted, MsgSystem.ZIP, aborted.battleId);

					for (int i = 0; i < battleCreateData.parties.length; ++i) {
						BattlePartyData other = (BattlePartyData) battleCreateData.parties[i];
						exits.add(other.user);
					}

					saveAborted();

					checkBattleFinished();

					// no more battle left to do
					setReadyForCleanup();
				}

				if (unbinds.size() >= battleCreateData.parties.length) {
					saveAborted();
					setReadyForCleanup();
				}
			}

		}

		private void handleAchievementProgress(AchievementProgressData data) {

			if (waitingAchievementProgressHandles.contains(data.handle)) {
				waitingAchievementProgressHandles.remove(data.handle);
			}

			if (!achievements.containsKey(data.account_id)) {
				achievements.put(data.account_id, new ArrayList<String>());
			}

			for (int i = 0; i < data.acquired.length; ++i) {
				// achievements.add(data.acquired[i].toString());
				achievements.get(data.account_id).add(data.acquired[i].toString());
			}

			if (waitingAchievementProgressHandles.isEmpty() && finishing != null) {
				checkBattleFinished();
			}
		}

		@Trace
		private void saveFinish(final BattleFinishedData bfd) {

			if (bfd == null) {
				throw new IllegalArgumentException("No BattleFinishedData for saveFinish " + this);
			}

			Connection con = null;
			PreparedStatement ps = null;

			final long end_time = System.currentTimeMillis();

			try {

				int eloDelta = battleCreateData.getTeamEloDelta(bfd.victoriousTeam);
				int powerDelta = battleCreateData.getTeamPowerDelta(bfd.victoriousTeam);

				con = config.rdsDatasource.getConnection();

				final String sql = "UPDATE `battle` SET `end_time`=?, `surrender`=?, `victor_team`=?, `victor_delta_elo`=?, `victor_delta_power`=?, `num_turns`=?, `renown`=? WHERE `battle_id`=?";

				ps = con.prepareStatement(sql);
				int index = 0;
				ps.setLong(++index, end_time);
				ps.setBoolean(++index, surrenders.size() > 0); // surrender?
				ps.setString(++index, bfd.victoriousTeam);
				ps.setInt(++index, eloDelta);
				ps.setInt(++index, powerDelta);
				ps.setInt(++index, numTurns);
				ps.setInt(++index, bfd.total_renown);
				ps.setString(++index, battleCreateData.battleId);
				ps.executeUpdate();
			} catch (SQLException e) {
				logger.error("saveFinish: " + e);
				e.printStackTrace();
				return;
			} finally {
				DbHelper.cleanup(con, ps);
			}

			for (int i = 0; i < battleCreateData.parties.length; ++i) {
				final BattlePartyData bpd = battleCreateData.getPartyByIndex(i);

				if (bpd == null) {
					logger.error("saveFinish " + this + " unable to find party by index " + i);
				}

				final boolean complete = !aborted && !diverged && !aborts.contains(bpd.user);

				{
					final boolean is_victor = bfd.victoriousTeam != null && bfd.victoriousTeam.equals(bpd.team);
					final int renown = bfd.getPartyRenown(i);
					final int elo = getCachedRanking(bpd.user, battleCreateData.tourney_id).elo;
					// TODO, probably want to record the global elo if
					// tourney_id != 0
					bpd.saveComplete(config, battleCreateData.battleId, end_time, is_victor, renown, elo, complete);
				}

				if (complete && !surrenders.contains(bpd.user)) {
					UserData.incrementBattleCount(config, bpd.user);

					for (int j = 0; j < bpd.defs.length; ++j) {
						final EntityDef def = bpd.getEntityDef(j);
						EntityDef.incrementBattles(config.rdsDatasource, bpd.user, def.id);
					}
				}
			}
		}

		@Trace
		synchronized private void saveRenown(final BattleFinishedData bfd) {

			if (bfd.rewards.length == 0) {
				logger.warn("saveRenown: No renown to save for " + bfd);
				return;
			}

			if (aborted) {
				return;
			}

			Connection con = null;
			PreparedStatement ps = null;
			try {
				con = config.rdsDatasource.getConnection();

				{
					final String sql0 = "INSERT INTO battle_renown (battle_id, session_key, account_id, party_index, total_renown, brat_kills, brat_underdog, brat_daily, brat_friend, brat_boost, brat_streak, brat_expert, achievement_renown, renown_time) VALUES ";
					final String sql1 = "(?,?,?,?,?,?,?,?,?,?,?,?,?,?) ";

					StringBuilder sb = new StringBuilder(sql0);

					for (int i = 0; i < bfd.rewards.length; ++i) {
						if (i > 0) {
							sb.append(",");
						}
						sb.append(sql1);
					}

					ps = con.prepareStatement(sb.toString());

					int index = 0;
					for (int i = 0; i < bfd.rewards.length; ++i) {
						final BattlePartyData bpd = battleCreateData.getPartyByIndex(i);

						ps.setString(++index, bfd.battleId);
						ps.setLong(++index, bpd.session_key);
						ps.setLong(++index, bpd.user);
						ps.setInt(++index, bpd.party_index);

						final BattleRewardData brd = bfd.rewards[bpd.party_index];

						ps.setInt(++index, brd.total_renown);
						ps.setInt(++index, brd.getAward(BattleRenownAwardType.KILLS));
						ps.setInt(++index, brd.getAward(BattleRenownAwardType.UNDERDOG));
						ps.setInt(++index, brd.getAward(BattleRenownAwardType.DAILY));
						ps.setInt(++index, brd.getAward(BattleRenownAwardType.FRIEND));
						ps.setInt(++index, brd.getAward(BattleRenownAwardType.BOOST));
						ps.setInt(++index, brd.getAward(BattleRenownAwardType.STREAK));
						ps.setInt(++index, brd.getAward(BattleRenownAwardType.EXPERT));
						ps.setInt(++index, brd.total_achievement_renown);
						ps.setLong(++index, bfd.timestamp);
					}

					ps.executeUpdate();
				}

			} catch (SQLException e) {
				logger.error("saveRenown: " + " ps=" + ps + " e=" + e);
				e.printStackTrace();
				return;
			} finally {
				DbHelper.cleanup(con, ps);
			}

			for (int i = 0; i < bfd.rewards.length; ++i) {
				final int renown = bfd.getPartyRenown(i);
				if (renown != 0) {
					final BattlePartyData party = battleCreateData.getPartyByIndex(i);
					config.renown.modifyRenown(party.user, renown, RenownReason.BATTLE, battleCreateData.battleId);

					NewRelic.recordMetric("Custom/battle/renown/total", renown);
				}
			}
		}

		synchronized private void checkBattleFinished() {

			if (finished != null) {
				return;
			}

			logger.debug("ENTER checkBattleFinished()");

			final int numTeams = numTeamsRemaining();

			if (finishing == null) {

				logger.debug("checkBattleFinished() finishing == null");

				if (numTeams > 1) {

					final int aliveTeams = numTeamsAlive();
					if (aliveTeams > 1) {
						logger.debug("checkBattleFinished NOPE, aliveTeams=" + aliveTeams);
						return;
					}

				} else {
					logger.debug("checkBattleFinished EMPTIED, numTeams=" + numTeams);
				}

				cacheFriendBattleRecord();
				cacheRankings();
				finishing = constructBattleFinishedData();
				constructAchievementData(); // writes into finished
				logger.info("checkBattleFinished() finishing constructed");
			}

			if (finalizeFinishing() == true) {

				logger.debug("checkBattleFinished() before handleBattleFinished()");

				handleBattleFinished(finishing);

				logger.debug("checkBattleFinished() after handleBattleFinished()");
			}

		}

		// private boolean disable_achievements = true;

		private boolean disable_achievements = false;

		synchronized private void constructAchievementData() {

			if (disable_achievements) {
				return;
			}

			if (aborted) {
				return;
			}

			for (int i = 0; i < battleCreateData.parties.length; ++i) {

				final BattlePartyData bpd = (BattlePartyData) battleCreateData.parties[i];

				// use only the global ranking for achievements
				final BattleRanking br = getCachedRanking(bpd.user, 0);

				if (!battleCreateData.friendly) {

					// battle achievement
					if (!surrenders.contains(bpd.user) && !aborted) {
						final String battleHandle = createAchievementProgressHandle(bpd.user, AchievementType.BATTLES);
						final int battleDelta = 1;
						waitingAchievementProgressHandles.add(battleHandle);
						AchievementSystem.incrementAchievementProgress(battleHandle, battleCreateData.battleId, config.rabbit, bpd.user, bpd.session_key,
								AchievementType.BATTLES, battleDelta);

						final boolean i_victor = bpd.team.equals(finishing.victoriousTeam);
						// win achievement
						if (i_victor) {

							final String winHandle = createAchievementProgressHandle(bpd.user, AchievementType.WINS);
							final int winDelta = 1;
							waitingAchievementProgressHandles.add(winHandle);
							AchievementSystem.incrementAchievementProgress(winHandle, battleCreateData.battleId, config.rabbit, bpd.user, bpd.session_key,
									AchievementType.WINS, winDelta);
						}

						// victors/defeats

						for (int j = 0; j < bpd.defs.length; ++j) {
							final EntityDef def = bpd.getEntityDef(j);
							if (i_victor) {
								NewRelic.incrementCounter("Custom/battle/party/victor/" + def.entityClass);
							} else {
								NewRelic.incrementCounter("Custom/battle/party/defeat/" + def.entityClass);
							}
						}

						// streak achievement
						if (i_victor) {
							final String streakHandle = createAchievementProgressHandle(bpd.user, AchievementType.STREAK);
							final int streakAmount = br.win_streak + 1; // +1
																		// for
																		// this
																		// win
							// for testing
							// final int streakAmount = 51;
							waitingAchievementProgressHandles.add(streakHandle);
							AchievementSystem.updateAchievementProgress(streakHandle, battleCreateData.battleId, config.rabbit, bpd.user, bpd.session_key,
									AchievementType.STREAK, streakAmount);
						}
					}

					// elo achievement
					{
						final String eloHandle = createAchievementProgressHandle(bpd.user, AchievementType.ELO);
						final int eloAmount = br.elo;
						// for testing
						// final int eloAmount = 2500;
						waitingAchievementProgressHandles.add(eloHandle);
						AchievementSystem.updateAchievementProgress(eloHandle, battleCreateData.battleId, config.rabbit, bpd.user, bpd.session_key,
								AchievementType.ELO, eloAmount);
					}

					// unit kills achievement
					{
						final String unitKillsHandle = createAchievementProgressHandle(bpd.user, AchievementType.UNIT_KILL);
						int maxKills = 0;
						for (int j = 0; j < bpd.defs.length; ++j) {
							final EntityDef def = bpd.getEntityDef(j);
							int numKills = def.getStatValue(StatType.KILLS.name());
							if (numKills > maxKills) {
								maxKills = numKills;
							}
						}

						logger.debug("^^^^^ " + bpd.user + " maxKills = " + maxKills);
						// for testing
						// maxKills = 100;
						waitingAchievementProgressHandles.add(unitKillsHandle);
						AchievementSystem.updateAchievementProgress(unitKillsHandle, battleCreateData.battleId, config.rabbit, bpd.user, bpd.session_key,
								AchievementType.UNIT_KILL, maxKills);
					}
				}
			}

		}

		synchronized private boolean finalizeFinishing() {

			logger.debug("ENTER finalizeFinishing()");

			if (waitingAchievementProgressHandles.isEmpty()) {

				logger.debug("finalizeFinishing() waitingAchievementProgressHandles isempty .. returning true");

				for (int partyIndex = 0; partyIndex < battleCreateData.parties.length; ++partyIndex) {

					final BattlePartyData bpd = (BattlePartyData) battleCreateData.parties[partyIndex];

					if (achievements.containsKey(bpd.user)) {
						for (int achIndex = 0; achIndex < achievements.get(bpd.user).size(); ++achIndex) {

							AchievementListItemDef def = config.achievement_list.getItem(achievements.get(bpd.user).get(achIndex));
							finishing.addAchievement(bpd.party_index, def.id, def.renownrewardamount);
						}
					}
				}

				finishing.compute();

				return true;
			} else {

				logger.debug("finalizeFinishing() waitingAchievementProgressHandles not empty .. returning false");

				for (String handle : waitingAchievementProgressHandles) {
					logger.debug("finalizeFinishing() wait handle " + handle);
				}

				return false;
			}
		}

		synchronized private BattleFinishedData constructBattleFinishedData() {

			logger.info("constructBattleFinishedData");

			final BattleFinishedData bfd = new BattleFinishedData(0, battleCreateData.battleId, battleCreateData.parties.length);

			if (aborted) {
				return bfd;
			}

			final boolean battle_ranking_allowed = isRankingAllowed();

			// one renown per kill

			for (int i = 0; i < battleCreateData.parties.length; ++i) {
				final BattlePartyData bpd = (BattlePartyData) battleCreateData.parties[i];

				// pks: how many party members from bpd are considered to be
				// killed
				// int pks = 0;

				boolean i_surrendered = false;
				boolean i_victor = false;
				int i_kill_renown = 0;

				if (surrenders.contains(bpd.user)) {
					logger.debug("constructBattleFinishedData SURRENDERED " + bpd);
					// surrendering is the same as losing everyone
					i_surrendered = true;

					for (int k = 0; k < bpd.defs.length; ++k) {
						final EntityDef e = bpd.getEntityDef(k);
						i_kill_renown += e.killRenown();
					}
				} else {
					final PartiesKills pk = kills.get(bpd.user);
					final int kc = pk.getKillCount();
					// some of the party remains, so they must be one of the
					// winners!
					i_victor = kc < bpd.defs.length;

					logger.debug("constructBattleFinishedData CASUALTIES " + bpd + " " + kc);

					for (int k = 0; k < bpd.defs.length; ++k) {
						final EntityDef e = bpd.getEntityDef(k);
						if (pk.isKilled(e.id)) {
							i_kill_renown += e.killRenown();
						}
					}
				}

				if (!battleCreateData.friendly) {

					if (!i_surrendered) {
						if (UserData.hasUnlock(config, bpd.user, "bst_renown")) {
							bfd.incrementAward(i, BattleRenownAwardType.BOOST, 5);
						}

						if (bpd.timer <= 30) {
							bfd.incrementAward(i, BattleRenownAwardType.EXPERT, 2);
						}
					}

					for (int k = 0; k < battleCreateData.parties.length; ++k) {

						if (i == k) {
							continue;
						}

						final BattlePartyData other = (BattlePartyData) battleCreateData.parties[k];

						if (!surrenders.contains(other.user)) {
							// get renown from deaths on the opposing team(s)
							if (!other.team.equals(bpd.team)) {
								logger.debug("constructBattleFinishedData AWARDING " + other + " " + i_kill_renown);
								bfd.incrementAward(k, BattleRenownAwardType.KILLS, i_kill_renown);
							}
						}

						if (!i_surrendered) {
							if (other.power > bpd.power) {

								// maybe data drive the underdog bonus
								final int UNDERDOG_INCREMENT = 1;
								final int UNDERDOG_MAX = 4;

								if (other.power >= (bpd.power)) {
									final int bonus = Math.min(UNDERDOG_MAX, (other.power - bpd.power) / UNDERDOG_INCREMENT);
									bfd.incrementAward(i, BattleRenownAwardType.UNDERDOG, bonus);
								}
							}
						}
					}
				}

				if (!i_surrendered) {
					final int login = UserData.consumeLoginStreakBonus(config, bpd.user);
					if (login > 0) {
						logger.debug("Applying loginStreakBonus to " + bpd);
						bfd.incrementAward(i, BattleRenownAwardType.DAILY, login);
					}
				}

				// some of the party remains, so they must be one of the
				// winners!
				if (i_victor) {
					logger.debug("constructBattleFinishedData VICTOR " + bpd + " " + bpd.team);
					bfd.victoriousTeam = bpd.team;

					if (!battleCreateData.friendly) {

						if (battle_ranking_allowed) {

							if (bpd.vs_type.allowRanking) {

								// use the the better of current tourney and
								// global for the win streak bizness
								int win_streak = getCachedRanking(bpd.user, battleCreateData.tourney_id).win_streak;

								if (win_streak < 2 && battleCreateData.tourney_id != 0) {
									final BattleRanking gbr = getCachedRanking(bpd.user, 0);
									win_streak = Math.max(win_streak, gbr.win_streak);
								}

								// streaks of 3 or more get a bonus
								// if the streak is currently 2 and this is a
								// win, this battle makes 3
								if (win_streak >= 2) {
									bfd.incrementAward(i, BattleRenownAwardType.STREAK, 1);
								}
							}
						}

						bfd.incrementAward(i, BattleRenownAwardType.WIN, 5);
					}

					// TODO make sure we record the wins for the whole team, not
					// for each party
					if (friendBattleRecord != null) {
						if (bpd.user == friendBattleRecord.account_id_0) {
							++friendBattleRecord.wins_0;
						} else {
							++friendBattleRecord.wins_1;
						}
					}
				}

				if (friendBattleRecord != null) {
					if (!i_surrendered) {
						// first time against this friend
						if (friendBattleRecord.last_time == 0) {
							bfd.incrementAward(i, BattleRenownAwardType.FRIEND, 6);
						}
					}
				}
			}

			bfd.compute();

			return bfd;
		}

		synchronized private void handleBattleFinished(final BattleFinishedData bfd) {

			if (finished != null) {
				return;
			}

			finished = bfd;

			logger.info("Finishing battle " + battleCreateData.battleId);

			// final BattleNotification bn = new BattleNotification(false,
			// bfd.victoriousTeam, battleCreateData.getTeamMembers(null));
			// config.msg.send("amq.fanout", bn, MsgSystem.ZIP);

			updateRankings();
			saveFinish(bfd);
			saveRenown(bfd);
			saveFriendBattleRecord();
			saveRankings(bfd);

			config.msg.send(BattleSystem.EXCHANGE, bfd, MsgSystem.ZIP, bfd.battleId);

			final int tourney_id = battleCreateData.tourney_id;
			final LeaderboardDirtyData ldd = new LeaderboardDirtyData(tourney_id);
			config.msg.send("amq.direct", ldd, MsgSystem.ZIP, LeaderboardDirtyData.KEY);

			setReadyForCleanup();
		}

		final HashMap<Long, HashMap<Integer, BattleRanking>> rankings = new HashMap<Long, HashMap<Integer, BattleRanking>>();

		class FriendBattleRecord {
			public long account_id_0;
			public long account_id_1;
			public int wins_0;
			public int wins_1;
			public long last_time;
		};

		private FriendBattleRecord friendBattleRecord;

		private void cacheFriendBattleRecord() {
			if (!battleCreateData.friendly) {
				return;
			}

			// surrender does not count
			if (surrenders.size() != 0 || aborted) {
				return;
			}

			friendBattleRecord = new FriendBattleRecord();
			friendBattleRecord.account_id_0 = battleCreateData.getPartyByIndex(0).user;
			friendBattleRecord.account_id_1 = battleCreateData.getPartyByIndex(1).user;

			Connection con = null;
			PreparedStatement s = null;
			try {
				con = GameConfig.instance.rdsDatasource.getConnection();

				{
					s = con.prepareStatement("SELECT wins_0, wins_1, last_time FROM friend_battle_record where account_id_0=? AND account_id_1=?");
					s.setLong(1, friendBattleRecord.account_id_0);
					s.setLong(2, friendBattleRecord.account_id_1);
					final ResultSet rs = s.executeQuery();
					if (rs.next()) {
						friendBattleRecord.wins_0 = rs.getInt("wins_0");
						friendBattleRecord.wins_1 = rs.getInt("wins_1");
						friendBattleRecord.last_time = rs.getLong("last_time");
					}
					s.close();
				}

			} catch (SQLException e) {
				logger.error("get where: " + e);
				e.printStackTrace();
			} finally {
				DbHelper.cleanup(con, s);
			}
		}

		private void saveFriendBattleRecord() {
			if (friendBattleRecord == null) {
				return;
			}

			if (aborted) {
				return;
			}

			boolean insert = friendBattleRecord.last_time <= 0;
			friendBattleRecord.last_time = System.currentTimeMillis();

			Connection con = null;
			PreparedStatement s = null;
			try {
				con = GameConfig.instance.rdsDatasource.getConnection();

				if (insert) {
					s = con.prepareStatement("INSERT into friend_battle_record (wins_0, wins_1, last_time, account_id_0, account_id_1) VALUES (?,?,?,?,?)");
					s.setInt(1, friendBattleRecord.wins_0);
					s.setInt(2, friendBattleRecord.wins_1);
					s.setLong(3, friendBattleRecord.last_time);
					s.setLong(4, friendBattleRecord.account_id_0);
					s.setLong(5, friendBattleRecord.account_id_1);
					s.executeUpdate();
					s.close();

					s = con.prepareStatement("INSERT into friend_battle_record (wins_0, wins_1, last_time, account_id_0, account_id_1) VALUES (?,?,?,?,?)");
					s.setInt(1, friendBattleRecord.wins_1);
					s.setInt(2, friendBattleRecord.wins_0);
					s.setLong(3, friendBattleRecord.last_time);
					s.setLong(4, friendBattleRecord.account_id_1);
					s.setLong(5, friendBattleRecord.account_id_0);
					s.executeUpdate();
					s.close();
				} else {
					s = con.prepareStatement("UPDATE friend_battle_record SET wins_0=?, wins_1=?, last_time=?, account_id_0=?, account_id_1=? WHERE account_id_0=? AND account_id_1=?");
					s.setInt(1, friendBattleRecord.wins_0);
					s.setInt(2, friendBattleRecord.wins_1);
					s.setLong(3, friendBattleRecord.last_time);
					s.setLong(4, friendBattleRecord.account_id_0);
					s.setLong(5, friendBattleRecord.account_id_1);
					s.setLong(6, friendBattleRecord.account_id_0);
					s.setLong(7, friendBattleRecord.account_id_1);
					s.executeUpdate();
					s.close();

					s = con.prepareStatement("UPDATE friend_battle_record SET wins_0=?, wins_1=?, last_time=?, account_id_0=?, account_id_1=? WHERE account_id_0=? AND account_id_1=?");
					s.setInt(1, friendBattleRecord.wins_1);
					s.setInt(2, friendBattleRecord.wins_0);
					s.setLong(3, friendBattleRecord.last_time);
					s.setLong(4, friendBattleRecord.account_id_1);
					s.setLong(5, friendBattleRecord.account_id_0);
					s.setLong(6, friendBattleRecord.account_id_1);
					s.setLong(7, friendBattleRecord.account_id_0);
					s.executeUpdate();
					s.close();
				}

			} catch (SQLException e) {
				logger.error("saveFriendBattleRecord: " + e);
				e.printStackTrace();
			} finally {
				DbHelper.cleanup(con, s);
			}
		}

		private void cacheRankings() {

			Connection con = null;
			PreparedStatement s = null;
			try {
				con = GameConfig.instance.rdsDatasource.getConnection();

				for (int i = 0; i < battleCreateData.parties.length; ++i) {
					final BattlePartyData bpd = (BattlePartyData) battleCreateData.parties[i];
					if (bpd.tourney_id != 0) {
						s = con.prepareStatement(//
						"SELECT t1.*, t2.`steam_id` FROM `ranking` as t1 INNER JOIN `auth_account` as t2 ON t1.`account_id` = t2.`account_id` WHERE (t1.tourney_id=? OR t1.tourney_id=0) AND t1.`account_id` = ?");
					} else {
						s = con.prepareStatement(//
						"SELECT t1.*, t2.`steam_id` FROM `ranking` as t1 INNER JOIN `auth_account` as t2 ON t1.`account_id` = t2.`account_id` WHERE t1.tourney_id=? AND t1.`account_id` = ?");

					}
					s.setInt(1, bpd.tourney_id);
					s.setLong(2, bpd.user);
					final ResultSet rs = s.executeQuery();
					while (rs.next()) {
						BattleRanking r = new BattleRanking(rs);
						setCachedRanking(r);
					}
					s.close();
				}

			} catch (SQLException e) {
				logger.error("get where: " + e);
				e.printStackTrace();
			} finally {
				DbHelper.cleanup(con, s);
			}

			// make sure everyone in the battle has a ranking, at least
			// in-memory
			for (int i = 0; i < battleCreateData.parties.length; ++i) {
				final BattlePartyData bpd = (BattlePartyData) battleCreateData.parties[i];

				if (getCachedRanking(bpd.user, battleCreateData.tourney_id) == null) {
					final BattleRanking r = new BattleRanking(bpd.user, bpd.tourney_id);
					setCachedRanking(r);
				}

				if (battleCreateData.tourney_id != 0) {
					if (getCachedRanking(bpd.user, 0) == null) {
						final BattleRanking r = new BattleRanking(bpd.user, 0);
						setCachedRanking(r);
					}
				}
			}
		}

		final static int RANKING_ALLOWED_POWER_MIN = 6;

		private boolean isRankingAllowed() {
			if (battleCreateData.tourney_id != 0) {
				return true;
			}

			// non tourney games have a power minimum for elo exchange
			for (int i = 0; i < battleCreateData.parties.length; ++i) {
				final BattlePartyData other = (BattlePartyData) battleCreateData.parties[i];
				if (other.power < RANKING_ALLOWED_POWER_MIN) {
					return false;
				}
			}

			return true;
		}

		private void updateRankings() {

			if (finished == null) {
				throw new IllegalAccessError();
			}

			if (aborted) {
				logger.debug("updateRankings cannot update rankings on aborted battle");
				return;
			}

			if (!isRankingAllowed()) {
				logger.debug("updateRankings disallowing Elo due to party power");
				return;
			}

			for (int i = 0; i < battleCreateData.parties.length; ++i) {
				final BattlePartyData bpd = (BattlePartyData) battleCreateData.parties[i];

				if (!bpd.vs_type.allowRanking) {
					logger.debug("updateRankings disallowing Elo due to vs_type: " + bpd);
					continue;
				}

				boolean win = bpd.team.equals(finished.victoriousTeam);

				final BattleRanking r = getCachedRanking(bpd.user, battleCreateData.tourney_id);
				updateRanking(bpd, win, r);

				if (battleCreateData.tourney_id != 0) {
					final BattleRanking gr = getCachedRanking(bpd.user, 0);
					updateRanking(bpd, win, gr);
				}
			}
		}

		private BattleRanking getCachedRanking(final long account_id, final int tourney_id) {
			final HashMap<Integer, BattleRanking> forAccount = rankings.get(account_id);
			if (forAccount != null) {
				return forAccount.get(tourney_id);
			}
			return null;
		}

		private void setCachedRanking(final BattleRanking r) {
			HashMap<Integer, BattleRanking> forAccount = rankings.get(r.account_id);
			if (forAccount == null) {
				forAccount = new HashMap<Integer, BattleRanking>();
				rankings.put(r.account_id, forAccount);
			}
			forAccount.put(r.tourney_id, r);
		}

		private Integer getOtherElo(final BattlePartyData bpd, final int tourney_id) {
			int otherElo = 0;
			int otherCount = 0;
			for (int j = 0; j < battleCreateData.parties.length; ++j) {
				final BattlePartyData other = (BattlePartyData) battleCreateData.parties[j];
				if (!other.team.equals(bpd.team)) {

					if (!other.vs_type.allowRanking) {
						return null;
					}

					final BattleRanking otherr = getCachedRanking(other.user, tourney_id);
					if (otherr != null) {
						otherElo += otherr.elo;
						++otherCount;
					}
				}
			}

			if (otherCount > 0) {
				otherElo /= otherCount;
				return otherElo;
			}

			return null;
		}

		private void updateRanking(final BattlePartyData bpd, final boolean win, final BattleRanking r) {

			if (win) {
				if (!battleCreateData.friendly) {
					r.incrementWins();
				}
			} else {
				if (!battleCreateData.friendly) {
					r.incrementLosses();
				}
			}

			if (battleCreateData.friendly) {
				++r.friend_battles;
			} else {
				r.best_win_streak = Math.max(r.best_win_streak, r.win_streak);

				Integer otherElo = getOtherElo(bpd, r.tourney_id);
				boolean quick = false;
				if (otherElo == null) {
					quick = true;
					otherElo = r.elo;
				}

				if (otherElo > 0) {
					int newElo = r.getNewElo(otherElo, win ? 1 : 0);

					if (quick) {
						if (win) {
							newElo = r.elo + 2;
						} else {
							newElo = r.elo - 2;
						}
					}

					logger.info("Changing Elo " + r.tourney_id + " of " + bpd + " from " + r.elo + " to " + newElo);
					r.elo = newElo;
				}
			}
		}

		@Trace
		private void saveRankings(final BattleFinishedData bfd) {

			if (rankings == null) {
				throw new IllegalAccessError();
			}

			if (aborted) {
				return;
			}

			final int tourney_id = battleCreateData.getPartyByIndex(0).tourney_id;
			final Tourney tourney = tourney_id != 0 ? Tourney.get(tourney_id) : null;

			if (tourney != null && (!tourney.started || tourney.ended)) {
				logger.debug("Tourney not started or already ended: " + tourney);
				return;
			}

			Connection con = null;
			try {
				con = GameConfig.instance.rdsDatasource.getConnection();
				for (int i = 0; i < battleCreateData.parties.length; ++i) {
					final BattlePartyData bpd = (BattlePartyData) battleCreateData.parties[i];
					final HashMap<Integer, BattleRanking> forAccount = rankings.get(bpd.user);
					if (forAccount != null) {
						for (BattleRanking r : forAccount.values()) {
							r.save(con);
						}
					}
				}
			} catch (SQLException e) {

				logger.error("get where: " + e);
				e.printStackTrace();
			} finally {
				DbHelper.cleanup(con, null);
			}

			if (tourney != null) {
				tourney.sendProgressToPlayers();
			} else {
				sendLeaderboardsToSteam();
			}

		}

		private void sendLeaderboardsToSteam() {

			if (!isRankingAllowed()) {
				logger.debug("sendLeaderboardsToSteam skipping due to party power");
				return;
			}

			new Thread() {

				@Override
				public void run() {

					try {

						for (int i = 0; i < battleCreateData.parties.length; ++i) {
							final BattlePartyData bpd = (BattlePartyData) battleCreateData.parties[i];

							if (!bpd.vs_type.allowRanking) {
								logger.debug("sendLeaderboardsToSteam skipping due to vs_type: " + bpd);
								continue;
							}

							// global rankings only
							final BattleRanking r = getCachedRanking(bpd.user, 0);

							if (r.steam_id > 0) {

								logger.debug("Pushing Steam Leaderboards for " + bpd + ", r=" + r);

								final long LEADERBOARD_WINS = 131893;
								final long LEADERBOARD_LOSSES = 131894;
								final long LEADERBOARD_WIN_LOSS = 131895;
								final long LEADERBOARD_ELO = 131896;

								Steam.Leaderboards.setLeaderboardScoreRetry(r.steam_id, LEADERBOARD_WINS, r.wins);
								Steam.Leaderboards.setLeaderboardScoreRetry(r.steam_id, LEADERBOARD_LOSSES, r.losses);
								final double winLoss = (r.losses > 0) ? ((double) r.wins) / r.losses : 1;
								Steam.Leaderboards.setLeaderboardScoreRetry(r.steam_id, LEADERBOARD_WIN_LOSS, winLoss);
								Steam.Leaderboards.setLeaderboardScoreRetry(r.steam_id, LEADERBOARD_ELO, r.elo);
							}
						}
					} catch (InterruptedException exp) {
						logger.error("saveRankings INTERRUPTED Steam");
						exp.printStackTrace();
						return;
					}
				}
			}.start();
		}
	}

	public BattleMonitor(BattleCreateData battleCreateData, GameConfig config, ChatRoom chatroom, final boolean save) throws IOException {
		this.battleCreateData = battleCreateData;
		logger = Logger.getLogger("BattleMonitor_" + battleCreateData.battleId);
		rabbit = config.rabbit;// new RabbitConfig(logger.getName(), false);
		consumerChannel = rabbit.createChannel(this);
		this.config = config;
		this.chatroom = chatroom;

		kills = new HashMap<Long, PartiesKills>();

		for (int i = 0; i < battleCreateData.parties.length; ++i) {
			final BattlePartyData bpd = battleCreateData.getPartyByIndex(i);
			final long userid = bpd.user;
			kills.put(userid, new PartiesKills(userid));

			NewRelic.incrementCounter("Custom/battle/party/power/" + bpd.power);

			for (int j = 0; j < bpd.defs.length; ++j) {
				final EntityDef def = bpd.getEntityDef(j);
				NewRelic.incrementCounter("Custom/battle/party/start/" + def.entityClass);
			}
		}

		this.battleConsumer = new BattleConsumer(consumerChannel);

		if (save) {
			battleCreateData.save(config);
			// recordMsg(battleCreateData);
		} else {
			depersist();
		}

		handleChannelCreated();

		logger.info("CTOR finished");

		requirePartySessions();

		if (!save) {
			if (readyForCleanup) {
				checkCleanup();
			}
		}
	}

	synchronized private void requirePartySessions() {
		for (int i = 0; i < battleCreateData.parties.length; ++i) {
			final BattlePartyData bpd = battleCreateData.getPartyByIndex(i);
			final SessionData sd = SessionData.loadUserSession(config.rdsDatasource, bpd.user);
			if (sd == null) {
				logger.info("requirePartySessions session not found, ABORTING " + bpd);
				disconnects.add(bpd.user);
				emitAbortUser(bpd.user, bpd.match_handle);
			}
		}
	}

	private void emitAbortUser(final long user, final int match_handle) {
		// abort the user
		final BattleAbortData abort = new BattleAbortData(user, battleCreateData.battleId, match_handle);
		logger.info("emitAbortUser  ABORTING " + abort);
		config.msg.send(BattleSystem.EXCHANGE, abort, MsgSystem.ZIP, abort.battleId);
	}

	private void persistTurns() {

		Connection con = null;
		PreparedStatement ps = null;
		try {

			con = config.rdsDatasource.getConnection();

			ps = con.prepareStatement("UPDATE battle SET num_turns=?, num_turns_complete=?, divergence_turn=?, diverged=? where battle_id=?");
			int index = 0;
			ps.setInt(++index, numTurns);
			ps.setInt(++index, numTurnsComplete);
			ps.setInt(++index, divergenceTurn);
			ps.setBoolean(++index, diverged);
			ps.setString(++index, battleCreateData.battleId);
			ps.executeUpdate();
			ps.close();

		} catch (SQLException e) {
			logger.error("persistTurns: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

	private void persistReadyForCleanup() {

		Connection con = null;
		PreparedStatement ps = null;
		try {

			con = config.rdsDatasource.getConnection();

			ps = con.prepareStatement("UPDATE battle SET ready_for_cleanup=? where battle_id=?");
			int index = 0;
			ps.setBoolean(++index, readyForCleanup);
			ps.setString(++index, battleCreateData.battleId);
			ps.executeUpdate();
			ps.close();

		} catch (SQLException e) {
			logger.error("persistReadyForCleanup: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

	synchronized public void depersist() throws IOException {

		final ArrayList<Object> msgs = new ArrayList<Object>();

		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = config.rdsDatasource.getConnection();

			ps = con.prepareStatement("SELECT battle_msg from battle_msg WHERE battle_id=?");
			ps.setString(1, battleCreateData.battleId);
			final ResultSet rs = ps.executeQuery();

			while (rs.next()) {
				final String jstr = rs.getString(1);
				final Object msg = JSON.parse(jstr);
				msgs.add(msg);
			}

		} catch (SQLException e) {
			logger.error("depersist: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}

		for (Object msg : msgs) {
			battleConsumer.handleMessage(msg);
		}
	}

	synchronized public void cleanupMonitor() {

		if (cleanedup) {
			return;
		}

		BattleSystem.recordBattleConcurrency();

		logger.debug("cleanupMonitor START");

		cleanedup = true;

		try {
			consumerChannel.basicCancel(monitorQueue);
		} catch (Exception e) {
			logger.warn("failed to cancel consumer");
			e.printStackTrace();
		}

		try {
			final Channel c = config.rabbit.createTemporaryChannel(this + "_delete", RabbitConfig.Consume.NO);
			c.queueDelete(monitorQueue);
			c.close();
		} catch (Exception e) {
			logger.warn("failed to delete monitor queue");
			e.printStackTrace();
		}

		try {
			chatroom.destroy();
		} catch (Exception e) {
			logger.error("failed to destroy battle chatroom");
			e.printStackTrace();
		}

		try {
			consumerChannel.close();
		} catch (Exception e) {
			logger.error("failed to close monitor channel");
			e.printStackTrace();
		}

		// rabbit.stop();

		cleanupDb();

		logger.info("cleanupMonitor FINISHED");

	}

	public static final String[] cleanup_tables = {//
	"battle_sync", "battle_move", "battle_exits", "battle_readies", "battle_surrenders", "battle_aborts", "battle_action", "battle_msg" //
	};

	private void cleanupDb() {
		logger.debug("cleanupDb START");

		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = config.rdsDatasource.getConnection();

			// keep divergences for examination
			if (!diverged) {
				for (String t : cleanup_tables) {
					ps = con.prepareStatement("DELETE FROM " + t + " WHERE battle_id=?");
					ps.setString(1, battleCreateData.battleId);
					ps.executeUpdate();
					ps.close();
				}
			}

			{
				ps = con.prepareStatement("UPDATE battle SET battle_create_data=NULL WHERE battle_id=?");
				ps.setString(1, battleCreateData.battleId);
				ps.executeUpdate();
				ps.close();
			}

		} catch (SQLException e) {
			logger.error("cleanupDb: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}

	}

	synchronized private void handleChannelCreated() throws IOException {

		monitorQueue = getMonitorQueue(battleCreateData.battleId);

		try {
			consumerChannel.exchangeDeclare(BattleSystem.EXCHANGE, "direct");
			consumerChannel.queueDeclare(monitorQueue, false, false, false, null);

			for (Object po : battleCreateData.parties) {
				BattlePartyData other = (BattlePartyData) po;
				// listen for the user sending messages on the battle exchange
				final String key = BattleSystem.getUserBattleKey(battleCreateData.battleId, other.user);
				consumerChannel.queueBind(monitorQueue, BattleSystem.EXCHANGE, key);
				consumerChannel.queueBind(monitorQueue, BattleSystem.EXCHANGE, BattleSystem.KEY_USER_ABORT_ALL_ + other.user);
			}

			consumerChannel.queueBind(monitorQueue, BattleSystem.EXCHANGE, battleCreateData.battleId);

			logger.debug("Consuming channel...");

			consumerChannel.basicConsume(monitorQueue, true, monitorQueue, battleConsumer);

			logger.debug("...Consume attached");

		} catch (Exception e) {
			logger.error("MONITOR FAILED: " + e);
			e.printStackTrace();
		}

		// final BattleNotification bn = new BattleNotification(true, null,
		// battleCreateData.getTeamMembers(null));
		// config.msg.send("amq.fanout", bn, MsgSystem.ZIP);
	}

	synchronized private void unbindUserFromBattle(final long user, final String display_name) {
		BattleSystem.unbindUserFromBattle(config.chat, user, display_name, battleCreateData);
	}

	synchronized public void setReadyForCleanup() {
		if (!readyForCleanup) {
			readyForCleanup = true;
			persistReadyForCleanup();
		}
		checkCleanup();
	}

	synchronized private void checkCleanup() {

		logger.debug("checkCleanup readyForCleanup readyForCleanup=" + readyForCleanup + " exits=" + exits.size() + "=" + Arrays.toString(exits.toArray())
				+ " parties=" + battleCreateData.parties.length);
		if (readyForCleanup && exits.size() == battleCreateData.parties.length && (aborted || finished != null)) {
			cleanupMonitor();
		}
	}

	public static String getMonitorQueue(final String battleId) {
		return "qb_" + battleId;
	}

	private void saveFirstBlood() {
		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = config.rdsDatasource.getConnection();

			// only save as abort if not already saves
			final String sql = "UPDATE `battle` SET `first_blood_time`=? WHERE `battle_id`=?";

			ps = con.prepareStatement(sql);
			ps.setLong(1, System.currentTimeMillis());
			ps.setString(2, battleCreateData.battleId);
			ps.executeUpdate();
		} catch (SQLException e) {
			logger.error("saveFirstBlood: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

	synchronized private void saveAborted() {
		if (aborted) {
			return;
		}

		logger.debug("saveAborted");

		aborted = true;
		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = config.rdsDatasource.getConnection();

			// only save as abort if not already saves
			final String sql = "UPDATE `battle` SET `end_time`=?, `aborted`=1 WHERE `battle_id`=? AND `end_time` IS NULL";

			ps = con.prepareStatement(sql);
			ps.setLong(1, System.currentTimeMillis());
			ps.setString(2, battleCreateData.battleId);
			ps.executeUpdate();
		} catch (SQLException e) {
			logger.error("saveAborted: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

	private void recordMsg(final BaseBattleData msg) {
		if (msg.battleId == null || msg.battleId.isEmpty()) {
			return;
		}

		Connection con = null;
		PreparedStatement ps = null;
		try {
			con = config.rdsDatasource.getConnection();
			ps = con.prepareStatement("INSERT INTO battle_msg (battle_id, account_id, battle_msg) VALUES (?,?,?)");
			ps.setString(1, msg.battleId);
			ps.setLong(2, msg.user);
			ps.setString(3, JSON.toString(msg));
			ps.executeUpdate();
			ps.close();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, ps);
		}
	}

	private String createAchievementProgressHandle(long account_id, AchievementType type) {
		String ret = battleCreateData.battleId + "." + String.valueOf(achievementProgressHandleIncValue) + "." + account_id + "." + type.name();
		achievementProgressHandleIncValue++;
		return ret;
	}

}