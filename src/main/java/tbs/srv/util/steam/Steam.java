package tbs.srv.util.steam;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.apache.log4j.Logger;
import org.codehaus.jackson.JsonNode;
import org.codehaus.jackson.JsonProcessingException;
import org.codehaus.jackson.map.ObjectMapper;
import org.eclipse.jetty.util.ajax.JSON;

import tbs.srv.util.GameConfig;

public class Steam {

	public static final Logger logger = Logger.getLogger(Steam.class.getSimpleName());

	public static final long WARN_MS = 10000; // 10 sec
	public static final long RETRY_MS = 500;
	public static final long DEFAULT_GIVEUP_MS = 30000; // 30 sec

	public static class WebAPIUtil {
		public static JsonNode getSupportedAPIList() {
			if (GameConfig.instance.STEAM_API_KEY == null) {
				return null;
			}

			final String steamUrl = "http://api.steampowered.com/ISteamWebAPIUtil/GetSupportedAPIList/v0001/" + //
					"?format=json" + //
					"&key=" + GameConfig.instance.STEAM_API_KEY;
			GameConfig.HttpResponse response = GameConfig.instance.getHttp(steamUrl);

			if (response.code != 200) {
				return null;
			}

			try {
				ObjectMapper mapper = new ObjectMapper();
				return mapper.readTree(response.body);
			} catch (JsonProcessingException e) {
				logger.error("Steam.WebAPIUtil.getSupportedAPIList: " + e);
			} catch (IOException e) {
				logger.error("Steam.WebAPIUtil.getSupportedAPIList: " + e);
			}
			return null;
		}
	}

	public static class IPlayerService {
		public static Integer[] getOwnedGames(final long steamid, final Set<Integer> filter) {
			final String url = "https://api.steampowered.com/IPlayerService/GetOwnedGames/V0001/?key=" + GameConfig.instance.STEAM_API_KEY + "&steamid="
					+ steamid + "&include_played_free_games=1";

			final GameConfig.HttpResponse response = GameConfig.instance.getHttp(url);

			if (response.code != 200) {
				logger.warn("getOwnedGames failed");
				return new Integer[0];
			}

			ArrayList<Integer> appids = new ArrayList<Integer>();

			try {
				final ObjectMapper mapper = new ObjectMapper();
				JsonNode tree = mapper.readTree(response.body);

				final JsonNode games = tree.path("response").path("games");

				for (int i = 0; i < games.size(); ++i) {
					final int appid = games.get(i).path("appid").getIntValue();
					if (filter != null && filter.contains(appid)) {
						appids.add(appid);
					}
				}
			} catch (JsonProcessingException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

			// appids.add(234024);
			// appids.add(234022);
			// appids.add(234021);
			// appids.add(234023);

			return appids.toArray(new Integer[appids.size()]);

		}
	}

	public static class ISteamUserStats {
		final String baseurl = "http://api.steampowered.com/ISteamUserStats/";

		public static boolean SetUserStatsForGame(final long steamid, String[] statnames, int[] values) {
			if (GameConfig.instance.STEAM_API_KEY == null) {
				return false;
			}

			final String url = "http://api.steampowered.com/ISteamUserStats/SetUserStatsForGame/v0001/";

			final StringBuilder bb = //
			new StringBuilder("appid=" + GameConfig.instance.STEAM_APP_ID + "&key=" + GameConfig.instance.STEAM_API_KEY + "&count=" + statnames.length
					+ "&steamid=" + steamid);

			for (int i = 0; i < statnames.length; ++i) {

				bb.append("&name[").append(i).append("]=").append(statnames[i]);
				bb.append("&value[").append(i).append("]=").append(values[i]);
			}

			final GameConfig.HttpResponse response = GameConfig.instance.postHttp(url, bb.toString());

			if (response.code != 200) {
				logger.warn("SetUserStatsForGame failed");
				return false;
			}

			return true;
		}

