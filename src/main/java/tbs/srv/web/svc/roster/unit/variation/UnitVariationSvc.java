package tbs.srv.web.svc.roster.unit.variation;

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

import tbs.srv.data.AppearanceDef;
import tbs.srv.data.EntityDef;
import tbs.srv.db.models.SessionData;
import tbs.srv.db.models.UserData;
import tbs.srv.util.GameConfig;
import tbs.srv.util.LobbySystem;
import tbs.srv.util.RenownReason;
import tbs.srv.web.WebConfig;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class UnitVariationSvc {

	public static final Logger logger = Logger.getLogger(UnitVariationSvc.class.getSimpleName());

	@Path("/{sessionKey}/{unit_id}/{variation}/{lobby_id}")
	@POST
	public Response post(String body //
			, @PathParam("sessionKey") String sessionKey //
			, @PathParam("unit_id") String unit_id //
			, @PathParam("variation") int variation //
			, @PathParam("lobby_id") long lobby_id //
	) throws JsonProcessingException, IOException {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		EntityDef unit;
		try {
			unit = UserData.loadRosterUnit(session.account_id, unit_id);
		} catch (SQLException e) {
			return Response.serverError().entity("Failed to load roster unit").build();
		}

		if (unit == null) {
			logger.info("No such unit " + unit_id);
			return Response.status(Status.BAD_REQUEST).entity("invalid unit").build();
		}

		logger.info(session.toString() + ", " + unit + ", " + variation);

		if (unit.appearance_index == variation) {
			logger.info("Unit already using variation " + unit);
			return Response.status(Status.BAD_REQUEST).entity("already using variation").build();
		}

		int cost = 0;

		if (!unit.hasAppearanceAcquired(variation)) {

			cost = GameConfig.instance.statCosts.getVariationCost();

			final AppearanceDef app = unit.characterClassDef.getAppearanceDef(variation);

			if (app == null) {
				logger.warn("User " + session + " INVALID VARIATION for unit " + unit + ", variation " + variation);
				return Response.status(Status.BAD_REQUEST).entity("invalid variation").build();
			}

			if (app.unlock_id != null) {
				if (!UserData.hasUnlock(GameConfig.instance, session.account_id, app.unlock_id)) {
					logger.warn("User " + session + " has not unlocked " + app.unlock_id + ", for unit " + unit + ", variation " + variation);
					return Response.status(Status.BAD_REQUEST).entity("unlock missing").build();
				}
			}

			if (app.acquire_id != null) {
				if (UserData.hasUnlock(GameConfig.instance, session.account_id, app.acquire_id)) {
					logger.debug("User " + session + " has FREE ACQUIRE " + app.acquire_id + ", for unit " + unit + ", variation " + variation);
					cost = 0;
				}
			}

			if (cost > 0) {
				int renown;
				try {
					renown = UserData.loadRenown(session.account_id);
				} catch (SQLException e) {
					return Response.serverError().entity("Failed to load renown").build();
				}

				if (renown < cost) {
					logger.warn("User " + session + " INSUFFICIENT RENOWN for unit " + unit + ", variation " + variation);
					return Response.status(Status.BAD_REQUEST).entity("insufficient renown").build();
				}

				WebConfig.instance.renown.modifyRenown(session.account_id, -cost, RenownReason.VARIATION, "UnitVariationSvc");
			}

			unit.acquireAppearance(variation);
		}

		unit.appearance_index = variation;
		unit.saveAppearance(session.account_id);

		// final HashMap<String, Object> r = new HashMap<String, Object>();
		// r.put("appearance_acquires", unit.appearance_acquires);
		// r.put("appearance_index", unit.appearance_index);

		if (lobby_id > 0) {
			LobbySystem.notifyVariation(lobby_id, session.account_id, unit_id, variation);
		}

		return Response.ok().build();
	}
}
