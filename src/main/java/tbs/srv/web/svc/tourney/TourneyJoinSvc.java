package tbs.srv.web.svc.tourney;

import java.sql.SQLException;
import java.util.HashMap;

import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON;

import tbs.srv.battle.BattleRanking;
import tbs.srv.data.TourneyDef;
import tbs.srv.db.models.SessionData;
import tbs.srv.db.models.UserData;
import tbs.srv.util.RenownReason;
import tbs.srv.util.Tourney;
import tbs.srv.util.TourneyProgressData;
import tbs.srv.web.WebConfig;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class TourneyJoinSvc {

	public static final Logger logger = Logger.getLogger(TourneyJoinSvc.class.getSimpleName());

	@SuppressWarnings("unchecked")
	@Path("/{sessionKey}")
	@POST
	public Response post(String vars, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		final HashMap<String, Object> body = (HashMap<String, Object>) JSON.parse(vars);

		final int tourney_id = ((Number) body.get("tourney_id")).intValue();

		final Tourney t = Tourney.get(tourney_id);
		if (t == null) {
			logger.warn("No such tourney: " + tourney_id);
			return Response.status(Status.BAD_REQUEST).entity("no such tourney").build();
		}

		if (!t.started) {
			logger.warn("Tourney not started: " + tourney_id);
			return Response.status(Status.BAD_REQUEST).entity("tourney not started").build();
		}

		if (t.ended) {
			logger.warn("Tourney already ended: " + tourney_id);
			return Response.status(Status.BAD_REQUEST).entity("tourney already ended").build();
		}

		BattleRanking br = BattleRanking.get(session.account_id, tourney_id, false);
		if (br != null) {
			logger.warn("Already joined: " + tourney_id);
			return Response.status(Status.BAD_REQUEST).entity("already joined").build();
		}

		final TourneyDef td = t.def;

		if (td.entry_fee > 0) {
			int renown;
			try {
				renown = UserData.loadRenown(session.account_id);
			} catch (SQLException e) {
				return Response.serverError().entity("Failed to load renown").build();
			}
			if (renown < td.entry_fee) {
				logger.error("Not enough renown: " + tourney_id);
				return Response.status(Status.BAD_REQUEST).entity("not enough renown").build();
			}
		}

		final TourneyProgressData prog = t.join(session.account_id);

		if (td.entry_fee > 0) {
			WebConfig.instance.renown.modifyRenown(session.account_id, -td.entry_fee, RenownReason.TOURNAMENT_ENTRY, Integer.toString(tourney_id));
		}

		return Response.ok(JSON.toString(prog)).build();
	}
}
