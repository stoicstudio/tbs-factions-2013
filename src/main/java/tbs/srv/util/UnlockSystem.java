package tbs.srv.util;

import java.io.IOException;

import org.apache.log4j.Logger;

public class UnlockSystem {

	public static final Logger logger = Logger.getLogger(UnlockSystem.class.getSimpleName());

	public static final String KEY = "key_unlock";

	public UnlockSystem() throws IOException {
	}

	public void unlock(final long account_id, final String unlock_id, final long duration) {
		final UnlockData data = new UnlockData(account_id, unlock_id, 0, duration);
		logger.info("unlocking " + data);
		GameConfig.instance.msg.send("amq.direct", data, MsgSystem.ZIP, KEY);
	}
}
