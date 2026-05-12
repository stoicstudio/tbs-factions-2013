package tbs.srv.util;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashMap;
import java.util.Map;

import javax.sql.DataSource;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import net.sf.ehcache.CacheManager;

import org.apache.commons.dbcp.DriverManagerConnectionFactory;
import org.apache.commons.dbcp.PoolableConnectionFactory;
import org.apache.commons.dbcp.PoolingDataSource;
import org.apache.commons.pool.impl.GenericObjectPool;
import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import tbs.srv.chat.ChatSystem;
import tbs.srv.data.CharacterClassDef;
import tbs.srv.data.EntityDef;
import tbs.srv.data.PurchasableUnitsData;
import tbs.srv.data.TourneyDefList;
import tbs.srv.db.DbHelper;
import tbs.srv.vs.VsSystem;
import tbs.srv.web.SystemMsgSystem;

public class GameConfig extends BaseConfig implements ICharacterClassProvider {

	// environment
	public CacheManager cacheManager;

	public String BUILD_NUMBER = "";

	public static final int RDS_VERSION = 88;

	public int DAILY_LOGIN_STREAK_MS = 1000 * 60 * 60 * 24;

	public String RDS_URL;
	public String RDS_USERNAME;
	public String RDS_PASSWORD;
	public int RDS_MAX_CONNECTIONS = 16;
	public int RDS_MAX_WAIT = 30000;
	public int RDS_EVICT_IDLE_MS = 30 * 60 * 1000; // half hour

	public String STEAM_API_KEY;
	public int STEAM_APP_ID;
	public boolean STEAM_ALWAYS_AUTHENTICATE;
	public String GAME_ENVIRONMENT;
	public String DATA_URL;
	public boolean RELIABLE_ENABLED = false;
	public boolean STEAM_MICRO_TXN_SANDBOX = true;
	public boolean STEAM_MICRO_TXN_HTTPS = true;
	public boolean STEAM_TXN_FORCE_FINALIZE = false;
	public String OVERRIDE_LOCAL_IP = null;
	public boolean BATTLE_GLOBAL_CHAT = true;

	public int LEADERBOARD_MAX_ENTRIES = 1000;

	public int SESSION_TIMEOUT_SECS = 90;

	public boolean KIOSK = false;

	final HashMap<String, IapTxnIdRange> iapTxnIdRanges = new HashMap<String, GameConfig.IapTxnIdRange>();

	public IapTxnIdRange iapTxnIdRange;

	public boolean GAME_REBOOTING = false;

	public DataSource rdsDatasource = null;

	public RabbitConfig rabbit;

	public VsSystem vs;

	public GameStatCosts statCosts;
	public BattleSceneListDef battle_scene_list;
	public EntityDef[] starting_roster;
	private Object[] starting_roster_json;
	public PurchasableUnitsData purchasable_units;
	public InAppPurchaseItemListDef in_app_purchase_items;
	public Map<String, Object> in_app_purchase_items_json;
	private Map<String, Object> purchasable_units_json;
	public Object[] starting_party;
	public int starting_renown;
	public Map<String, CharacterClassDef> character_classes = new HashMap<String, CharacterClassDef>();
	public AchievementListDef achievement_list;
	public TourneyDefList tourney_defs;

	public MsgSystem msg;
	public ChatSystem chat;
	public RenownSystem renown;
	public SystemMsgSystem systemMessage;
	public UnlockSystem unlock;
	public UnitAddSystem unitAdd;

	static public GameConfig instance;

	private static class MyTask implements Runnable {
		public long delta = 0;
		public long start = System.currentTimeMillis();

		public MyTask() {

		}

		@Override
		public void run() {
			delta = System.currentTimeMillis() - start;
		}

		public String toString() {
			return getClass().getSimpleName() + " " + delta + " ms";
		}
	}

	private static class SetupDataSourceTask extends MyTask implements Runnable {

