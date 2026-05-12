package tbs.srv.web.svc.roster.unit.hire;

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
import org.codehaus.jackson.JsonNode;
import org.codehaus.jackson.JsonProcessingException;
import org.codehaus.jackson.map.ObjectMapper;

import tbs.srv.data.EntityDef;
import tbs.srv.data.PurchasableUnitData;
import tbs.srv.db.models.SessionData;
import tbs.srv.db.models.UserData;
import tbs.srv.util.RenownReason;
import tbs.srv.web.WebConfig;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class UnitHireSvc {

	public static final Logger logger = Logger.getLogger(UnitHireSvc.class.getSimpleName());

	@Path("/{sessionKey}")
	@POST
	public Response hire_roster_unit(String body, @PathParam("sessionKey") String sessionKey) throws JsonProcessingException, IOException {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		UserData user;
		try {
			user = new UserData(WebConfig.instance.rdsDatasource, WebConfig.instance, session.account_id);
		} catch (SQLException e) {
			return Response.serverError().entity("Failed to load userdata").build();
		}

		final ObjectMapper mapper = new ObjectMapper();
		final JsonNode jbody = mapper.readTree(body);

		final String purchasable_unit_id = jbody.path("purchasable_unit_id").getValueAsText();
		final String new_unit_id = jbody.path("new_unit_id").getValueAsText();
		final String new_unit_name = jbody.path("new_unit_name").getValueAsText();

		final PurchasableUnitData pu = WebConfig.instance.purchasable_units.get(purchasable_unit_id);
		if (pu == null) {
			return Response.status(Status.BAD_REQUEST).entity("No such purchasable unit " + purchasable_unit_id).build();
		}

		final EntityDef old = user.rosterDefs.get(new_unit_id);
		if (old != null) {
			return Response.status(Status.BAD_REQUEST).entity("already have unit " + new_unit_id).build();
		}

		if (user.renown < pu.cost) {
			return Response.status(Status.BAD_REQUEST).entity("not enough renown " + user.renown + "/" + pu.cost).build();
		}

		final EntityDef d = pu.def.duplicate(new_unit_id);
		d.start_date = System.currentTimeMillis();
		d.setName(new_unit_name);
		user.rosterDefs.put(new_unit_id, d);
		try {
			user.saveRosterMember(WebConfig.instance.rdsDatasource, new_unit_id);
		} catch (SQLException e) {
			return Response.serverError().entity("Failed to save roster member").build();
		}

		logger.info("HIRE UNIT " + " " + session + " " + d);

		WebConfig.instance.renown.modifyRenown(user.account_id, -pu.cost, RenownReason.HIRE, "AccountSvc.hire_roster_unit");

		return Response.ok(body).build();
	}

}
