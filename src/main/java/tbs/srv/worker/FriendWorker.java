package tbs.srv.worker;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

import org.apache.log4j.Logger;

import tbs.srv.auth.AccountData;
import tbs.srv.data.FriendData;
import tbs.srv.data.FriendOnlineData;
import tbs.srv.data.FriendsData;
import tbs.srv.data.GameLocationData;
import tbs.srv.db.DbHelper;
import tbs.srv.util.FriendSystem;
import tbs.srv.util.GameConfig;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.RabbitConfig;
import tbs.srv.util.steam.Steam;
import tbs.srv.util.steam.SteamFriend;
import tbs.srv.util.steam.SteamPlayerSummary;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;

public class FriendWorker extends BaseWorker {

	private static final String QUEUE = "q_friend";
	private static final Logger logger = Logger.getLogger(FriendWorker.class.getSimpleName());

	private boolean FRIEND_WORKER_ENABLED = true;

	//

	public FriendWorker(GameConfig config) throws IOException {
		super(logger, config, 0);

		FRIEND_WORKER_ENABLED = config.getEnvBoolean("FRIEND_WORKER_ENABLED", FRIEND_WORKER_ENABLED, false);
	}

	private Object[] updateSteamFriends(final long account_id, final long steam_id) throws InterruptedException {

		if (steam_id <= 0) {
			logger.error("updateSteamFriends invalid steam id");
			return null;
		}

		final List<SteamFriend> sfs = Steam.SteamUser.getFriendListRetry(steam_id);

		if (sfs == null) {
			logger.warn("updateSteamFriends unable to load friends list for " + steam_id);
			return null;
		}

		long[] ids = new long[sfs.size()];
		for (int i = 0; i < ids.length; ++i) {
			final SteamFriend sf = sfs.get(i);
			ids[i] = sf.steamid;
		}

		final HashMap<Long, FriendData> steamId2friends = new HashMap<Long, FriendData>();
		final HashMap<Long, FriendData> steamId2tbsfriends = new HashMap<Long, FriendData>();

		final List<SteamPlayerSummary> sums = Steam.SteamUser.getPlayerSummariesRetry(ids);

		if (sums == null) {
			logger.warn("Unable to load steam player summaries for " + Arrays.toString(ids));
			return null;
		}

		final long[] steam_ids = new long[sums.size()];
		for (int i = 0; i < sums.size(); ++i) {
			final SteamPlayerSummary sps = sums.get(i);
			steam_ids[i] = sps.steamid;

			final FriendData friend = new FriendData(sps);
			steamId2friends.put(friend.steam_id, friend);
		}

		Connection con = null;
		PreparedStatement ps = null;
		
		if (steam_ids.length > 0) {
			try {

				con = config.rdsDatasource.getConnection();
				{

					StringBuilder sql = new StringBuilder(
							"" //
									+ "select t1.`account_id` account_id, t1.`steam_id` steam_id, t2.session_key session_key, t3.`game_location` game_location, friend_battle_record.wins_0, friend_battle_record.wins_1, friend_battle_record.last_time " //
									+ "from `auth_account` as t1 " //
									+ "left join (`session` as t2, `account_info` as t3, friend_battle_record) " //
									+ "on (t1.account_id = t2.account_id AND t1.account_id = t3.account_id AND friend_battle_record.account_id_0=? AND friend_battle_record.account_id_1=t1.account_id) " //
									+ "where t1.`steam_id` IN (?");

					for (int i = 1; i < steam_ids.length; ++i) {
						sql.append(",?");
					}

					sql.append(")");

					ps = con.prepareStatement(sql.toString());

					ps.setLong(1, account_id);

					for (int i = 0; i < steam_ids.length; ++i) {
						ps.setLong(1 + i + 1, steam_ids[i]);
					}
					final ResultSet rs = ps.executeQuery();
					while (rs.next()) {
						final long other_steam_id = rs.getLong("steam_id");

						final FriendData friend = steamId2friends.get(other_steam_id);

						if (friend != null) {
							friend.id = rs.getLong("account_id");
							friend.online = rs.getBoolean("session_key");
							friend.location = rs.getString("game_location");
							friend.wins = rs.getInt("wins_0");
							friend.losses = rs.getInt("wins_1");
							friend.last_battle_time = rs.getLong("last_time");
							steamId2tbsfriends.put(friend.steam_id, friend);
						}
					}
					ps.close();
				}

			} catch (SQLException e) {
				e.printStackTrace();
			} finally {
				DbHelper.cleanup(con, ps);
			}
		}
		
		return steamId2tbsfriends.values().toArray();
	}