		private final String url;
		private final String username;
		private final String password;
		private final int expected_version;
		private final Logger logger;
		private final int max_connections;
		private final int evict_idle_ms;
		private final int max_wait;
		public DataSource ds;

		public SetupDataSourceTask(final String url, final String username, final String password, final int expected_version, final int max_connections,
				final int max_wait, final int evict_idle_ms, final Logger logger) {

			this.url = url;
			this.username = username;
			this.password = password;
			this.logger = logger;
			this.expected_version = expected_version;
			this.max_connections = max_connections;
			this.evict_idle_ms = evict_idle_ms;
			this.max_wait = max_wait;
		}

		@Override
		public void run() {
			ds = GameConfig.setupDatasource(url, username, password, max_connections, max_wait, evict_idle_ms, logger);

			if (ds == null) {
				return;
			}

			Connection con = null;
			Statement s = null;
			try {
				con = ds.getConnection();
				s = con.createStatement();
				ResultSet rs = s.executeQuery("SELECT `version_number` FROM `version`");
				rs.next();

				final int version_number = rs.getInt("version_number");
				s.close();

				if (version_number != expected_version) {
					logger.error("Invalid RDS VERSION.  Game Expected " + expected_version + ", found DB " + version_number);
					System.exit(0);
					ds = null;
				} else {
					logger.info("Running DB " + url + " VERSION " + version_number);
				}

			} catch (SQLException e) {
				logger.error("SetupDataSourceTask " + url + ":" + e);
				e.printStackTrace();
				ds = null;
			} finally {
				DbHelper.cleanup(con, s);
			}

			super.run();
		}
	}

	private class LoadRosterTask extends MyTask implements Runnable {

		@SuppressWarnings("unchecked")
		@Override
		public void run() {
			String url;

			final String fn = KIOSK ? "starting_roster_kiosk.json" : "starting_roster.json";

			if (DATA_URL.startsWith("http:")) {
				url = DATA_URL + "/" + fn;
			} else {
				url = DATA_URL + "/common/character/" + fn;
			}

			logger.info("Loading " + url);
			HttpResponse response = getResource(url);
			if (response.body == null || response.body.isEmpty()) {
				logger.error("Failed to LoadRosterTask from " + url);
				System.exit(0);
			}

			Map<String, Object> rm = (Map<String, Object>) JSON.parse(response.body);
			Map<String, Object> rosterMap = (Map<String, Object>) rm.get("roster");
			Map<String, Object> partyMap = (Map<String, Object>) rm.get("party");

			if (partyMap == null || rosterMap == null) {
				logger.error("Malformed starting roster");
				System.exit(0);
			}

			starting_roster_json = (Object[]) rosterMap.get("defs");
			starting_party = (Object[]) partyMap.get("ids");
			starting_renown = ((Number) rm.get("renown")).intValue();
			purchasable_units_json = (Map<String, Object>) rm.get("purchasable_units");

			logger.info("starting_roster has roster " + starting_roster_json.length + " and party " + starting_party.length + ", renown=" + starting_renown);
			super.run();
		}
	}

	private class LoadBattleSceneListTask extends MyTask implements Runnable {

		@Override
		public void run() {

			String url;
			if (DATA_URL.startsWith("http:")) {
				url = DATA_URL + "/battle_scene_list.json";
			} else {
				url = DATA_URL + "/common/battle/battle_scene_list.json";
			}

			logger.info("Loading " + url);
			HttpResponse response = getResource(url);
			if (response.body == null || response.body.isEmpty()) {
				logger.error("Failed to LoadBattleSceneListTaskfrom " + url);
				System.exit(0);
			}

			@SuppressWarnings("rawtypes")
			final Map rm = (Map) JSON.parse(response.body);

			battle_scene_list = new BattleSceneListDef(rm);

			logger.info("battle_scene_list " + battle_scene_list);
			super.run();
		}
	}

	private class LoadInAppPurchaseTask extends MyTask implements Runnable {

