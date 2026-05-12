package tbs.srv.web.svc.roster.unit.promote;

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

import tbs.srv.data.CharacterClassDef;
import tbs.srv.data.EntityDef;
import tbs.srv.data.StatType;
import tbs.srv.db.models.SessionData;
import tbs.srv.db.models.UserData;
import tbs.srv.util.RenownReason;
import tbs.srv.web.WebConfig;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class UnitPromoteSvc {

	public static final Logger logger = Logger.getLogger(UnitPromoteSvc.class.getSimpleName());

	@Path("/{sessionKey}")
	@POST
	public Response promote_unit(String body, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		JsonNode jbody = null;
		try {
			ObjectMapper mapper = new ObjectMapper();
			jbody = mapper.readTree(body);
		} catch (Exception e) {
			logger.error("promote_unit: " + e);
		}

		final String class_id = jbody.path("class_id").getValueAsText();
		final String name = jbody.path("name").getValueAsText();
		final String unit_id = jbody.path("unit_id").getValueAsText();

		EntityDef entity;
		try {
			entity = UserData.loadRosterUnit(session.account_id, unit_id);
		} catch (SQLException e1) {
			return Response.serverError().entity("Failed to load entity").build();
		}

		if (entity == null) {
			return Response.status(Status.BAD_REQUEST).entity("No such unit: " + unit_id).build();
		}

		final CharacterClassDef classDef = WebConfig.instance.getCharacterClassDef(class_id);
		if (classDef == null) {
			return Response.status(Status.BAD_REQUEST).entity("No such class: " + class_id).build();
		}

		final int rank = entity.getStatValue(StatType.RANK);

		final int cost = WebConfig.instance.statCosts.getPromotionCost(rank);

		int renown = 0;
		try {
			renown = UserData.loadRenown(session.account_id);
		} catch (SQLException e1) {
			return Response.serverError().entity("Failed to load renown").build();
		}

		if (cost > renown) {
			return Response.status(Status.BAD_REQUEST).entity("Not enough renown " + cost + "/" + renown).build();
		}

		final int nextRank = rank + 1;

		logger.info("PROMOTE UNIT " + " " + session.display_name + ":" + unit_id + ", class=" + class_id + " rank=" + nextRank);

		if (entity.entityClass.equals(classDef.id)) {
			// trying to rank up, not take an advanced class
			final int maxRank = entity.characterClassDef.getStatRangeByName(StatType.RANK.name()).max;

			if (rank >= maxRank) {
				return Response.status(Status.BAD_REQUEST).entity("Already at max rank: " + rank + "/" + maxRank).build();
			}
		} else {
			if (!entity.entityClass.equals(classDef.parent)) {
				return Response.status(Status.BAD_REQUEST).entity("Class " + entity.entityClass + " not promotable to: " + class_id).build();
			}

			entity.entityClass = class_id;
			entity.setClassDef(WebConfig.instance, true);
		}

		if (name != null) {
			entity.setName(name);
		}

		// we no longer reset stats on promotion

		entity.setStat(StatType.RANK, nextRank);

		try {
			UserData.saveRosterMember(WebConfig.instance.rdsDatasource, session.account_id, entity);
		} catch (SQLException e) {
			return Response.serverError().entity("Failed to save roster member").build();
		}

		WebConfig.instance.renown.modifyRenown(session.account_id, -cost, RenownReason.PROMOTE, "AccountSvc.promote_unit");

		return Response.ok(body).build();
	}

}
