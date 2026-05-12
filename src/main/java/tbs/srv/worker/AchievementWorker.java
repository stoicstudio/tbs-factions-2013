package tbs.srv.worker;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;

import org.apache.log4j.Logger;

import tbs.srv.auth.AccountData;
import tbs.srv.battle.BattleSystem;
import tbs.srv.db.models.SessionStartedData;
import tbs.srv.db.models.UserData;
import tbs.srv.util.AchievementListItemDef;
import tbs.srv.util.AchievementProgressData;
import tbs.srv.util.AchievementSystem;
import tbs.srv.util.AchievementType;
import tbs.srv.util.GameConfig;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.steam.Steam;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.DefaultConsumer;
import com.rabbitmq.client.Envelope;

public class AchievementWorker extends BaseWorker {

	private static final String QUEUE = "q_achievement";
	private static final Logger logger = Logger.getLogger(AchievementWorker.class.getSimpleName());

	public AchievementWorker(GameConfig config) throws IOException {
		super(logger, config, 0);

	}

	@Override
	protected void startWorker() throws Exception {

		final Channel channel = GameConfig.instance.rabbit.createChannel(this);
		logger.debug("ENTER AchievementWorker.startWorker()");

		channel.queueDeclare(QUEUE, true, false, false, null);
		channel.queueBind(QUEUE, "amq.direct", AchievementSystem.ACHIEVEMENT_UPDATE_PROGRESS);
		channel.queueBind(QUEUE, "amq.direct", SessionStartedData.KEY);

		channel.basicConsume(QUEUE, true, "achievement_consumer", new DefaultConsumer(channel) {
			@Override
			public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {

				logger.debug("ENTER AchievementWorker.handleDelivery()");

				Object data = MsgSystem.parseResponseConsume(body, properties, consumerTag);

				if (data instanceof AchievementProgressData) {
					handleAchievementProgressData((AchievementProgressData) data);
				} else if (data instanceof SessionStartedData) {
					handleSessionStartedData((SessionStartedData) data);
				}
			}

		});

	}

	private void handleSessionStartedData(final SessionStartedData data) {
		updateAllAchievements(data.account_id, data.session_key);
	}

	private void handleAchievementProgressData(AchievementProgressData achievementProgressData) {

		logger.debug("handleAchievementProgressData got " + achievementProgressData);

		/*
		 * TEST, // BATTLES, // ELO, // KILLS, // WINS;
		 */
		switch (achievementProgressData.achievement_type) {
		case BATTLES:
		case KILLS:
		case WINS: {
			if (!handleAchievementIncrement(achievementProgressData)) {

				logger.debug("AchievementWorker.handleAchievementIncrement returned false");
			}
		}
			break;
		case UNIT_KILL:
		case STREAK:
		case ELO: {
			if (!handleAchievementUpdate(achievementProgressData)) {

				logger.debug("AchievementWorker.handleAchievementUpdate returned false");
			}
		}
			break;
		default: {
			logger.debug("AchievementWorker unknown achievement type = " + achievementProgressData.achievement_type.toString());
		}
			break;
		}
	}

	private ArrayList<String> checkForAchievements(//
			final long account_id, final long session_key, final AchievementType[] types, final int[] newValues, final boolean force) {

		final ArrayList<String> achievementsEarned = new ArrayList<String>();

		final ArrayList<String> achievementsOwned = UserData.getAchievements(config, account_id);
		final HashSet<String> achievementsProcessed = new HashSet<String>();

		final int numAchievementDefs = config.achievement_list.numItems();
		// this is retro active so new achievements can be added with count requirements lower than what has been accumlated already.

		logger.debug("checkForAchievements " + numAchievementDefs + " account=" + account_id + " types=" + Arrays.toString(types) + " values="
				+ Arrays.toString(newValues) + " force=" + force);

		for (int j = 0; j < types.length; ++j) {
			final AchievementType type = types[j];
			final int newValue = newValues[j];

			for (int i = 0; i < numAchievementDefs; ++i) {

				final AchievementListItemDef def = config.achievement_list.getItem(i);

				if (def.type == type) {

					logger.debug("checkForAchievements def " + def + " newValue=" + newValue);

					if (def.count <= newValue) {

						boolean awarded = force;
						if (!achievementsOwned.contains(def.id)) {
							UserData.awardAchievement(config, account_id, def.id, session_key);
							awarded = true;
						}

						if (awarded) {
							if (!achievementsProcessed.contains(def.id)) {
								achievementsEarned.add(def.id);
								achievementsOwned.add(def.id);
								achievementsProcessed.add(def.id);
							}
						}
					}
				}
			}
		}

		return achievementsEarned;
	}

	private ArrayList<String> checkForAchievements(final long account_id, final long session_key, final AchievementType type, final int newValue,
			final boolean force) {

		return checkForAchievements(account_id, session_key, new AchievementType[] { type }, new int[] { newValue }, force);
	}