		@SuppressWarnings("unchecked")
		@Override
		public void run() {

			String url;
			if (DATA_URL.startsWith("http:")) {
				url = DATA_URL + "/in_app_purchase.json";
			} else {
				url = DATA_URL + "/common/iap/in_app_purchase.json";
			}

			logger.info("Loading " + url);
			final HttpResponse response = getResource(url);
			if (response.body == null || response.body.isEmpty()) {
				logger.error("Failed to LoadInAppPurchaseTaskfrom " + url);
				System.exit(0);
			}

			in_app_purchase_items_json = (Map<String, Object>) JSON.parse(response.body);

			super.run();
		}
	}

	private class LoadAchievementListTask extends MyTask implements Runnable {

		@Override
		public void run() {

			String url;
			if (DATA_URL.startsWith("http:")) {
				url = DATA_URL + "/achievement_defs.json";
			} else {
				url = DATA_URL + "/common/achievement/achievement_defs.json";
			}

			logger.info("Loading " + url);
			HttpResponse response = getResource(url);
			if (response.body == null || response.body.isEmpty()) {
				logger.error("Failed to LoadAchievementListTask " + url);
				System.exit(0);
			}

			@SuppressWarnings("rawtypes")
			final Map rm = (Map) JSON.parse(response.body);

			achievement_list = new AchievementListDef(rm);

			logger.info("achivement_list " + achievement_list);
			super.run();
		}
	}

	private class LoadTourneyScheduleTask extends MyTask implements Runnable {

		@Override
		public void run() {

			String url;
			if (DATA_URL.startsWith("http:")) {
				url = DATA_URL + "/tourney_defs.json";
			} else {
				url = DATA_URL + "/common/tourney/tourney_defs.json";
			}

			logger.info("Loading " + url);
			HttpResponse response = getResource(url);
			if (response.body == null || response.body.isEmpty()) {
				logger.error("Failed to LoadTourneyScheduleTask " + url);
				System.exit(0);
			}

			final Object[] v = (Object[]) JSON.parse(response.body);
			tourney_defs = new TourneyDefList(v);

			super.run();
		}
	}

	private class LoadGameStatCostsTask extends MyTask implements Runnable {

		@SuppressWarnings("unchecked")
		@Override
		public void run() {
			String url;
			if (DATA_URL.startsWith("http:")) {
				url = DATA_URL + "/stat_costs.json";
			} else {
				url = DATA_URL + "/common/character/stat_costs.json";
			}

			logger.info("Loading " + url);
			HttpResponse response = getResource(url);
			if (response.body == null || response.body.isEmpty()) {
				logger.error("Failed to LoadGameStatCostsTask " + url);
				System.exit(0);
			}

			Map<String, Object> rm = (Map<String, Object>) JSON.parse(response.body);
			statCosts = new GameStatCosts(rm);
			super.run();
		}
	}

	private class LoadCharacterClassesTask extends MyTask implements Runnable {

		@SuppressWarnings("unchecked")
		@Override
		public void run() {
			String url;
			if (DATA_URL.startsWith("http:")) {
				url = DATA_URL + "/character_classes.json";
			} else {
				url = DATA_URL + "/common/character/character_classes.json";
			}

			logger.info("Loading " + url);
			HttpResponse response = getResource(url);
			if (response.body == null || response.body.isEmpty()) {
				logger.error("Failed to LoadCharacterClassesTask from " + url);
				System.exit(0);
			}

			final Map<String, Object> jbody = (Map<String, Object>) JSON.parse(response.body);

			final Object[] defs = (Object[]) jbody.get("classes");

			if (defs == null) {
				logger.error("Malformed character_classes");
				System.exit(0);
			}

			for (Object o : defs) {
				final Map<String, Object> j = (Map<String, Object>) o;
				final CharacterClassDef entity = new CharacterClassDef(j);
				character_classes.put(entity.id, entity);
			}

			logger.info("character_classes has " + character_classes.size());
			super.run();
		}
	}