		public static boolean SetUserStatsForRetry(final long steamid, String[] statnames, int[] values) throws InterruptedException {

			if (GameConfig.instance.STEAM_API_KEY == null) {
				return true;
			}

			final long start = System.currentTimeMillis();
			long warnstart = start;

			for (;;) {

				if (SetUserStatsForGame(steamid, statnames, values)) {
					return true;
				}

				final long cur = System.currentTimeMillis();
				final long delta = cur - start;

				if (delta > DEFAULT_GIVEUP_MS) {
					logger.warn("SetUserStatsForRetry GIVEUP " + steamid);
					return false;
				}

				final long warndelta = cur - warnstart;
				if (warndelta > WARN_MS) {
					logger.warn("SetUserStatsForRetry RETRY " + steamid);
				}

				// try again
				Thread.sleep(RETRY_MS);
			}
		}
	}

	public static class ISteamMicroTxn {
		public static boolean finalizeTxn(final long xxx, final long orderid, int[] out_errorcode, String[] out_errordesc) {
			if (GameConfig.instance.STEAM_API_KEY == null) {
				return false;
			}

			final String url = getMicroTxnUrl() + "/FinalizeTxn/v0002/";

			final String body = //
			"appid=" + GameConfig.instance.STEAM_APP_ID + "&key=" + GameConfig.instance.STEAM_API_KEY + "&orderid=" + orderid;

			final GameConfig.HttpResponse response = GameConfig.instance.postHttp(url, body);

			if (response.code != 200) {
				logger.warn("finalizeTxn failed orderid=" + orderid + ": " + response.code + " " + url);

				if (GameConfig.instance.STEAM_TXN_FORCE_FINALIZE) {
					logger.warn("finalizeTxn STEAM_TXN_FORCE_FINALIZE");
					return true;
				}

				return false;
			}

			final ObjectMapper mapper = new ObjectMapper();
			JsonNode tree;
			try {
				tree = mapper.readTree(response.body);
			} catch (Exception e) {
				throw new WebApplicationException(Response.status(Status.BAD_REQUEST).entity("finalizeTxn Steam Error: Empty Response").build());
			}

			final String ok = (String) tree.path("response").path("result").getTextValue();

			if (!"OK".equals(ok)) {
				final JsonNode error = tree.path("response").path("error");
				final int errorcode = error.path("errorcode").getValueAsInt();
				final String errordesc = error.path("errordesc").getTextValue();

				if (out_errorcode != null && out_errorcode.length > 0) {
					out_errorcode[0] = errorcode;
				}

				if (out_errordesc != null && out_errordesc.length > 0) {
					out_errordesc[0] = errordesc;
				}

				if (GameConfig.instance.STEAM_TXN_FORCE_FINALIZE) {
					logger.warn("finalizeTxn STEAM_TXN_FORCE_FINALIZE " + orderid + " " + errorcode + " " + errordesc);
					return true;
				}

				logger.error("finalizeTxn order=" + orderid + ": " + errorcode + " " + errordesc);

				return false;
			}

			return true;
		}

		public static class SteamTxnItemData {
			public int itemid;
			public int qty;
			public int amount;
			public String description;
			public String category;

			public SteamTxnItemData(final int itemid, final int qty) {
				this.itemid = itemid;
				this.qty = qty;
			}
		}

		public static class SteamTxnResponseData {
			public long orderid;
			public long transid;
			public String steamurl;
			public boolean ok;
			public int errorcode;
			public String errordesc;

			public String message() {
				if (ok) {
					return "OK";
				} else {
					return "Steam ERROR " + errorcode + ": " + errordesc;
				}
			}

			public boolean severe() {
				if (ok) {
					return false;
				}

				switch (errorcode) {
				case 104: // Transaction denied OR ip rate limit
				case 7: // Not logged in
				case 4: // pending purchases
				case 8: // currency does not match
					return false;
				}

				return true;
			}
		}

		public static String getMicroTxnUrl() {
			if (GameConfig.instance.STEAM_MICRO_TXN_SANDBOX) {
				if (GameConfig.instance.STEAM_MICRO_TXN_HTTPS) {
					return "https://api.steampowered.com/ISteamMicroTxnSandbox";
				} else {
					return "http://api.steampowered.com/ISteamMicroTxnSandbox";
				}
			} else {
				if (GameConfig.instance.STEAM_MICRO_TXN_HTTPS) {
					return "https://api.steampowered.com/ISteamMicroTxn";
				} else {
					return "http://api.steampowered.com/ISteamMicroTxn";
				}
			}
		}