	private boolean handleAchievementIncrement(AchievementProgressData data) {

		final int oldValue = UserData.incrementAchievementCount_AccountInfo(config, data.account_id, data.achievement_type, data.delta);
		final int newValue = oldValue + data.delta;

		data.total = newValue;

		final ArrayList<String> achievementsEarned = checkForAchievements(data.account_id, data.session_key, data.achievement_type, data.total, false);

		final int numAchievementsEarned = achievementsEarned.size();

		data.acquired = new String[numAchievementsEarned];

		for (int i = 0; i < numAchievementsEarned; ++i) {
			data.acquired[i] = achievementsEarned.get(i);
		}

		GameConfig.instance.msg.send("", data, MsgSystem.ZIP, MsgSystem.getUserQueue(data.account_id)); // to client
		if (data.battle_id != null && !data.battle_id.isEmpty()) {
			GameConfig.instance.msg.send(BattleSystem.EXCHANGE, data, MsgSystem.ZIP, data.battle_id); // to BattleMonitor
		}

		notifySteam(data.account_id, (String[]) data.acquired, new AchievementType[] { data.achievement_type }, new int[] { data.total });

		return true;
	}

	private boolean handleAchievementUpdate(AchievementProgressData data) {

		final int oldValue = UserData.updateAchievementMaxCount_AccountInfo(config, data.account_id, data.achievement_type, data.total);
		final int newValue = Math.max(data.total, oldValue);
		data.total = newValue;

		final ArrayList<String> achievementsEarned = checkForAchievements(data.account_id, data.session_key, data.achievement_type, data.total, false);

		final int numAchievementsEarned = achievementsEarned.size();

		data.acquired = new String[numAchievementsEarned];

		for (int i = 0; i < numAchievementsEarned; ++i) {
			data.acquired[i] = achievementsEarned.get(i);
		}

		GameConfig.instance.msg.send("", data, MsgSystem.ZIP, MsgSystem.getUserQueue(data.account_id)); // to client

		if (data.battle_id != null && !data.battle_id.isEmpty()) {
			GameConfig.instance.msg.send(BattleSystem.EXCHANGE, data, MsgSystem.ZIP, data.battle_id); // to BattleMonitor
		}

		notifySteam(data.account_id, (String[]) data.acquired, new AchievementType[] { data.achievement_type }, new int[] { data.total });

		return true;

	}

	private void notifySteam(final long account_id, final String[] achievements, final AchievementType[] types, final int[] values) {

		new Thread() {
			@Override
			public void run() {
				notifySteamWork(account_id, achievements, types, values);
			}
		}.start();
	}

	private void notifySteamWork(final long account_id, final String[] achievements, final AchievementType[] types, final int[] values) {

		final long steam_id = AccountData.getSteamId(account_id);
		if (steam_id == 0) {
			logger.info("notifySteam cannot for " + account_id + ", no steam id");
			return;
		}

		logger.debug("notifySteam ach=" + Arrays.toString(achievements) + ", types=" + Arrays.toString(types) + ", values=" + Arrays.toString(values));

		final String[] steam_names = new String[types.length + achievements.length];
		final int[] steam_values = new int[types.length + achievements.length];

		for (int i = 0; i < types.length; ++i) {
			steam_names[i] = types[i].name();
			steam_values[i] = values[i];
		}

		for (int i = 0; i < achievements.length; ++i) {
			steam_names[types.length + i] = achievements[i];
			steam_values[types.length + i] = 1;
		}

		logger.debug("notifySteam steam_names=" + Arrays.toString(steam_names) + ", steam_values=" + Arrays.toString(steam_values));

		try {
			final boolean r = Steam.ISteamUserStats.SetUserStatsForRetry(steam_id, steam_names, steam_values);
			if (!r) {
				logger.warn("handleAchievementIncrement Steam failed for " + account_id + "/" + steam_id);
			}
		} catch (InterruptedException e) {
			logger.error("handleAchievementIncrement: " + e);
		}
	}

	private void updateAllAchievements(final long account_id, final long session_key) {
		final HashMap<String, Integer> progress = UserData.getAchievementProgress(account_id);

		logger.debug("updateAllAchievements " + account_id + ", progress=" + progress.size());
		if (progress.size() <= 0) {
			return;
		}

		final AchievementType[] types = new AchievementType[progress.size()];
		final int[] values = new int[progress.size()];

		int i = 0;
		for (String key : progress.keySet()) {
			final AchievementType type = AchievementType.valueOf(key);
			final int value = progress.get(key);
			types[i] = type;
			values[i] = value;
			++i;
		}

		final ArrayList<String> achievementsEarned = checkForAchievements(account_id, session_key, types, values, true);
		final String[] ach = achievementsEarned.toArray(new String[achievementsEarned.size()]);
		notifySteam(account_id, ach, types, values);
	}

	@Override
	protected void runWorker(long deltaMs) throws Exception {
		// TODO Auto-generated method stub

	}

	@Override
	protected void stopWorker() throws Exception {
		// TODO Auto-generated method stub

	}

}
