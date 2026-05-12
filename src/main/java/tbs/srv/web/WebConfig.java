package tbs.srv.web;

import java.sql.Connection;
import java.sql.SQLException;

import javax.sql.DataSource;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import net.sf.ehcache.Cache;
import net.sf.ehcache.Element;
import net.sf.ehcache.config.CacheConfiguration;
import net.sf.ehcache.constructs.blocking.CacheEntryFactory;
import net.sf.ehcache.constructs.blocking.SelfPopulatingCache;
import net.sf.ehcache.store.MemoryStoreEvictionPolicy;

import org.apache.log4j.Logger;

import tbs.srv.battle.BattleSystem;
import tbs.srv.chat.ChatSystem;
import tbs.srv.db.DbHelper;
import tbs.srv.db.models.AuthDataVbb;
import tbs.srv.db.models.SessionData;
import tbs.srv.util.GameConfig;

import com.mysql.jdbc.jdbc2.optional.MysqlDataSource;
import com.newrelic.api.agent.Trace;

public class WebConfig extends GameConfig {

	public static final Logger logger = Logger.getLogger(WebConfig.class.getSimpleName());
	public static final int PROTOCOL_VERSION = 11;

	// environment
	public boolean AD_HOC_ACCOUNTS = false;
	public String VBB_USER = "gameserver_vbb";
	public String VBB_PASSWORD;
	public String VBB_SERVER = "mysql.stoicstudio.com";
	public String VBB_DB = "stoic_vbb_forum";
	public boolean VBB_ENABLED = true;
	public int PORT = 8080;
	public String JDBC_DRIVER = "com.mysql.jdbc.Driver";
	public boolean CHAT_ZIP = true;
	public String ADMIN_KEY;

	public int JETTY_MIN_THREADS = 10;
	public int JETTY_MAX_THREADS = 160;
	public long JETTY_THREAD_IDLE_MS = 10000;
	public int JETTY_MAX_QUEUE = 200;

	public DataSource vbbDataSource;

	public SelfPopulatingCache authVbbCache;
	private SelfPopulatingCache sessionCache;

	public BattleSystem battle;

	public WebSessionListener sessionListener;

	// The following group ids correspond to the vbulletin groups.
	// in future we may want to configure these with env vars
	public static long[] AUTH_USER_GROUPS = { 12 };
	public static long[] AUTH_ALLOW_FAKING_GROUPS = { 12 };
	public static long[] AUTH_SUPERUSER_GROUPS = { 6, 9 };

	public static WebConfig instance;

	public static boolean init() throws Exception {

		try {
			WebConfig.instance = new WebConfig();
			return true;
		} catch (Exception e) {
			logger.error("Failed to initialize WebConfig " + e);
			e.printStackTrace();
			return false;
		}
	}