		public static SteamTxnResponseData initTxn(final long orderid, final long steamid, final int itemcount, final String language, final String currency,
				final boolean clientsession, final String ipaddress, final SteamTxnItemData... items) {
			if (GameConfig.instance.STEAM_API_KEY == null) {
				return null;
			}

			final String url = getMicroTxnUrl() + "/InitTxn/v0002/";

			final StringBuilder bb = new StringBuilder();
			bb.append("appid=").append(GameConfig.instance.STEAM_APP_ID);
			bb.append("&key=").append(GameConfig.instance.STEAM_API_KEY);
			bb.append("&orderid=").append(orderid);
			bb.append("&steamid=").append(steamid);
			bb.append("&itemcount=").append(itemcount);
			bb.append("&language=").append(language);
			bb.append("&currency=").append(currency);
			bb.append("&usersession=").append(clientsession ? "client" : "web");
			if (!clientsession) {
				bb.append("&ipaddress=").append(ipaddress);
			}

			for (int i = 0; i < items.length; ++i) {
				final SteamTxnItemData item = items[i];
				bb.append("&itemid[").append(i).append("]=").append(item.itemid);
				bb.append("&qty[").append(i).append("]=").append(item.qty);
				bb.append("&amount[").append(i).append("]=").append(item.amount);
				bb.append("&description[").append(i).append("]=").append(item.description);
				bb.append("&category[").append(i).append("]=").append(item.category);
			}

			final String body = bb.toString();

			GameConfig.HttpResponse response = GameConfig.instance.postHttp(url, body);

			if (response.code != 200) {
				logger.warn("initTxn failed " + response.code + " " + url);
				return null;
			}

			ObjectMapper mapper = new ObjectMapper();
			JsonNode tree;
			try {
				tree = mapper.readTree(response.body);
			} catch (Exception e) {
				logger.error("initTxn empty response to " + url);
				throw new WebApplicationException(Response.status(Status.BAD_REQUEST).entity("initTxn Steam Error: Empty Response").build());
			}

			final String ok = (String) tree.path("response").path("result").getTextValue();

			final SteamTxnResponseData rd = new SteamTxnResponseData();
			rd.orderid = orderid;

			if (!"OK".equals(ok)) {
				final JsonNode error = tree.path("response").path("error");
				rd.errorcode = error.path("errorcode").getValueAsInt();
				rd.errordesc = error.path("errordesc").getTextValue();

				if (rd.severe())
					logger.error("initTxn " + orderid + " " + rd.errorcode + " " + rd.errordesc + " to " + url);
				else
					logger.warn("initTxn " + orderid + " " + rd.errorcode + " " + rd.errordesc + " to " + url);

				return rd;
			}

			final JsonNode params = tree.path("response").path("params");

			rd.orderid = params.path("orderid").getValueAsInt();
			rd.transid = Long.parseLong(params.path("transid").getTextValue());
			rd.steamurl = params.path("steamurl").getTextValue();
			rd.ok = true;

			if (rd.orderid != orderid) {
				logger.error("initTxn order id mismatch.  sent " + orderid + " got " + rd.orderid + ": " + response.body + " to " + url);
				return null;
			}

			if (rd.transid == 0) {
				logger.error("initTxn invalid steam transaction id for " + url);
				return null;
			}

			return rd;
		}

		public static class SteamUserInfo {
			public long steamid;
			public String state;
			public String country;
			public String currency;
			public String status;
			public String language;
			public String ipaddress;

			public boolean error;
			public int errorcode;
			public String errordesc;

			public final static int ERROR_CODE_NOT_LOGGED_IN = 7;

			public boolean isOk() {
				return currency != null && currency.length() == 3 && language != null && language.length() == 2 && steamid != 0;
			}

			public String debugString() {
				return "SteamUserInfo [steamid=" + steamid + ", state=" + state + ", country=" + country + ", currency=" + currency + ", status=" + status
						+ ", language=" + language + ", ipaddress=" + ipaddress + ", error=" + error + ", errorcode=" + errorcode + ", errordesc=" + errordesc
						+ "]";
			}

			@Override
			public String toString() {
				return "SteamUserInfo[" + steamid + ", " + currency + "]";
			}

