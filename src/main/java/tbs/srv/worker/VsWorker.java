package tbs.srv.worker;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;
import java.util.HashMap;
import java.util.List;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON;

import tbs.srv.battle.BattleRanking;
import tbs.srv.battle.BattleSystem;
import tbs.srv.battle.data.BattleCreateData;
import tbs.srv.battle.data.BattlePartyData;
import tbs.srv.battle.data.client.BattleAbortData;
import tbs.srv.data.EntityDef;
import tbs.srv.data.TourneyDef;
import tbs.srv.data.VsQueueData;
import tbs.srv.db.DbHelper;
import tbs.srv.db.models.SessionStartedData;
import tbs.srv.db.models.UserData;
import tbs.srv.util.BaseConfig;
import tbs.srv.util.GameConfig;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.Tourney;
import tbs.srv.util.VsType;
import tbs.srv.vs.VsSystem;
import tbs.srv.vs.data.VsCancelData;
import tbs.srv.vs.data.VsFindData;

import com.newrelic.api.agent.NewRelic;
import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;

public class VsWorker extends BaseWorker {

	private static final Logger logger = Logger.getLogger(VsWorker.class.getSimpleName());

	private Channel channel;

	public static class VsWorkerConfig extends BaseConfig {

		private static final Logger logger = Logger.getLogger(VsWorkerConfig.class.getSimpleName());

		public int VS_WINDOW_POWER_MIN = 0;
		public int VS_WINDOW_POWER_MAX = 4;

		public int VS_WINDOW_EQ_CONST = 3;
		public int VS_WINDOW_EQ_DELTA = -1;
		public int VS_WINDOW_EQ_DENOMINATOR = 3;

		public int VS_WINDOW_POWER_TIME_SECS = 90;

		public int VS_WINDOW_ELO_MIN = 4;
		public int VS_WINDOW_ELO_MAX = 4000;
		public int VS_WINDOW_ELO_TIME_SECS = 1000;
		public int VS_WINDOW_ELO_TIME_MS;

		public final int VS_BRACKET_ELO;
		public final int VS_BRACKET_POWER;

		public int VS_QUICK_ELO_DIFF = 50;

		public VsWorkerConfig() {

			super(logger);

			VS_WINDOW_POWER_MIN = getEnvInteger("VS_WINDOW_POWER_MIN", VS_WINDOW_POWER_MIN, false);
			VS_WINDOW_POWER_MAX = getEnvInteger("VS_WINDOW_POWER_MAX", VS_WINDOW_POWER_MAX, false);
			VS_WINDOW_POWER_TIME_SECS = getEnvInteger("VS_WINDOW_POWER_TIME_SECS", VS_WINDOW_POWER_TIME_SECS, false);

			VS_WINDOW_ELO_MIN = getEnvInteger("VS_WINDOW_ELO_MIN", VS_WINDOW_ELO_MIN, false);
			VS_WINDOW_ELO_MAX = getEnvInteger("VS_WINDOW_ELO_MAX", VS_WINDOW_ELO_MAX, false);
			VS_WINDOW_ELO_TIME_SECS = getEnvInteger("VS_WINDOW_ELO_TIME_SECS", VS_WINDOW_ELO_TIME_SECS, false);

			VS_WINDOW_EQ_CONST = getEnvInteger("VS_WINDOW_EQ_CONST", VS_WINDOW_EQ_CONST, false);
			VS_WINDOW_EQ_DELTA = getEnvInteger("VS_WINDOW_EQ_DELTA", VS_WINDOW_EQ_DELTA, false);
			VS_WINDOW_EQ_DENOMINATOR = getEnvInteger("VS_WINDOW_EQ_DENOMINATOR", VS_WINDOW_EQ_DENOMINATOR, false);

			VS_QUICK_ELO_DIFF = getEnvInteger("VS_QUICK_ELO_DIFF", VS_QUICK_ELO_DIFF, false);

			// a delta 200 in elo means a 75% chance to win
			VS_BRACKET_ELO = getEnvInteger("VS_BRACKET_ELO", 200, false);
			// whatever power delta means 75% chance to win (empirical)
			VS_BRACKET_POWER = getEnvInteger("VS_BRACKET_POWER", 4, false);

			logger.info("VS_WINDOW POWER " + VS_WINDOW_POWER_MIN + " -> " + VS_WINDOW_POWER_MAX + " IN " + VS_WINDOW_POWER_TIME_SECS + " sec");
			logger.info("VS_WINDOW   ELO " + VS_WINDOW_ELO_MIN + " -> " + VS_WINDOW_ELO_MAX + " IN " + VS_WINDOW_ELO_TIME_SECS + " sec");
		}
	}

