package tbs.srv.util;

import org.apache.log4j.Logger;

public class AchievementSystem {

	private static final Logger logger = Logger.getLogger(AchievementSystem.class.getSimpleName());

	public static final String ACHIEVEMENT_UPDATE_PROGRESS = "key_achievement_update_progress";

	public static void incrementAchievementProgress(String handle, String battle_id, RabbitConfig rabbit, final long account_id, final long session_key,
			final AchievementType achievementType, final int delta) {

		logger.debug("ENTER incrementAchievementProgress " + handle);

		final AchievementProgressData achievementProgressData = new AchievementProgressData();

		achievementProgressData.account_id = account_id;
		achievementProgressData.session_key = session_key;
		achievementProgressData.achievement_type = achievementType;
		achievementProgressData.delta = delta;

		achievementProgressData.handle = handle;
		achievementProgressData.battle_id = battle_id;

		GameConfig.instance.msg.send("amq.direct", achievementProgressData, MsgSystem.ZIP, ACHIEVEMENT_UPDATE_PROGRESS);

	}

	public static void updateAchievementProgress(String handle, String battle_id, RabbitConfig rabbit, final long account_id, final long session_key,
			final AchievementType achievementType, final int total) {

		logger.debug("ENTER updateAchievementProgress " + handle);

		final AchievementProgressData achievementProgressData = new AchievementProgressData();

		achievementProgressData.account_id = account_id;
		achievementProgressData.session_key = session_key;
		achievementProgressData.achievement_type = achievementType;
		achievementProgressData.total = total;

		achievementProgressData.handle = handle;
		achievementProgressData.battle_id = battle_id;

		GameConfig.instance.msg.send("amq.direct", achievementProgressData, MsgSystem.ZIP, ACHIEVEMENT_UPDATE_PROGRESS);

	}

}