			public void fakeIt() {

				if (currency == null) {
					currency = "USD";
				}

				if (country == null) {
					country = "US";
				}

				if (state == null) {
					state = "TX";
				}
			}
		}

		public static SteamUserInfo getUserInfoRetry(final long steamid, final String language) throws InterruptedException {

			if (GameConfig.instance.STEAM_API_KEY == null) {
				return null;
			}

			final long start = System.currentTimeMillis();
			long warnstart = start;

			for (;;) {

				final SteamUserInfo sui = Steam.ISteamMicroTxn.getUserInfo(steamid, language);
				if (sui != null) {
					return sui;
				}

				final long cur = System.currentTimeMillis();
				final long delta = cur - start;

				if (delta > DEFAULT_GIVEUP_MS) {
					logger.warn("getUserInfoRetry GIVEUP");
					return null;
				}

				final long warndelta = cur - warnstart;
				if (warndelta > WARN_MS) {
					logger.warn("getUserInfoRetry RETRY");
				}

				// try again
				Thread.sleep(RETRY_MS);
			}
		}

		public static SteamUserInfo getUserInfo(final long steamid, final String language) {
			if (GameConfig.instance.STEAM_API_KEY == null) {
				return null;
			}

			final String url = getMicroTxnUrl() + "/GetUserInfo/v0002/";

			final StringBuilder bb = new StringBuilder("appid=" + GameConfig.instance.STEAM_APP_ID + "&key=" + GameConfig.instance.STEAM_API_KEY + "&steamid="
					+ steamid);

			final String body = bb.toString();
			
			final GameConfig.HttpResponse response = GameConfig.instance.getHttp(url + "?" + body);

			if (response.code != 200) {
				logger.warn("getUserInfo " + steamid + " failed " + response.code + " " + url);
				return null;
			}

			ObjectMapper mapper = new ObjectMapper();
			JsonNode tree;
			try {
				tree = mapper.readTree(response.body);
			} catch (Exception e) {
				logger.warn("getUserInfo Steam Error: Empty Response");
				return null;
			}

			final String ok = (String) tree.path("response").path("result").getTextValue();

			final SteamUserInfo sui = new SteamUserInfo();
			sui.steamid = steamid;
			sui.language = language;

			if (!"OK".equals(ok)) {

				final JsonNode error = tree.path("response").path("error");
				final int errorcode = error.path("errorcode").getIntValue();
				final String errordesc = error.path("errordesc").getTextValue();
				logger.warn("getUserInfo " + steamid + " failed " + response.body);

				sui.error = true;
				sui.errorcode = errorcode;
				sui.errordesc = errordesc;

				return sui;
			}

			final JsonNode params = tree.path("response").path("params");
			if (params.isNull()) {
				logger.error("getUserInfo " + steamid + " no response params " + response.body);
				return null;
			}

			sui.state = params.path("state").getTextValue();
			sui.country = params.path("country").getTextValue();
			sui.currency = params.path("currency").getTextValue();
			sui.status = params.path("status").getTextValue();

			return sui;
		}

	}

	public static class UserAuth {
		public static boolean authenticateUserTicket(final long id, final String authTicket) {
			if (GameConfig.instance.STEAM_API_KEY == null) {
				return false;
			}

			final String url = "http://api.steampowered.com/ISteamUserAuth/AuthenticateUserTicket/v0001/" + //
					"?appid=" + GameConfig.instance.STEAM_APP_ID + //
					"&key=" + GameConfig.instance.STEAM_API_KEY + //
					"&ticket=" + authTicket;

			final GameConfig.HttpResponse response = GameConfig.instance.getHttp(url);

			if (response.code != 200) {
				logger.warn("authenticateUserTicket FAILED steam_id=" + id + " http=" + response.code + " " + url);
				return false;
			}

			ObjectMapper mapper = new ObjectMapper();
			JsonNode tree;
			try {
				tree = mapper.readTree(response.body);
			} catch (Exception e) {
				throw new WebApplicationException(Response.status(Status.BAD_REQUEST).entity("authenticateUserTicket Steam Error: Empty Response").build());
			}

			final String ok = (String) tree.path("response").path("params").path("result").getTextValue();

			if ("OK".equals(ok)) {
				// logger.info("Steam Auth result: " + result);
				return true;
			}

			final JsonNode error = tree.path("response").path("error");
			if (!error.isNull()) {
				final Number errorcode = error.path("errorcode").getNumberValue();
				final String errordesc = error.path("errordesc").getTextValue();
				logger.warn("authenticateUserTicket FAILED steam_id=" + id + " rsp " + errorcode + ": " + errordesc);
			}

			return false;
		}
	}

