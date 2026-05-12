package tbs.srv.web.svc.roster.unit.stats;

import java.sql.SQLException;

import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.apache.log4j.Logger;
import org.codehaus.jackson.JsonNode;
import org.codehaus.jackson.map.ObjectMapper;
import org.codehaus.jackson.node.ArrayNode;

import tbs.srv.data.EntityDef;
import tbs.srv.data.Stat;
import tbs.srv.data.StatRange;
import tbs.srv.data.StatType;
import tbs.srv.db.models.SessionData;
import tbs.srv.db.models.UserData;
import tbs.srv.util.RenownReason;
import tbs.srv.web.WebConfig;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class UnitStatsSvc {

	public static final Logger logger = Logger.getLogger(UnitStatsSvc.class.getSimpleName());

	private String purfix(final SessionData session, final EntityDef unit) {
		return "PURCHASE STAT " + session + ":" + unit.id + "(" + unit.entityClass + ")/" + unit.getStatValue(StatType.RANK) + " ";
	}

	@Path("/purchase/{sessionKey}")
	@POST
	public Response purchase_stats(String body, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		JsonNode jbody = null;
		try {
			ObjectMapper mapper = new ObjectMapper();
			jbody = mapper.readTree(body);
		} catch (Exception e) {
			logger.error("purchase_stats: " + e);
		}

		final String unit_id = jbody.path("unit_id").getValueAsText();
		final ArrayNode stats = (ArrayNode) jbody.path("stats");
		final ArrayNode deltas = (ArrayNode) jbody.path("deltas");

		if (stats.size() != deltas.size()) {
			return Response.status(Status.BAD_REQUEST).entity("Stats and deltas don't match").build();
		}

		EntityDef entity;
		try {
			entity = UserData.loadRosterUnit(session.account_id, unit_id);
		} catch (SQLException e1) {
			return Response.serverError().entity("Failed to load entity").build();
		}

		if (entity == null) {
			return Response.status(Status.BAD_REQUEST).entity("No such unit " + unit_id).build();
		}

		int totalCost = 0;
		for (int i = 0; i < stats.size(); ++i) {
		}

		int renown = 0;
		try {
			renown = UserData.loadRenown(session.account_id);
		} catch (SQLException e1) {
			return Response.serverError().entity("Failed to load renown").build();
		}

		if (totalCost > renown) {
			logger.error(purfix(session, entity) + "INSUFFICIENT RENOWN " + totalCost + "/" + renown);
			return Response.status(Status.BAD_REQUEST).entity("Not enough renown: " + totalCost + "/" + renown).build();
		}

		final int rank = entity.getStatValue(StatType.RANK);

		for (int i = 0; i < stats.size(); ++i) {
			final String statName = stats.get(i).getTextValue();
			final int delta = deltas.get(i).getIntValue();
			final int value = entity.getStatValue(statName);
			final StatType stat = StatType.valueOf(statName);

			if (!stat.purchaseable) {
				logger.error(purfix(session, entity) + "UNPURCHASABLE " + stat);
				return Response.status(Status.BAD_REQUEST).entity("Stat " + stat + " not purchasable").build();
			}

			if (!entity.hasStat(statName)) {
				logger.error(purfix(session, entity) + "INVALID " + stat);
				return Response.status(Status.BAD_REQUEST).entity("No such stat: " + statName).build();
			}

			final int next = value + delta;
			final StatRange sr = entity.characterClassDef.getStatRangeByName(stat.name());
			if (!sr.validate(next)) {
				logger.warn(purfix(session, entity) + "OUT OF RANGE " + stat + ", " + next);
				return Response.status(Status.BAD_REQUEST).entity("Stat goes out of range: " + next + ", " + sr).build();
			}

			final int cost = WebConfig.instance.statCosts.getTotalCost(rank, delta);
			totalCost += cost;

			entity.setStat(statName, value + delta);
			final int result = entity.getStatValue(statName);

			logger.debug(purfix(session, entity) + statName + ", " + value + " + " + delta + " = " + result);
		}

		final int upg = entity.getUpgrades();
		final int max = entity.getMaxUpgrades();
		if (upg > max) {
			logger.warn(purfix(session, entity) + "ATTEMPT TO OVER-UPGRADE " + upg + "/" + max);

			for (Stat stat : entity.stats.values()) {
				final StatRange sr = entity.characterClassDef.getStatRangeByName(stat.stat);
				if (sr != null) {
					logger.warn(purfix(session, entity) + "ATTEMPT " + stat.stat + " = " + stat.get() + " > " + sr.min);
				}
			}
			return Response.status(Status.BAD_REQUEST).entity("Can't upgrade past max: " + upg + "/" + max).build();
		}

		entity.saveDirty(WebConfig.instance.rdsDatasource, session.account_id);

		if (totalCost != 0) {
			WebConfig.instance.renown.modifyRenown(session.account_id, -totalCost, RenownReason.UPGRADE, "AccountSvc.purchase_stats");
		}

		return Response.ok(body).build();
	}

}