	private final VsWorkerConfig vwconfig = new VsWorkerConfig();

	private static final int VS_CHECK_MS = 5000;

	public VsWorker(GameConfig config) {
		super(logger, config, VS_CHECK_MS);
	}

	@Override
	protected void startWorker() {
		try {
			initializeVs();
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(0);
		}
	}

	@Override
	protected void runWorker(final long deltaMs) {
		processMatches();
	}

	@Override
	protected void stopWorker() {

	}

	private ArrayList<VsFindEntry> vs = new ArrayList<VsFindEntry>();
	private HashMap<Long, VsFindEntry> users = new HashMap<Long, VsFindEntry>();

	private static class VsFindEntry {
		VsFindData data;
		public String display_name;
		public int power;
		public int battle_count;
		public int threshold_power;
		public int threshold_elo;
		public EntityDef[] partydefs;
		final public long startTime = System.currentTimeMillis();
		final private VsWorkerConfig config;
		public String battle_id;
		public int elo;

		public static class BadEntryException extends Exception {
			/**
			 * 
			 */
			private static final long serialVersionUID = 1L;

			public BadEntryException(String msg) {
				super(msg);
			}

		}

		public String toString() {
			return data.toString() + " p=" + power + " elo=" + elo;
		}

		public VsFindEntry(VsWorkerConfig config, VsFindData data) throws BadEntryException {

			this.config = config;

			if (data.type.equalPower) {
				this.threshold_power = 0;
			} else {
				this.threshold_power = config.VS_WINDOW_POWER_MIN;
			}

			if (data.type.eloWindow) {
				this.threshold_elo = config.VS_WINDOW_ELO_MIN;
			} else {
				this.threshold_elo = Integer.MAX_VALUE;
			}

			this.data = data;

			this.display_name = data.display_name;
			this.battle_count = UserData.getBattleCount(data.user);

			if (data.partyIds.length == 0) {
				throw new BadEntryException("Can't really go to battle without a party");
			}

			partydefs = new EntityDef[data.partyIds.length];

			if (data.type.eloWindow) {
				final BattleRanking rnk = BattleRanking.get(data.user, data.tourney_id, true);
				this.elo = rnk.elo;
			} else {
				this.elo = 0;
			}

			for (int i = 0; i < data.partyIds.length; ++i) {
				final String pid = (String) data.partyIds[i];
				try {
					final EntityDef def = UserData.loadRosterUnit(data.user, pid);
					if (def == null) {
						throw new BadEntryException("No such roster member " + pid);
					}

					partydefs[i] = def;
					power += def.getPower();

				} catch (SQLException e) {
					throw new BadEntryException("Failed to load unit " + pid + ": " + e);
				}
			}

			if (data.tourney_id > 0) {
				final Tourney t = Tourney.get(data.tourney_id);
				if (t != null) {
					final TourneyDef td = t.def;
					if (td.power_requirement != power) {
						throw new BadEntryException("Incorrect tourney power " + power + ", tourney: " + t + ", requirement: " + td.power_requirement);
					}
				}
			}

			logger.info("VsFindEntry CREATED " + this);
			logger.info("VsFindEntry PARTY " + data.user + "/" + data.session_key + "/h=" + data.match_handle + " " + Arrays.toString(data.partyIds));

		}