	public static class Leaderboards {
		public static boolean setLeaderboardScore(final long id, final long leaderboard, final Number score) {
			if (GameConfig.instance.STEAM_API_KEY == null) {
				return false;
			}

			final String url = "http://api.steampowered.com/ISteamLeaderboards/SetLeaderboardScore/v0001/";

			final String body = //
			"appid=" + GameConfig.instance.STEAM_APP_ID + "&leaderboardid=" + leaderboard + "&steamid=" + id + "&score=" + score
					+ "&scoremethod=ForceUpdate&key=" + GameConfig.instance.STEAM_API_KEY;

			final GameConfig.HttpResponse response = GameConfig.instance.postHttp(url, body);

			if (response.code != 200) {
				logger.warn("setLeaderboardScore failed " + response.code + " " + url);
				return false;
			}

			return true;
		}

		public static boolean setLeaderboardScoreRetry(final long id, final long leaderboard, final Number score) throws InterruptedException {

			if (GameConfig.instance.STEAM_API_KEY == null) {
				return true;
			}

			final long start = System.currentTimeMillis();
			long warnstart = start;

			for (;;) {

				if (setLeaderboardScore(id, leaderboard, score)) {
					return true;
				}

				final long cur = System.currentTimeMillis();
				final long delta = cur - start;

				if (delta > DEFAULT_GIVEUP_MS) {
					logger.warn("setLeaderboardScoreRetry GIVEUP " + id);
					return false;
				}

				final long warndelta = cur - warnstart;
				if (warndelta > WARN_MS) {
					logger.warn("setLeaderboardScoreRetry RETRY " + id);
				}

				// try again
				Thread.sleep(RETRY_MS);
			}

		}

	}

	public static class SteamUser {