	public WebConfig() throws Exception {

		super(logger, "web");

		logger.info("Creating WebConfig with PROTOCOL_VERSION " + PROTOCOL_VERSION);

		VBB_PASSWORD = getEnv("VBB_PASSWORD", null, true);
		VBB_USER = getEnv("VBB_USER", VBB_USER, false);
		VBB_SERVER = getEnv("VBB_SERVER", VBB_SERVER, false);
		VBB_DB = getEnv("VBB_DB", VBB_DB, false);
		PORT = getEnvInteger("PORT", PORT, false);
		AD_HOC_ACCOUNTS = getEnvBoolean("AD_HOC_ACCOUNTS", AD_HOC_ACCOUNTS, false);
		CHAT_ZIP = getEnvBoolean("CHAT_ZIP", CHAT_ZIP, false);
		ADMIN_KEY = getEnv("ADMIN_KEY", null, false);
		VBB_ENABLED = getEnvBoolean("VBB_ENABLED", VBB_ENABLED, false);

		JETTY_MIN_THREADS = getEnvInteger("JETTY_MIN_THREADS", JETTY_MIN_THREADS, false);
		JETTY_MAX_THREADS = getEnvInteger("JETTY_MAX_THREADS", JETTY_MAX_THREADS, false);
		JETTY_THREAD_IDLE_MS = getEnvLong("JETTY_THREAD_IDLE_MS", JETTY_THREAD_IDLE_MS, false);
		JETTY_MAX_QUEUE = getEnvInteger("JETTY_MAX_QUEUE", JETTY_MAX_QUEUE, false);

		chat = new ChatSystem(this, CHAT_ZIP, false);
		battle = new BattleSystem(this, false);

		if (VBB_ENABLED) {
			MysqlDataSource mds = new MysqlDataSource();
			mds.setUser(VBB_USER);
			mds.setPassword(VBB_PASSWORD);
			mds.setUrl("jdbc:mysql://" + VBB_SERVER + "/" + VBB_DB);
			vbbDataSource = mds;

			Connection con = null;
			try {
				con = vbbDataSource.getConnection();
				boolean valid = con.isValid(0);
				if (!valid) {
					System.out.println("WebConfig ERROR validating VBB DB");
				}

				con.close();
			} catch (SQLException exp) {
				exp.printStackTrace();
			} finally {
				DbHelper.cleanup(con, null);
			}
		}

		// TODO how many players can a single web server realistically handle?
		// TODO these numbers should probably be higher for the worker process
		int MAX_AUTHS = 5000;
		int MAX_SESSIONS = 5000;
		CacheConfiguration authConfig = new CacheConfiguration(//
				"auth", //
				MAX_AUTHS).memoryStoreEvictionPolicy(MemoryStoreEvictionPolicy.LFU).eternal(false);

		CacheConfiguration sessionConfig = new CacheConfiguration(//
				"session", //
				MAX_SESSIONS).memoryStoreEvictionPolicy(MemoryStoreEvictionPolicy.LFU).eternal(false).timeToLiveSeconds(6000).timeToIdleSeconds(60);

		if (vbbDataSource != null) {
			authVbbCache = new SelfPopulatingCache(new Cache(authConfig), new AuthVbbCacheEntryFactory());
		}

		sessionCache = new SelfPopulatingCache(new Cache(sessionConfig), new SessionCacheEntryFactory());

		cacheManager.addCache(authVbbCache);
		cacheManager.addCache(sessionCache);

		sessionListener = new WebSessionListener(rabbit);

	}

	class AuthVbbCacheEntryFactory implements CacheEntryFactory {

		@Override
		public Object createEntry(Object key) throws Exception {
			return new AuthDataVbb(vbbDataSource, (String) key);
		}

	}

	class SessionCacheEntryFactory implements CacheEntryFactory {

		@Override
		public Object createEntry(Object key) throws Exception {
			try {
				SessionData session = SessionData.load(rdsDatasource, (Long) key);
				if (session != null) {
					session.maybeTouch(instance.rdsDatasource);
				}

				return session;
			} catch (Exception exp) {
				logger.warn("Failed to find session entry for cache: " + key);
				return null;
			}
		}
	}

	public SessionData getSession(final String sessionKey) {
		if (sessionKey == null || sessionKey.isEmpty()) {
			return null;
		}
		try {
			return getSession(Long.parseLong(sessionKey, 16));
		} catch (Exception exp) {
			logger.warn("getSession failed for session " + sessionKey);
			throw new WebApplicationException(Response.status(Status.UNAUTHORIZED).entity("getSession no such session: " + sessionKey).build());
		}
	}

	@Trace
	public SessionData getSession(final long sessionKey) {
		final Element e = WebConfig.instance.sessionCache.get(sessionKey);
		final SessionData session = (e != null) ? (SessionData) e.getObjectValue() : null;
		if (session != null && session.isValid()) {

			if (WebConfig.instance.GAME_REBOOTING) {
				throw new WebApplicationException(Response.status(Status.SERVICE_UNAVAILABLE).entity("getSession game_rebooting").build());
			}

			session.maybeTouch(instance.rdsDatasource);
			return session;
		}

		logger.warn("getSession failed for session " + sessionKey);

		throw new WebApplicationException(Response.status(Status.UNAUTHORIZED).entity("getSession No such session: " + Long.toString(sessionKey, 16)).build());
	}

	@Trace
	public void putSession(final SessionData session) {
		sessionCache.put(new Element(session.getSessionKey(), session));
	}

	@Trace
	public void removeSession(final long session_key) {
		sessionCache.remove(session_key);
	}

}