	private void handleGameLocation(final GameLocationData gld) {
		Connection con = null;
		PreparedStatement s = null;
		try {
			con = WorkerConfig.instance.rdsDatasource.getConnection();
			final String sql = "UPDATE `account_info` SET `game_location`=? WHERE `account_id` = ?";
			s = con.prepareStatement(sql);
			s.setString(1, gld.location);
			s.setLong(2, gld.account_id);
			s.executeUpdate();
			s.close();
		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

	}

	private void handleCollectFriends(final long account_id) {

		new Thread() {

			@Override
			public void run() {
				try {
					Thread.sleep(500);
					doCollectFriends(account_id);
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}.start();

	}

	private void doCollectFriends(final long account_id) throws InterruptedException {

		final long start = System.currentTimeMillis();

		final AccountData account = AccountData.getAccount(config.rdsDatasource, account_id);

		if (account == null) {
			logger.error("Unable to load account " + account_id);
			return;
		}

		if (account.steam_id == 0) {
			// no friends
			return;
		}

		final Object[] steam_friends = updateSteamFriends(account_id, account.steam_id);

		if (steam_friends == null) {
			logger.warn("doCollectFriends NO FRIENDS FOR " + account_id);
			return;
		}

		// all friends must have a unique id, so simply assign negative ordinals
		for (int i = 0; i < steam_friends.length; ++i) {
			final FriendData f = (FriendData) steam_friends[i];
			if (f.id == 0) {
				f.id = -(i + 1);
			}
		}

		final long delta = System.currentTimeMillis() - start;
		logger.info("handleCollectFriends " + account_id + " count " + steam_friends.length + " duration " + delta);

		try {
			final Channel channel = GameConfig.instance.rabbit.createTemporaryChannel(this, RabbitConfig.Consume.NO);
			final String q = MsgSystem.getUserQueue(account_id);
			// MsgSystem.declareUserQueue(channel, q, false);
			final FriendsData msg = new FriendsData();
			msg.friends = steam_friends;

			final FriendOnlineData fod = new FriendOnlineData(account_id, true);

			for (Object fo : steam_friends) {
				final FriendData fd = (FriendData) fo;
				if (fd.id > 0) {
					final String key = FriendSystem.getFriendKey(fd.id);
					logger.debug("friend listening " + q + " to " + key);
					// bind this user to the friend
					channel.queueBind(q, "amq.direct", key);

					MsgSystem.send(channel, "", fod, MsgSystem.ZIP, MsgSystem.getUserQueue(fd.id));
				}
			}
			MsgSystem.send(channel, "", msg, MsgSystem.ZIP, q);
			channel.close();
		} catch (Exception e) {
			logger.warn("Unable to bind user to friends: " + account_id + ": " + e);
			// e.printStackTrace();
		}
	}

	@Override
	protected void startWorker() throws IOException {
		final Channel channel = GameConfig.instance.rabbit.createChannel(this);
		channel.queueDeclare(QUEUE, true, false, false, null);
		channel.queueBind(QUEUE, "amq.direct", FriendSystem.KEY_COLLECT);
		channel.queueBind(QUEUE, "amq.direct", FriendSystem.KEY_LOCATION);

		final String tag = channel.basicConsume(QUEUE, true, "friend_consumer", new DefaultConsumer(channel) {
			@Override
			public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) {

				if (envelope.getRoutingKey().equals(FriendSystem.KEY_COLLECT)) {
					final long account_id = Long.parseLong(new String(body));
					if (FRIEND_WORKER_ENABLED) {
						handleCollectFriends(account_id);
					}
				} else if (envelope.getRoutingKey().equals(FriendSystem.KEY_LOCATION)) {
					final GameLocationData gld = (GameLocationData) MsgSystem.parseResponseConsume(body, properties, consumerTag);
					handleGameLocation(gld);
				}
			}
		});

		logger.info("startWorker CONSUMER " + tag);
	}

	@Override
	protected void runWorker(long deltaMs) {
	}

	@Override
	protected void stopWorker() {

	}
}
