package tbs.srv.web.svc.roster.unlock;

import java.io.IOException;
import java.sql.SQLException;

import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.apache.log4j.Logger;
import org.codehaus.jackson.JsonProcessingException;

import tbs.srv.db.models.SessionData;
import tbs.srv.db.models.UserData;
import tbs.srv.util.GameConfig;
import tbs.srv.util.RenownReason;
import tbs.srv.web.WebConfig;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class RosterRowUnlockSvc {

	public static final Logger logger = Logger.getLogger(RosterRowUnlockSvc.class.getSimpleName());

	@Path("/{sessionKey}")
	@POST
	public Response post(String body, @PathParam("sessionKey") String sessionKey) throws JsonProcessingException, IOException {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		logger.info("unlock " + session);

		int roster_rows;
		try {
			roster_rows = UserData.loadRosterRows(session.account_id);
		} catch (SQLException e) {
			return Response.serverError().entity("Failed to load roster rows").build();
		}

		if (roster_rows >= GameConfig.instance.statCosts.max_num_roster_rows) {
			return Response.status(Status.BAD_REQUEST).entity("max rows").build();
		}

		int renown;
		try {
			renown = UserData.loadRenown(session.account_id);
		} catch (SQLException e) {
			return Response.serverError().entity("Failed to load renown").build();
		}

		final int cost = GameConfig.instance.statCosts.roster_row_cost;
		if (renown < cost) {
			return Response.status(Status.BAD_REQUEST).entity("insufficient renown").build();
		}

		try {
			UserData.saveRosterRows(session.account_id, roster_rows + 1);
		} catch (SQLException e) {
			return Response.serverError().entity("Failed to save roster rows").build();
		}

		GameConfig.instance.renown.modifyRenown(session.account_id, -cost, RenownReason.ROSTER_SLOT, Integer.toString(roster_rows));

		return Response.ok(body).build();
	}

}