	private class RabbitTask extends MyTask implements Runnable {

		@Override
		public void run() {
			rabbit = new RabbitConfig(GameConfig.class.getSimpleName());
			super.run();
		}
	}

	public GameConfig(Logger logger, String name) throws Exception {

		super(logger);

		instance = this;

		KIOSK = getEnvBoolean("KIOSK", KIOSK, false);

		STEAM_API_KEY = getEnv("STEAM_API_KEY", null, false);
		STEAM_APP_ID = getEnvInteger("STEAM_APP_ID", 0, true);
		STEAM_ALWAYS_AUTHENTICATE = getEnvBoolean("STEAM_ALWAYS_AUTHENTICATE", false, false);
		GAME_ENVIRONMENT = getEnv("GAME_ENVIRONMENT", null, true);
		BUILD_NUMBER = getEnv("BUILD_NUMBER", null, true);
		DATA_URL = getEnv("DATA_URL", "http://stoicstudio.com/deploy/dev/" + BUILD_NUMBER, false);
		GAME_REBOOTING = getEnvBoolean("GAME_REBOOTING", GAME_REBOOTING, false);

		STEAM_MICRO_TXN_SANDBOX = getEnvBoolean("STEAM_MICRO_TXN_SANDBOX", STEAM_MICRO_TXN_SANDBOX, false);
		STEAM_MICRO_TXN_HTTPS = getEnvBoolean("STEAM_MICRO_TXN_HTTPS", STEAM_MICRO_TXN_HTTPS, false);
		STEAM_TXN_FORCE_FINALIZE = getEnvBoolean("STEAM_TXN_FORCE_FINALIZE", STEAM_TXN_FORCE_FINALIZE, false);
		BATTLE_GLOBAL_CHAT = getEnvBoolean("BATTLE_GLOBAL_CHAT", BATTLE_GLOBAL_CHAT, false);

		OVERRIDE_LOCAL_IP = getEnv("OVERRIDE_LOCAL_IP", OVERRIDE_LOCAL_IP, false);

		RDS_MAX_CONNECTIONS = getEnvInteger("RDS_MAX_CONNECTIONS", RDS_MAX_CONNECTIONS, false);
		RDS_MAX_WAIT = getEnvInteger("RDS_MAX_WAIT", RDS_MAX_WAIT, false);
		RDS_EVICT_IDLE_MS = getEnvInteger("RDS_EVICT_IDLE_MS", RDS_EVICT_IDLE_MS, false);

		SESSION_TIMEOUT_SECS = getEnvInteger("SESSION_TIMEOUT_SECS", SESSION_TIMEOUT_SECS, false);

		RDS_URL = getEnv("RDS_URL", null, true);
		RDS_USERNAME = getEnv("RDS_USERNAME", null, true);
		RDS_PASSWORD = getEnv("RDS_PASSWORD", null, false);

		RELIABLE_ENABLED = getEnvBoolean("RELIABLE_ENABLED", RELIABLE_ENABLED, false);

		DAILY_LOGIN_STREAK_MS = getEnvInteger("DAILY_LOGIN_STREAK_MS", DAILY_LOGIN_STREAK_MS, false);

		LEADERBOARD_MAX_ENTRIES = getEnvInteger("LEADERBOARD_MAX_ENTRIES", LEADERBOARD_MAX_ENTRIES, false);

		logger.info("Worker Tasks Starting");
		final long start = System.currentTimeMillis();

		final SetupDataSourceTask setupRds = new SetupDataSourceTask(//
				RDS_URL, RDS_USERNAME, RDS_PASSWORD, RDS_VERSION, RDS_MAX_CONNECTIONS, RDS_MAX_WAIT, RDS_EVICT_IDLE_MS, logger);

		loadIapTxnIds();

		Runnable[] tasks = new Runnable[] { //
		setupRds, //

				new LoadRosterTask(),//
				new LoadBattleSceneListTask(), //
				new LoadCharacterClassesTask(), //
				new LoadGameStatCostsTask(), //
				new LoadAchievementListTask(), //
				new LoadTourneyScheduleTask(), //
				new LoadInAppPurchaseTask(), //
				new RabbitTask() //
		};//

		Thread[] threads = new Thread[tasks.length];

		for (int i = 0; i < tasks.length; ++i) {
			threads[i] = new Thread(tasks[i]);
			threads[i].start();
		}

		for (int i = 0; i < tasks.length; ++i) {
			try {
				threads[i].join();
				logger.info("### Joined Worker Task " + tasks[i]);
			} catch (InterruptedException e1) {
				e1.printStackTrace();
			}
		}

		rdsDatasource = setupRds.ds;

		final long end = System.currentTimeMillis();

		logger.info("Worker Tasks Complete in " + (end - start) + " ms");

		if (statCosts == null) {
			logger.error("No stat costs!");
			System.exit(0);
		}

		if (rdsDatasource == null) {
			logger.error("No Game Datasource!");
			System.exit(0);
		}

		if (rabbit == null || rabbit.connection == null) {
			logger.error("No Rabbit Connection!");
			System.exit(0);
		}

		initIapTxnRange();

		starting_roster = new EntityDef[starting_roster_json.length];
		for (int i = 0; i < starting_roster_json.length; ++i) {
			Object srj = starting_roster_json[i];
			@SuppressWarnings("unchecked")
			Map<String, Object> rm = (Map<String, Object>) srj;
			starting_roster[i] = new EntityDef(rm, this);
		}

		if (tourney_defs == null) {
			logger.error("No tournament schedule.");
			System.exit(0);
		}

		purchasable_units = new PurchasableUnitsData(purchasable_units_json, this);
		in_app_purchase_items = new InAppPurchaseItemListDef(in_app_purchase_items_json);

		msg = new MsgSystem(this);
		unlock = new UnlockSystem();
		unitAdd = new UnitAddSystem();

		cacheManager = CacheManager.create();

		vs = new VsSystem(this);

		renown = new RenownSystem(this);

		systemMessage = new SystemMsgSystem(this);
	}

