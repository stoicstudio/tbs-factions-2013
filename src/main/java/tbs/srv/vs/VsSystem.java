package tbs.srv.vs;

import java.util.Arrays;

import org.apache.log4j.Logger;

import tbs.srv.util.GameConfig;
import tbs.srv.util.VsType;
import tbs.srv.vs.data.VsCancelData;
import tbs.srv.vs.data.VsFindData;

import com.newrelic.api.agent.Trace;

public class VsSystem {

	private static final Logger logger = Logger.getLogger(VsSystem.class.getSimpleName());

	final private GameConfig config;

	public static final String EXCHANGE = "vs";
	public static final String KEY_FIND = "vs_find";
	public static final String KEY_CANCEL = "vs_cancel";

	public static final boolean ZIP = true;

	public VsSystem(GameConfig _config) {

		this.config = _config;

	}

	@Trace
	public boolean start(final long session_key, long user, final String display_name, Object[] partyIds, long forceMatch, String forceScene,
			final int minTimer, final VsType type, final int match_handle, final int tourney_id) {
		final VsFindData data = new VsFindData(session_key, user, display_name, partyIds, forceMatch, forceScene, minTimer, type, match_handle, tourney_id);

		logger.info("start " + data + ", party=" + Arrays.toString(data.partyIds));
		return config.msg.send(EXCHANGE, data, ZIP, KEY_FIND);
	}

	public static class AbortException extends Exception {
		/**
		 * 
		 */
		private static final long serialVersionUID = 1L;

		public AbortException(String msg) {
			super(msg);
		}
	}

	@Trace
	public boolean cancel(long user, final int match_handle) {
		final VsCancelData msg = new VsCancelData(user, match_handle);

		logger.info("cancel " + msg);

		if (!config.msg.send(EXCHANGE, msg, false, KEY_CANCEL)) {
			logger.error("Failed to cancel " + user);
			return false;
		}

		return true;
	}

}