		private int bumpThreshold(final long elapsed_ms, final int cur, final int min, final int max, final int duration_ms, final String name) {

			// negatives are infinite and don't bump
			if (cur < 0) {
				return cur;
			}

			final int range = max - min;

			final int now = Math.min(max, min + (int) (range * elapsed_ms / duration_ms));
			if (now != cur) {
				logger.debug("Threshold BUMPED " + name + " " + now + ": " + this);
			}
			return now;
		}

		public void bumpThresholds(final long currentTime) {

			final int delta = (int) (currentTime - startTime);

			if (!data.type.equalPower) {
				final int eq = config.VS_WINDOW_EQ_CONST + (this.power + config.VS_WINDOW_EQ_DELTA) / config.VS_WINDOW_EQ_DENOMINATOR;
				final int powermax = //
				Math.max(config.VS_WINDOW_POWER_MIN, //
						Math.min(config.VS_WINDOW_POWER_MAX, //
								eq));

				threshold_power = bumpThreshold(delta, threshold_power, config.VS_WINDOW_POWER_MIN, powermax, config.VS_WINDOW_POWER_TIME_SECS * 1000, "power");
			}

			if (data.type.eloWindow) {
				threshold_elo = bumpThreshold(delta, threshold_elo, config.VS_WINDOW_ELO_MIN, config.VS_WINDOW_ELO_MAX, config.VS_WINDOW_ELO_TIME_SECS * 1000,
						"Elo");
			}
		}

		// private static final long TIME_EXPIRING = 10 * 1000;
		// private static final long TIME_EXPIRED = 30 * 1000;

		public boolean isExpiring(long current) {
			// TODO check this vs. the session keepalive, not a vs-specific one
			return false;
		}

		public boolean isExpired(long current) {
			// TODO check this vs. the session keepalive, not a vs-specific one
			return false;
		}
	}