	final public static class IapTxnIdRange {
		final public String env;
		final public long min;
		final public long max;

		public IapTxnIdRange(final String env, final long min, final long max) {
			this.env = env;
			this.min = min;
			this.max = max;
		}
	}

	private void loadIapTxnIds() throws Exception {
		final File file = new File("config/iap_txn_ids.xml");
		final DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
		final DocumentBuilder db = dbf.newDocumentBuilder();
		final Document doc = db.parse(file);

		doc.getDocumentElement().normalize();

		final NodeList nodes = doc.getElementsByTagName("env");
		for (int i = 0; i < nodes.getLength(); ++i) {
			final Node n = nodes.item(i);
			if (n.getNodeType() == Node.ELEMENT_NODE) {
				final Element e = (Element) n;
				final String env = e.getAttribute("id");
				final String mins = e.getAttribute("min");
				final String maxs = e.getAttribute("max");

				final IapTxnIdRange itir = new IapTxnIdRange(env, Long.parseLong(mins), Long.parseLong(maxs));
				iapTxnIdRanges.put(itir.env, itir);
			}
		}
	}

	private void initIapTxnRange() {

		iapTxnIdRange = iapTxnIdRanges.get(GAME_ENVIRONMENT);

		if (iapTxnIdRange == null) {
			logger.warn("No iapTxnIdRange for environment " + GAME_ENVIRONMENT + ", NO IAP TXN POSSIBLE");
			return;
		}

		Connection con = null;
		PreparedStatement s = null;
		try {
			con = rdsDatasource.getConnection();

			{
				s = con.prepareStatement("SELECT MIN(txn_id) min_txn_id, MAX(txn_id) max_txn_id FROM iap_txn");
				final ResultSet rs = s.executeQuery();
				if (rs.next()) {

					final long min_txn_id = rs.getLong("min_txn_id");
					final long max_txn_id = rs.getLong("max_txn_id");

					if (max_txn_id >= iapTxnIdRange.max) {
						logger.error("max_txn_id " + max_txn_id + " >= iapTxnIdRange.max " + iapTxnIdRange.max);
						System.exit(0);
					}

					if (min_txn_id < iapTxnIdRange.min) {
						logger.warn("min_txn_id " + min_txn_id + " < iapTxnIdRange.min " + iapTxnIdRange.min);
					}
				}
				s.close();
			}

			{
				s = con.prepareStatement("ALTER TABLE iap_txn AUTO_INCREMENT = ?");
				s.setLong(1, iapTxnIdRange.min);
				s.execute();
				s.close();
			}

		} catch (SQLException e) {

			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

	}

	public void stop() {
		rabbit.stop();
	}

	protected static DataSource setupDatasource(final String url, final String username, final String password, final int max_connections, final int max_wait,
			final int evict_idle_ms, Logger logger) {

		if (url != null && username != null && username != null) {

			final GenericObjectPool gop = new GenericObjectPool(null);
			gop.setTestOnBorrow(false);
			gop.setTestWhileIdle(true);
			gop.setMaxActive(max_connections);
			gop.setMaxIdle(-1);
			gop.setMinEvictableIdleTimeMillis(evict_idle_ms);
			if (evict_idle_ms > 0) {
				gop.setTimeBetweenEvictionRunsMillis(evict_idle_ms);
			}
			gop.setWhenExhaustedAction(GenericObjectPool.WHEN_EXHAUSTED_BLOCK);
			gop.setMaxWait(max_wait);

			String furl = url;
			if (furl.indexOf("?") < 0) {
				furl += "?";
			} else {
				furl += "&";
			}

			furl += "noAccessToProcedureBodies=true&useUnicode=true&characterEncoding=UTF-8";

			final DriverManagerConnectionFactory connectionFactory = new DriverManagerConnectionFactory("jdbc:mysql://" + furl, username, password);
			final String validation = "SELECT 1";
			new PoolableConnectionFactory(connectionFactory, gop, null, validation, false, true);
			PoolingDataSource pds = new PoolingDataSource(gop);

			final long start = System.currentTimeMillis();

			final long DB_LOGIN_RETRY_LIMIT_MS = 30000;
			final long DB_LOGIN_RETRY_SLEEP_MS = 2000;
			while ((System.currentTimeMillis() - start) < DB_LOGIN_RETRY_LIMIT_MS) {
				Connection con = null;
				try {
					con = pds.getConnection();

					boolean valid = con.isValid(0);
					con.close();
					if (!valid) {
						logger.warn("GameConfig ERROR validating DB " + url);
					} else {
						return pds;
					}
				} catch (SQLException e) {
					logger.warn("GameConfig ERROR creating DB " + url + ": " + e.getMessage());
					// e.printStackTrace();
				} finally {
					DbHelper.cleanup(con, null);
				}

				logger.warn("Sleeping to retry db connection");

				try {
					Thread.sleep(DB_LOGIN_RETRY_SLEEP_MS);
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
					return null;
				}
			}
		}

		return null;
	}

	public static class HttpResponse {
		public String body;
		public int code;

		public HttpResponse(String body, int code) {
			super();
			this.body = body;
			this.code = code;
		}

	}

	public HttpResponse getResource(String urlToRead) {
		if (!urlToRead.startsWith("http:", 0)) {
			return getFile(urlToRead);
		} else {
			return getHttp(urlToRead);
		}
	}

	public HttpResponse getFile(String urlToRead) {

		StringBuilder contents = new StringBuilder();
		try {

			final BufferedReader input = new BufferedReader(new InputStreamReader(new FileInputStream(urlToRead), "UTF-8"));

			String line = null;

			while ((line = input.readLine()) != null) {
				contents.append(line);
				contents.append(System.getProperty("line.separator"));
			}

			input.close();
			return new HttpResponse(contents.toString(), 0);

		} catch (Exception e) {
			e.printStackTrace();
			return new HttpResponse(null, 0);
		}

	}

	public HttpResponse getHttp(String urlToRead) {

		URL url;
		try {
			url = new URL(urlToRead);

		} catch (MalformedURLException e2) {
			logger.error("Malformed URL: " + urlToRead + ": " + e2);
			e2.printStackTrace();
			return null;
		}

		HttpURLConnection conn = null;
		StringBuilder result = new StringBuilder();
		try {
			BufferedReader rd;

			logger.debug("getHttp " + url);

			conn = (HttpURLConnection) url.openConnection();
			conn.setRequestProperty("Connection", "close");
			conn.setRequestProperty("Accept-Charset", "UTF-8");
			conn.setRequestProperty("Content-Type", "text/plain; charset=utf-8");
			conn.setRequestMethod("GET");
			
			InputStreamReader isr = new InputStreamReader(conn.getInputStream(), "UTF-8");
			rd = new BufferedReader(isr);
			String line = null;

			while ((line = rd.readLine()) != null) {
				result.append(line);
			}
			rd.close();

			conn.disconnect();

			logger.debug("getHttp RESPONSE " + conn.getResponseCode() + " " + url);
			return new HttpResponse(result.toString(), conn.getResponseCode());

		} catch (Exception e) {
			// is there no better way? The humanity!
			try {
				final String m = e.getMessage();
				final String prefix = "HTTP response code: ";
				final int i_prefix = m.indexOf(prefix);
				if (i_prefix >= 0) {
					final int i_code = i_prefix + prefix.length();
					final int i_space = m.indexOf(" ", i_code);
					final String c_s = m.substring(i_code, i_space);
					final int code = Integer.parseInt(c_s);
					return new HttpResponse(e.getMessage(), code);
				}
			} catch (Exception e1) {
				// do nothing, just fail msg
			}

			logger.warn("getHttp FAIL " + e.getMessage() + " " + urlToRead);
			return new HttpResponse(null, 0);
		} finally {
			if (conn != null) {
				conn.disconnect();
			}
		}
	}

	public HttpResponse postHttp(String urlToPost, String data) {

		HttpURLConnection conn = null;

		// Send data
		try {
			final URL url = new URL(urlToPost);

			logger.debug("postHttp " + url + " " + data);

			conn = (HttpURLConnection) url.openConnection();
			conn.setRequestProperty("Connection", "close");
			conn.setRequestProperty("Accept-Charset", "UTF-8");
			conn.setRequestMethod("POST");
			conn.setDoOutput(true);

			if (data == null) {
				data = "";
			}

			final OutputStreamWriter wr = new OutputStreamWriter(conn.getOutputStream());
			wr.write(data);
			wr.flush();

			final StringBuilder sb = new StringBuilder();
			// Get the response
			final InputStreamReader isr = new InputStreamReader(conn.getInputStream(), "UTF-8");
			BufferedReader rd = new BufferedReader(isr);
			String line;
			while ((line = rd.readLine()) != null) {
				sb.append(line);
			}

			wr.close();
			rd.close();

			conn.disconnect();

			logger.debug("postHttp RESPONSE " + conn.getResponseCode() + " " + url + " " + sb.toString());

			return new HttpResponse(sb.toString(), conn.getResponseCode());

		} catch (Exception e) {
			// e.printStackTrace();
			logger.warn("postHttp FAIL " + e.getMessage());
			return new HttpResponse(null, 0);
		} finally {
			if (conn != null) {
				conn.disconnect();
			}
		}
	}

	public CharacterClassDef getCharacterClassDef(final String id) {
		return character_classes.get(id);
	}

}
