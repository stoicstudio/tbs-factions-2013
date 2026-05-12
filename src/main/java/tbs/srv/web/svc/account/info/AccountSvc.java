package tbs.srv.web.svc.account.info;

import java.sql.SQLException;
import java.util.HashMap;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON;

import tbs.srv.db.models.SessionData;
import tbs.srv.db.models.UserData;
import tbs.srv.util.GameConfig;
import tbs.srv.util.Tourney;
import tbs.srv.web.WebConfig;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class AccountSvc {

	public static final Logger logger = Logger.getLogger(AccountSvc.class.getSimpleName());

	@Path("/{sessionKey}")
	@GET
	public Response get(@PathParam("sessionKey") String sessionKey) throws SQLException {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		final UserData user = new UserData(WebConfig.instance.rdsDatasource, WebConfig.instance, session.account_id);

		final HashMap<String, Object> ai = new HashMap<String, Object>();
		final HashMap<String, Object> roster = new HashMap<String, Object>();

		roster.put("defs", user.rosterDefs.values().toArray());
		ai.put("roster", roster);

		final HashMap<String, Object> partyVars = new HashMap<String, Object>();

		partyVars.put("ids", user.party);
		ai.put("party", partyVars);
		ai.put("renown", user.renown);
		ai.put("purchasable_units", WebConfig.instance.purchasable_units);
		ai.put("daily_login_streak", user.daily_login_streak);
		ai.put("daily_login_bonus", user.daily_login_bonus);
		ai.put("unlocks", user.unlocks);
		ai.put("purchases", user.purchases);
		ai.put("roster_rows", user.roster_rows);
		ai.put("iap_sandbox", GameConfig.instance.STEAM_MICRO_TXN_SANDBOX);
		ai.put("completed_tutorial", user.completed_tutorial);
		ai.put("login_count", user.login_count);

		Tourney.requestSendStateToPlayer(user.account_id);

		final String body = JSON.toString(ai);
		return Response.ok(body).build();
	}

}