	private void purgePersistedVs() {

		logger.info("purgePersistedVs");

		Connection con = null;
		PreparedStatement s = null;

		int count = 0;

		try {
			con = WorkerConfig.instance.rdsDatasource.getConnection();
			con.setAutoCommit(false);
			s = con.prepareStatement("UPDATE `vs_find` SET `vs_end_time`=?, `vs_serverstopped`=? WHERE `vs_end_time` IS NULL AND `vs_serverstopped` IS NULL");
			s.setLong(1, System.currentTimeMillis());
			s.setBoolean(2, true);
			s.execute();
			s.close();

			s = con.prepareStatement("REPLACE INTO vs_find_history SELECT * from vs_find");
			s.execute();
			s.close();

			s = con.prepareStatement("DELETE FROM vs_find");
			count = s.executeUpdate();
			s.close();

			con.setAutoCommit(true);

		} catch (SQLException e) {

			try {
				con.rollback();
			} catch (SQLException e1) {
				// TODO Auto-generated catch block
				e1.printStackTrace();
			}
			logger.error("purgePersistedVs: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		logger.info("purgePersistedVs PURGED " + count);

	}

	private void reloadPersistedVs() {
		Connection con = null;
		PreparedStatement s = null;

		ArrayList<String> vs_data_strs = new ArrayList<String>();

		try {
			con = WorkerConfig.instance.rdsDatasource.getConnection();
			s = con.prepareStatement("SELECT * FROM `vs_find` WHERE `vs_end_time` IS NULL AND `vs_serverstopped` IS NULL");
			final ResultSet rs = s.executeQuery();

			while (rs.next()) {
				long session_key = 0;
				int match_handle = 0;
				try {
					session_key = rs.getLong("session_key");
					match_handle = rs.getInt("vs_match_handle");
					final String vs_data = rs.getString("vs_data");
					vs_data_strs.add(vs_data);

					logger.info("reloadPersistedVs DEPERSIST " + session_key + "/" + match_handle);
				} catch (Exception e) {
					logger.error("Failed to depersist " + session_key + "/" + match_handle + ": " + e);
					e.printStackTrace();
				}
			}
			s.close();
		} catch (SQLException e) {
			logger.error("reloadPersistedVs: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		for (String vs_data : vs_data_strs) {
			try {
				final VsFindData vfd = (VsFindData) JSON.parse(vs_data);
				logger.info("reloadPersistedVs RECREATE " + vfd);
				handleFind(vfd, false);
			} catch (Exception e) {
				logger.error("Failed to RE-VS " + vs_data);
				e.printStackTrace();
			}
		}
	}

	private void setupVsChannel() throws IOException {

		channel = GameConfig.instance.rabbit.createChannel(this);

		channel.queueDeclare(QUEUE, false, false, false, null);

		channel.exchangeDeclare(VsSystem.EXCHANGE, "direct");

		channel.queueBind(QUEUE, VsSystem.EXCHANGE, VsSystem.KEY_FIND);
		channel.queueBind(QUEUE, VsSystem.EXCHANGE, VsSystem.KEY_CANCEL);
		channel.queueBind(QUEUE, "amq.direct", SessionStartedData.KEY);

		logger.info("basicConsume " + queueConsumer);
		final String tag = channel.basicConsume(QUEUE, true, "vs_consumer", queueConsumer);

		logger.info("setupVsChannel CONSUMER " + tag);
	}

	private void initializeVs() throws IOException {

		if (WorkerConfig.instance.GAME_REBOOTING) {
			purgePersistedVs();
		} else {
			reloadPersistedVs();
			setupVsChannel();
		}
	}

	private static final String QUEUE = "q_vs";

	DefaultConsumer queueConsumer = new DefaultConsumer(channel) {
		@Override
		public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {

			try {
				if (envelope != null) {
					logger.debug("handleDelivery ENVELOPE " + envelope.getRoutingKey() + "/" + envelope.getDeliveryTag());
				} else {
					logger.warn("handleDelivery NO-ENVELOPE");
				}

				final Object data = MsgSystem.parseResponseConsume(body, properties, consumerTag);

				logger.debug("handleDelivery DATA " + data);

				if (data instanceof VsFindData) {
					handleFind((VsFindData) data, true);
				} else if (data instanceof VsCancelData) {
					evictUser((VsCancelData) data);
					noticeCancel((VsCancelData) data);
				} else if (data instanceof SessionStartedData) {
					handleSessionStartedData((SessionStartedData) data);
				} else {
					logger.error("handleDelivery UNKNOWN " + data + ", envelope=" + envelope);
				}
			} catch (Exception exp) {
				logger.error("EXCEPTION " + exp);
				exp.printStackTrace();
			}
		}
	};

	private void handleSessionStartedData(final SessionStartedData data) {

		for (VsType type : queueDataTypes) {
			VsQueueData vqd = constructVsQueueData(0, type);
			GameConfig.instance.msg.send("", vqd, MsgSystem.ZIP, MsgSystem.getUserQueue(data.account_id)); // to client
		}
	}

	private VsQueueData constructVsQueueData(final long account_id, final VsType type) {

		HashMap<Integer, Integer> counts = new HashMap<Integer, Integer>();
		for (VsFindEntry e : vs) {
			if (e.data.type != type) {
				continue;
			}
			if (e.data.forcematch > 0) {
				continue;
			}

			Integer p = Integer.valueOf(e.power);
			Integer c = Integer.valueOf(0);
			if (counts.containsKey(p)) {
				c = counts.get(p);
			}

			c = Integer.valueOf(c.intValue() + 1);

			counts.put(p, c);
		}

		Object[] pa = counts.keySet().toArray();
		Object[] ca = counts.values().toArray();

		return new VsQueueData(type.name(), account_id, pa, ca);
	}

	private int matching = 0;
	private ArrayList<VsCancelData> cancelsWhileMatching = new ArrayList<VsCancelData>();

	private void incrementMatching() {
		synchronized (cancelsWhileMatching) {
			++matching;
		}
	}

	private void decrementMatching() {
		synchronized (cancelsWhileMatching) {
			--matching;

			matching = Math.max(0, matching);
			if (matching == 0) {

				for (VsCancelData msg : cancelsWhileMatching) {
					// if we are canceling, we don't know the battle id
					BattleSystem.send(new BattleAbortData(msg.user, (String) null, msg.match_handle));
				}

				cancelsWhileMatching.clear();
			}
		}
	}

	private void noticeCancel(final VsCancelData msg) {

		noticeVsCancelCount(msg.user);

		synchronized (cancelsWhileMatching) {
			if (matching > 0) {
				cancelsWhileMatching.add(msg);
				return;
			}
		}

		BattleSystem.send(new BattleAbortData(msg.user, (String) null, msg.match_handle));
	}

	private void saveVsFindStart(final VsFindEntry entry) {
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = WorkerConfig.instance.rdsDatasource.getConnection();
			s = con.prepareStatement("REPLACE INTO `vs_find` (`session_key`, `vs_match_handle`, `account_id`, `vs_start_time`, `elo`, `vs_power`, `vs_data`, `timer`, `scene`, `friendly`, `tourney_id`, `vs_type`) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)");
			int index = 0;
			s.setLong(++index, entry.data.session_key);
			s.setInt(++index, entry.data.match_handle);
			s.setLong(++index, entry.data.user);
			s.setLong(++index, entry.startTime);
			s.setInt(++index, entry.elo);
			s.setInt(++index, entry.power);
			final String json = JSON.toString(entry.data);
			s.setString(++index, json);
			s.setInt(++index, entry.data.timer);
			s.setString(++index, entry.data.scene);
			s.setBoolean(++index, entry.data.type == VsType.FRIEND);
			s.setInt(++index, entry.data.tourney_id);
			s.setInt(++index, entry.data.type.ordinal());
			s.executeUpdate();
			s.close();
		} catch (SQLException e) {
			logger.error("saveVsFindStart: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	private void saveVsFindStop(final VsFindEntry entry) {
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = WorkerConfig.instance.rdsDatasource.getConnection();
			con.setAutoCommit(false);

			int index = 0;

			s = con.prepareStatement("REPLACE INTO vs_find_history SELECT * FROM vs_find WHERE `session_key`=? AND `vs_match_handle`=?");
			index = 0;
			s.setLong(++index, entry.data.session_key);
			s.setInt(++index, entry.data.match_handle);
			s.execute();
			s.close();

			s = con.prepareStatement("DELETE FROM vs_find where `session_key`=? AND `vs_match_handle`=?");
			index = 0;
			s.setLong(++index, entry.data.session_key);
			s.setInt(++index, entry.data.match_handle);
			s.execute();
			s.close();

			s = con.prepareStatement("UPDATE `vs_find_history` SET `vs_end_time`=?, `vs_battle_id`=? WHERE `session_key`=? AND `vs_match_handle`=?");
			index = 0;
			s.setLong(++index, System.currentTimeMillis());
			s.setString(++index, entry.battle_id);
			s.setLong(++index, entry.data.session_key);
			s.setInt(++index, entry.data.match_handle);
			s.executeUpdate();
			s.close();

			con.setAutoCommit(true);

		} catch (SQLException e) {
			try {
				con.rollback();
			} catch (SQLException e1) {
				// TODO Auto-generated catch block
				e1.printStackTrace();
			}
			logger.error("saveVsFindStop: " + e);
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}
	}

	private int findCount = 0;

	synchronized private void handleFind(VsFindData find, final boolean checkImmediately) {

		++findCount;

		logger.debug("handleFind " + findCount + " " + find);

		evictUser(find.user, 0);

		VsFindEntry entry = null;

		if (find.tourney_id > 0) {
			final Tourney t = Tourney.get(find.tourney_id);
			if (t == null) {
				logger.warn("User " + find.user + " no such tourney " + find.tourney_id);
				return;
			}
			if (!t.canUserBattle(find.user)) {
				logger.warn("User " + find.user + " cannot battle in tourney " + t);
				return;
			}
		}
		try {
			entry = new VsFindEntry(vwconfig, find);
		} catch (tbs.srv.worker.VsWorker.VsFindEntry.BadEntryException e) {
			logger.error("Unable to start find for " + find + ": " + e.getMessage());
			// e.printStackTrace();
			return;
		}

		noticeVsStartCount(entry);

		saveVsFindStart(entry);
		// TODO start with a low threshold and retry later

		if (checkImmediately) {
			final long cur = new Date().getTime();
			VsFindEntry match = findBestMatch(entry, 0, cur);
			if (match != null) {
				logger.info("FOUND IMMEDIATELY " + entry.data + " vs. " + match.data);
				if (createMatchWrapper(entry, match, false)) {
					return;
				}
			}
		}

		// no match now, wait for later
		if (users.containsKey(entry.data.user)) {
			vs.remove(entry);
		}

		users.put(entry.data.user, entry);
		vs.add(entry);
		logger.info("WAITING for " + entry);

		broadcastVsQueueData(entry.data.user, entry.data.type);
	}

	private List<VsType> queueDataTypes = Arrays.asList(new VsType[] { VsType.QUICK, VsType.RANKED, VsType.TOURNEY });

	private void broadcastVsQueueData(final long account_id, VsType type) {

		if (!queueDataTypes.contains(type)) {
			return;
		}
		VsQueueData vqd = constructVsQueueData(account_id, type);
		GameConfig.instance.msg.send("amq.fanout", vqd, MsgSystem.ZIP); // to client
	}

	private boolean evictUser(final VsCancelData msg) {
		return evictUser(msg.user, msg.match_handle);
	}

	private boolean evictUser(final long user, final int match_handle) {

		VsFindEntry entry = users.get(user);

		if (entry != null) {
			if (entry.data.match_handle == match_handle || match_handle == 0) {
				return evictEntry(entry);
			}
		}
		return false;
	}

	synchronized private boolean evictEntry(final VsFindEntry entry) {

		if (entry != null) {
			users.remove(entry.data.user);
			// logger.debug("EVICT " + user);
			boolean result = vs.remove(entry);
			saveVsFindStop(entry);
			broadcastVsQueueData(entry.data.user, entry.data.type);
			return result;
		}
		return false;
	}

	private boolean createMatchWrapper(VsFindEntry v0, VsFindEntry v1, final boolean evict0) {
		incrementMatching();
		final boolean result = createMatch(v0, v1, evict0);
		decrementMatching();
		return result;
	}

	private boolean createMatch(VsFindEntry v0, VsFindEntry v1, final boolean evict0) {

		String scene = v0.data.scene;
		if (scene == null) {
			scene = v1.data.scene;
		}

		BattlePartyData[] parties = new BattlePartyData[2];
		final String team0 = Long.toString(v0.data.user);
		final String team1 = Long.toString(v1.data.user);
		parties[0] = new BattlePartyData(v0.data.user, team0, v0.display_name, v0.partydefs, v0.data.match_handle, 0, v0.elo, v0.power, v0.data.session_key,
				v0.battle_count, v0.data.timer, v0.data.tourney_id, v0.data.type);
		parties[1] = new BattlePartyData(v1.data.user, team1, v1.display_name, v1.partydefs, v1.data.match_handle, 1, v1.elo, v1.power, v1.data.session_key,
				v1.battle_count, v1.data.timer, v1.data.tourney_id, v1.data.type);

		final boolean friendly = v0.data.type == VsType.FRIEND && v1.data.type == VsType.FRIEND;
		final int tourney_id = v0.data.tourney_id > 0 ? v0.data.tourney_id : v1.data.tourney_id;
		BattleCreateData bcd;
		try {
			bcd = WorkerConfig.instance.battle.createBattle(WorkerConfig.instance.msg, scene, friendly, tourney_id, parties);
		} catch (Exception e) {
			e.printStackTrace();
			return false;
		}

		// only notice the one, the metrics knows that this means 2 ppl matched
		noticeVsMatchCount(v0, v1);

		if (bcd == null) {
			logger.error("FAILED TO BATTLE " + v0 + " vs. " + v1);
			return false;
		}

		v0.battle_id = bcd.battleId;
		v1.battle_id = bcd.battleId;

		boolean ok = true;

		if (!evictEntry(v0)) {
			if (evict0) {
				logger.error("createMatch failed to evict " + v0);
				ok = false;
			}
		}

		if (!evictEntry(v1)) {
			logger.error("createMatch failed to evict " + v1);
			ok = false;
		}

		return ok;
	}

	public class VsBestMatchComparator implements Comparator<VsFindEntry> {

		public final static int MULT = 100;

		@Override
		public int compare(VsFindEntry o1, VsFindEntry o2) {
			final int dElo = (o1.elo > 0 && o2.elo > 0) ? MULT * (o1.elo - o2.elo) / vwconfig.VS_BRACKET_ELO : 0;
			final int dPower = MULT * (o1.power - o2.power) / vwconfig.VS_BRACKET_POWER;
			final int dTimer = MULT * (o1.data.timer - o2.data.timer) / 30;

			int d = (dElo + dPower + dTimer);
			if (o1.data.type != o2.data.type) {
				d += (d > 0) ? 1 : -1;
			}

			logger.debug("VsBestMatchComparator d=" + d + ", dElo=" + dElo + ", dPower=" + dPower + ", dTimer=" + dTimer + ", " + o1 + " VS " + o2);
			return d;
		}
	}

	private enum ForceMatchPossibility {
		ALLOWED, REQUIRED, FORBIDDEN
	}

	private ForceMatchPossibility checkForceMatch(final VsFindEntry lhs, final VsFindEntry rhs) {

		if (lhs.data.forcematch == 0 && rhs.data.forcematch == 0) {
			return ForceMatchPossibility.ALLOWED;
		}

		// left wants someone
		if (lhs.data.forcematch != 0) {
			// left wants right
			if (lhs.data.forcematch == rhs.data.user) {
				if (rhs.data.forcematch == 0 || rhs.data.forcematch == lhs.data.user) {
					// right either wants left or doesn't care
					return ForceMatchPossibility.REQUIRED;
				}
			}

			return ForceMatchPossibility.FORBIDDEN;
		}

		// right wants someone
		if (rhs.data.forcematch != 0) {
			// right wants left
			if (lhs.data.forcematch == rhs.data.user) {
				if (rhs.data.forcematch == 0 || rhs.data.forcematch == lhs.data.user) {
					// right either wants left or doesn't care
					return ForceMatchPossibility.REQUIRED;
				}
			}
			return ForceMatchPossibility.FORBIDDEN;
		}

		return ForceMatchPossibility.ALLOWED;

	}

	synchronized private VsFindEntry findBestMatch(VsFindEntry entry, int from, long currentTime) {

		int bestDifference = Integer.MAX_VALUE;
		VsFindEntry best = null;

		// first filter and check for forcematch

		final VsBestMatchComparator comparator = new VsBestMatchComparator();

		for (VsFindEntry other : vs) {
			// don't play with yourself
			if (entry.data.user == other.data.user) {
				continue;
			}

			if (entry.isExpiring(currentTime)) {
				// ignore because keepalive is fading
				continue;
			}

			if (entry.data.tourney_id != other.data.tourney_id) {
				continue;
			}

			final ForceMatchPossibility pos = checkForceMatch(entry, other);
			if (pos == ForceMatchPossibility.REQUIRED) {
				logger.info("FORCEMATCHING " + entry + " vs. " + other);
				return other;
			} else if (pos == ForceMatchPossibility.FORBIDDEN) {
				// can't match with this dude
				continue;
			}

			if (!GameConfig.instance.KIOSK) {
				if (!checkWindows(entry, other)) {
					continue;
				}
			}

			final int difference = Math.abs(comparator.compare(entry, other));
			if (difference < bestDifference) {
				best = other;
				bestDifference = difference;
			}
		}

		return best;
	}

	private boolean checkWindows(final VsFindEntry entry, final VsFindEntry other) {
		// hard window on power difference
		final int powerDifference = Math.abs(entry.power - other.power);
		if (powerDifference > entry.threshold_power || powerDifference > other.threshold_power) {
			return false;
		}

		// hard window on elo difference
		final int eloDifference = (entry.elo > 0 && other.elo > 0) ? Math.abs(entry.elo - other.elo) : vwconfig.VS_QUICK_ELO_DIFF;

		if (eloDifference > entry.threshold_elo || eloDifference > other.threshold_elo) {
			return false;
		}
		return true;
	}

	private void noticeVsStartCount(final VsFindEntry v) {

		NewRelic.incrementCounter("Custom/vs/change/start/type/" + v.data.type.name());
		NewRelic.incrementCounter("Custom/vs/change/total/start");
	}

	private void noticeVsCancelCount(final long account_id) {

		final VsFindEntry v = users.get(account_id);

		if (v == null) {
			return;
		}

		NewRelic.incrementCounter("Custom/vs/change/cancel/type/" + v.data.type.name());
		NewRelic.incrementCounter("Custom/vs/change/total/cancel");

		if (v != null) {
			final long cur = System.currentTimeMillis();
			final long delay = cur - v.startTime;
			NewRelic.recordMetric("Custom/vs/delay/cancel", delay);
		}

	}

	private void noticeVsMatchCount(final VsFindEntry... v) {

		final long cur = System.currentTimeMillis();
		long delay = 0;
		for (int i = 0; i < v.length; ++i) {
			delay += cur - v[i].startTime;
		}

		delay /= v.length;

		NewRelic.incrementCounter("Custom/vs/change/match/type/" + v[0].data.type.name(), v.length);
		NewRelic.recordMetric("Custom/vs/delay/match/type/" + v[0].data.type.name(), delay);

		NewRelic.incrementCounter("Custom/vs/change/total/match", v.length);
		NewRelic.recordMetric("Custom/vs/delay/total/match", delay);
	}

	private int[] last_type_counts = new int[VsType.values().length];
	private int last_total = 0;
	private long last_update = 0;
	private final static long LAST_UPDATE_THRESHOLD = 45000;

	synchronized private void noticeVsCurCounts(final int[] type_counts) {

		final long cur = System.currentTimeMillis();
		final long elapsed = cur - last_update;
		final boolean force = elapsed > LAST_UPDATE_THRESHOLD;

		int total = 0;
		for (int i = 0; i < type_counts.length; ++i) {
			final int c = type_counts[i];
			final int last = last_type_counts[i];

			total += c;

			if (force || last != c) {
				last_type_counts[i] = c;
				final VsType t = VsType.values()[i];
				NewRelic.recordMetric("Custom/vs/waiting/type/" + t.name(), c);
			}
		}

		if (force || last_total != total) {
			last_total = total;
			NewRelic.recordMetric("Custom/vs/waiting/total", total);
		}

		if (force) {
			last_update = cur;
		}
	}

	synchronized private void processMatches() {

		// logger.debug("processMatches " + vs.size());

		final long currentTime = System.currentTimeMillis();

		VsFindEntry oldEntry = null;

		boolean changed = false;

		int[] type_counts = new int[VsType.values().length];

		for (int i = 0; i < vs.size();) {
			final VsFindEntry entry = vs.get(i);

			++type_counts[entry.data.type.ordinal()];

			final long deltaTime = System.currentTimeMillis() - currentTime;

			if (deltaTime > (20 * 1000)) {
				logger.error("processMatches EXTRALONG LOOP! " + deltaTime);
				break;
			}

			if (oldEntry == entry) {
				logger.error("INFINITE LOOP on " + i + " " + entry);
				break;
			}

			if (entry.isExpired(currentTime)) {
				logger.info("EXPIRED " + entry);

				if (evictEntry(entry)) {
					changed = true;
					// go back around with the same index
					continue;
				}
			} else if (!entry.isExpiring(currentTime)) {
				final VsFindEntry match = findBestMatch(entry, i + 1, currentTime);
				if (match != null) {
					if (createMatchWrapper(entry, match, true)) {
						changed = true;
						// go back around with the same index
						continue;
					}
				}
				entry.bumpThresholds(currentTime);
			}
			++i;
		}

		noticeVsCurCounts(type_counts);

		if (changed) {
			BattleSystem.recordBattleConcurrency();
		}
	}
}