		public static Integer[] getPublisherAppOwnership(final long steamid) {
			final String url = "https://api.steampowered.com/ISteamUser/GetPublisherAppOwnership/V0002/?key=" + GameConfig.instance.STEAM_API_KEY + "&steamid="
					+ steamid;

			final GameConfig.HttpResponse response = GameConfig.instance.getHttp(url);

			if (response.code != 200) {
				logger.warn("getPublisherAppOwnership failed");
				return new Integer[0];
			}

			ArrayList<Integer> appids = new ArrayList<Integer>();

			try {
				final ObjectMapper mapper = new ObjectMapper();
				final JsonNode tree = mapper.readTree(response.body);
				final JsonNode games = tree.path("appownership").path("apps");

				for (int i = 0; i < games.size(); ++i) {
					final int appid = games.get(i).path("appid").getIntValue();
					final boolean ownsapp = games.get(i).path("ownsapp").getBooleanValue();
					if (ownsapp) {
						appids.add(appid);
					}
				}
			} catch (JsonProcessingException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

			// appids.add(234024);
			// appids.add(234022);
			// appids.add(234021);
			// appids.add(234023);

			return appids.toArray(new Integer[appids.size()]);

		}

		public static List<SteamFriend> getFriendListRetry(final long steam_id) throws InterruptedException {

			if (GameConfig.instance.STEAM_API_KEY == null) {
				return null;
			}

			final long start = System.currentTimeMillis();
			long warnstart = start;

			boolean[] unauthorized = new boolean[1];

			for (;;) {

				final List<SteamFriend> sfs = Steam.SteamUser.getFriendList(steam_id, unauthorized);
				if (sfs != null) {
					return sfs;
				}

				if (unauthorized[0]) {
					// cannot keep trying
					logger.info("getFriendListRetry GIVEUP due to unauthorization " + steam_id);
					return new ArrayList<SteamFriend>();
				}

				final long cur = System.currentTimeMillis();
				final long delta = cur - start;

				if (delta > DEFAULT_GIVEUP_MS) {
					logger.warn("getFriendListRetry GIVEUP " + steam_id);
					return null;
				}

				final long warndelta = cur - warnstart;
				if (warndelta > WARN_MS) {
					logger.warn("acquireSteamFriendList RETRY " + steam_id);
				}

				// try again
				Thread.sleep(RETRY_MS);
			}
		}

		@SuppressWarnings("unchecked")
		public static List<SteamFriend> getFriendList(final long id, boolean[] unauthorized) {
			if (GameConfig.instance.STEAM_API_KEY == null) {
				return null;
			}

			final String steamUrl = "http://api.steampowered.com/ISteamUser/GetFriendList/v001/";

			final String url = steamUrl + "?steamid=" + id + "&key=" + GameConfig.instance.STEAM_API_KEY;

			final GameConfig.HttpResponse response = GameConfig.instance.getHttp(url);

			if (response.code == 401) {
				if (unauthorized != null && unauthorized.length > 0) {
					unauthorized[0] = true;
				}
				logger.info("getFriendList Unauthorized for steamid=" + id);
				return null;
			} else if (response.code != 200) {
				logger.warn("getFriendList failed " + response.code + " " + url);
				return null;
			}

			try {
				final ObjectMapper mapper = new ObjectMapper();
				JsonNode tree = mapper.readTree(response.body);

				final JsonNode players = tree.path("response").path("players");

				for (int i = 0; i < players.size(); ++i) {
					mapper.readValue(players.get(i), SteamFriend.class);
				}

				final Map<String, Object> rj = (Map<String, Object>) JSON.parse(response.body);
				final Map<String, Object> friendslist = (Map<String, Object>) rj.get("friendslist");
				final Object[] friends = (Object[]) friendslist.get("friends");
				final ArrayList<SteamFriend> sfs = new ArrayList<SteamFriend>();
				for (Object fo : friends) {
					final SteamFriend sf = new SteamFriend();
					sf.fromSteamJSON((Map<String, Object>) fo);
					sfs.add(sf);
				}

				return sfs;
			} catch (JsonProcessingException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

			return null;

		}

		@SuppressWarnings("unchecked")
		public static List<SteamPlayerSummary> getPlayerSummaries(final long... ids) {
			if (GameConfig.instance.STEAM_API_KEY == null) {
				return null;
			}

			final String steamUrl = "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?format=json";

			String url = steamUrl + "&key=" + GameConfig.instance.STEAM_API_KEY + "&steamids=";

			int count = 0;
			for (long id : ids) {
				if (count > 0) {
					url += ",";
				}
				url += id;
				++count;
			}

			final GameConfig.HttpResponse response = GameConfig.instance.getHttp(url);

			if (response.code != 200) {
				logger.warn("getPlayerSummaries failed " + response.code + " " + url);
				return null;
			}

			final Map<String, Object> rj = (Map<String, Object>) JSON.parse(response.body);
			final Map<String, Object> r = (Map<String, Object>) rj.get("response");
			final Object[] players = (Object[]) r.get("players");
			final ArrayList<SteamPlayerSummary> sfs = new ArrayList<SteamPlayerSummary>();
			for (Object po : players) {
				final SteamPlayerSummary sps = new SteamPlayerSummary();
				sps.fromSteamJson((Map<String, Object>) po);
				sfs.add(sps);
			}

			return sfs;
		}

		public static List<SteamPlayerSummary> getPlayerSummariesRetry(final long... ids) throws InterruptedException {

			if (GameConfig.instance.STEAM_API_KEY == null) {
				return null;
			}

			final long start = System.currentTimeMillis();
			long warnstart = start;

			for (;;) {

				final List<SteamPlayerSummary> sps = Steam.SteamUser.getPlayerSummaries(ids);
				if (sps != null) {
					return sps;
				}

				final long cur = System.currentTimeMillis();
				final long delta = cur - start;

				if (delta > DEFAULT_GIVEUP_MS) {
					logger.warn("getPlayerSummariesRetry GIVEUP");
					return null;
				}

				final long warndelta = cur - warnstart;
				if (warndelta > WARN_MS) {
					logger.warn("getPlayerSummariesRetry RETRY");
				}

				// try again
				Thread.sleep(RETRY_MS);
			}
		}
	}
}
