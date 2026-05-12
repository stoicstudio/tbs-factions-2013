package tbs.srv.worker;

import org.apache.log4j.Logger;

import tbs.srv.battle.BattleSystem;
import tbs.srv.chat.ChatSystem;
import tbs.srv.util.GameConfig;

public class WorkerConfig extends GameConfig {

	public static final Logger logger = Logger.getLogger(WorkerConfig.class.getSimpleName());

	public boolean CHAT_ZIP = true;

	public static WorkerConfig instance;
	public BattleSystem battle;

	public WorkerConfig(final boolean battle_authority, final boolean chat_authority) throws Exception {
		super(logger, "worker");

		logger.info("Creating WorkerConfig...");

		CHAT_ZIP = getEnvBoolean("CHAT_ZIP", CHAT_ZIP, false);

		chat = new ChatSystem(this, CHAT_ZIP, chat_authority);

		battle = new BattleSystem(this, battle_authority);

		if (GAME_REBOOTING) {
			systemMessage.setSystemMessage(null, false);
			systemMessage.save();
		}
	}

	public static boolean init(final boolean battle_authority, final boolean chat_authority) {
		try {
			instance = new WorkerConfig(battle_authority, chat_authority);
			return true;
		} catch (Exception e) {
			logger.error("Failed to initialize WorkerConfig " + e);
			return false;
		}
	}
}
