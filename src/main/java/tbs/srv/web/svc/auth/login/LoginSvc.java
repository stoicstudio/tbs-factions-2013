package tbs.srv.web.svc.auth.login;

import java.io.IOException;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Locale;

import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.apache.log4j.Logger;
import org.codehaus.jackson.JsonNode;
import org.codehaus.jackson.map.ObjectMapper;
import org.eclipse.jetty.util.ajax.JSON;

import tbs.srv.auth.AccountData;
import tbs.srv.data.ClientConfigData;
import tbs.srv.db.models.AuthDataVbb;
import tbs.srv.db.models.SessionData;
import tbs.srv.db.models.UserData;
import tbs.srv.util.GameConfig;
import tbs.srv.util.steam.Steam;
import tbs.srv.web.WebConfig;
import tbs.srv.web.svc.account.info.AccountInit;

import com.newrelic.api.agent.NewRelic;
import com.newrelic.api.agent.Trace;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class LoginSvc {

	private static final Logger logger = Logger.getLogger(LoginSvc.class.getSimpleName());

	@Trace
	public boolean authenticateSteam(long steam_id, final String authTicket) {

		if (WebConfig.instance.STEAM_ALWAYS_AUTHENTICATE) {
			// force authenticate steam
			return true;
		}

		if (authTicket == null) {
			logger.warn("authenticateSteam no authTicket: steam_id=" + steam_id);
			throw new IllegalArgumentException("No authTicket provided");
		}

		if (authTicket.equals("LOAD_TEST_TICKET_OK") && steam_id < 0) {
			// special ticket just for load testing
			return true;
		}

		if (Steam.UserAuth.authenticateUserTicket(steam_id, authTicket)) {
			return true;
		}

		// just try again if fail
		try {
			Thread.sleep(1000);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}

		return Steam.UserAuth.authenticateUserTicket(steam_id, authTicket);
	}

	@Trace
	private AccountData loginSteam(final long steam_id, final String steamAuthTicket, final String displayName) {
		// logger.debug("loginSteam " + steamId);

		if (!authenticateSteam(steam_id, steamAuthTicket)) {
			logger.warn("Steam Auth Failed steam_id=" + steam_id);
			throw new WebApplicationException(Response.status(Status.UNAUTHORIZED).entity("loginSteam steam_auth_failed").build());
		}

		AccountData account = AccountData.getSteam(WebConfig.instance.rdsDatasource, steam_id);

		if (account == null) {
			account = new AccountData(0, displayName, steam_id, 0, 0, null, 0, 0, false);
			account.create(WebConfig.instance.rdsDatasource);
		} else {
			account.updateDisplayName(WebConfig.instance.rdsDatasource, displayName);
		}

		return account;
	}

	private AccountData loginVbb(final String username, final String password, HttpServletRequest request) {
		// logger.debug("loginVbb " + username);

		if (password == null || password.isEmpty()) {
			logger.warn("login [" + request.getRemoteAddr() + "] invalid vbb login: " + username);
			throw new WebApplicationException(Response.status(Status.BAD_REQUEST).entity("loginVbb missing_password").build());
		}

		// int colon = username.indexOf(":");
		// String realusername = username;
		// if (colon > 0) {
		// realusername = username.substring(0, colon);
		// }

		AuthDataVbb auth = AuthDataVbb.get(username, false);

		if (auth == null) {
			logger.warn("login [" + request.getRemoteAddr() + "] no such user: " + username);
			throw new WebApplicationException(Response.status(Status.UNAUTHORIZED).entity("loginVbb no_such_user").build());
		}

		if (!auth.validatePassword(password)) {
			logger.warn("Failed validation for : " + username + ", retrying");

			// get a fresh one if this fails
			// TODO if we've already removed the same one, don't keep doing it
			auth = AuthDataVbb.get(username, true);

			if (!auth.validatePassword(password)) {
				logger.warn("Failed retry validation for : " + username + ", aborting");
				throw new WebApplicationException(Response.status(Status.UNAUTHORIZED).entity("loginVbb invalid_login").build());
			}
		}

		AccountData account = AccountData.getVbb(WebConfig.instance.rdsDatasource, auth.id);

		if (account == null) {
			account = new AccountData(0, auth.username, 0, auth.id, 0, auth.username, 0, 0, false);
			account.create(WebConfig.instance.rdsDatasource);
		}

		return account;

	}

	private AccountData loginChild(final AccountData parent, final int child_number) {

		// logger.debug("loginChild " + parent + " child");

		if (!parent.canChildAccount()) {
			logger.warn("loginChild cannot_child_account " + parent);
			throw new WebApplicationException(Response.status(Status.UNAUTHORIZED).entity("loginChild cannot_child_account").build());
		}

		AccountData account = parent.getChild(WebConfig.instance.rdsDatasource, child_number);

		if (account == null) {
			final String childName = parent.display_name + ":" + child_number;
			final long steam_id = 0;
			final long vbb_id = 0;
			account = new AccountData(0, childName, steam_id, vbb_id, 0, parent.vbb_name, parent.account_id, child_number, false);
			account.create(WebConfig.instance.rdsDatasource);
		}

		return account;
	}

	@POST
	@Path("/{protocolVersion}")
	public Response login(String body, @PathParam("protocolVersion") int protocolVersion, @Context HttpServletRequest request) throws IOException {

		NewRelic.incrementCounter("Custom/login/attempt");
		if (protocolVersion > WebConfig.PROTOCOL_VERSION) {
			logger.warn("login [" + request.getRemoteAddr() + "] protocol " + protocolVersion + " > " + WebConfig.PROTOCOL_VERSION);
			return Response.status(Status.BAD_REQUEST).entity("invalid_client_protocol_high").build();
		} else if (protocolVersion < WebConfig.PROTOCOL_VERSION) {
			logger.warn("login [" + request.getRemoteAddr() + "] protocol " + protocolVersion + " < " + WebConfig.PROTOCOL_VERSION);
			return Response.status(Status.BAD_REQUEST).entity("invalid_client_protocol_low").build();
		}

		if (WebConfig.instance.GAME_REBOOTING) {
			logger.info("AuthSvc GAME_REBOOTING");
			return Response.status(Status.SERVICE_UNAVAILABLE).entity("game_rebooting").build();
		}

		JsonNode jbody = null;
		try {
			ObjectMapper mapper = new ObjectMapper();
			jbody = mapper.readTree(body);
		} catch (Exception e) {
			logger.warn("login [" + request.getRemoteAddr() + "] invalid body: " + body);
			return Response.status(Status.BAD_REQUEST).entity("invalid body").build();
		}

		String ip = request.getRemoteAddr();
		if (ip.startsWith("0:0:0:0:0:0:0:")) {
			if (GameConfig.instance.OVERRIDE_LOCAL_IP != null) {
				ip = GameConfig.instance.OVERRIDE_LOCAL_IP;
			}
		}

		final Locale locale = request.getLocale();

		logger.debug("IP=" + ip + ", locale=" + locale);

		if (ip == null) {
			logger.error("Invalid null IP: " + ip);
			return Response.serverError().entity("invalid ip").build();
		}

		if (jbody == null) {
			logger.warn("login [" + request.getRemoteAddr() + "] no body: " + body);
			return Response.status(Status.BAD_REQUEST).entity("missing_body").build();
		}

		String displayName = jbody.get("display_name").getTextValue();
		JsonNode jsteam_id = jbody.get("steam_id");

		long steamId = 0;

		if (jsteam_id != null && !jsteam_id.isNull()) {
			if (jsteam_id.isNumber()) {
				steamId = jsteam_id.getValueAsLong();
			} else {
				steamId = Long.parseLong(jsteam_id.getTextValue());
			}
		}

		AccountData account = null;

		if (WebConfig.instance.KIOSK) {
			// always get a new account for the kiosk

			account = new AccountData(0, displayName, 0, 0, 0, null, 0, 0, false);
			account.create(WebConfig.instance.rdsDatasource);
		} else if (steamId != 0) {
			final String steamAuthTicket = jbody.get("steam_auth_ticket").getTextValue();
			try {
				account = loginSteam(steamId, steamAuthTicket, displayName);
			} catch (Exception e) {
				logger.warn("login [" + request.getRemoteAddr() + "] invalid steam login: " + steamId + " [" + displayName + "]");
				return Response.status(Status.BAD_REQUEST).entity("invalid steam login").build();
			}

		} else {
			final String username = jbody.get("username").getTextValue();
			final String password = jbody.get("password").getTextValue();
			account = loginVbb(username, password, request);
		}

		if (account == null) {
			logger.error("AuthSvc no account " + ip + " steamId=" + steamId);
			return Response.serverError().entity("account_error").build();
		}

		if (!account.enabled) {
			logger.warn("AuthSvc not enabled " + ip + " " + account);
			return Response.status(Status.UNAUTHORIZED).entity("account_disabled").build();
		}

		if (jbody.has("child_number")) {
			int child_number = jbody.get("child_number").getValueAsInt();

			if (child_number > 0) {

				final AccountData child = loginChild(account, child_number);

				if (child == null) {
					logger.error("AuthSvc child error " + account + " " + child_number);
					return Response.serverError().entity("child_error").build();
				}

				child.updateDisplayName(WebConfig.instance.rdsDatasource, account.display_name + ":" + child_number);
				account = child;
			}
		}

		final JsonNode ccdv = jbody.get("client_config");
		logger.info("Authenticated " + account + ", body=" + ccdv.toString());
		final ClientConfigData ccd = new ClientConfigData(ccdv);

		UserData user;
		try {
			user = AccountInit.initializeAccount(WebConfig.instance, account);
		} catch (SQLException e) {
			return Response.serverError().entity("Failed to initialize account").build();
		}

		final SessionData session = SessionData.generate(WebConfig.instance, account, ip, ccd, user.login_count);

		if (session == null) {
			logger.error("AuthSvc no session" + account);
			return Response.serverError().build();
		}

		final HashMap<String, Object> rsp = new HashMap<String, Object>();
		rsp.put("user_id", account.account_id);

		// let the user know about any ongoing system messages
		final String sm = WebConfig.instance.systemMessage.getSystemMessage();
		if (sm != null && !sm.isEmpty()) {
			rsp.put("system_msg", sm);
		}

		// we pass session_key as string because flash can't handle 64 bits
		rsp.put("session_key", session.getSessionKeyString());
		rsp.put("build_number", WebConfig.instance.BUILD_NUMBER);
		rsp.put("vbb_name", account.vbb_name);
		rsp.put("display_name", account.display_name);

		if (user.login_count == 1) {
			NewRelic.incrementCounter("Custom/login/first");
		}

		NewRelic.incrementCounter("Custom/login/ok");

		return Response.ok(JSON.toString(rsp)).build();
	}
}
