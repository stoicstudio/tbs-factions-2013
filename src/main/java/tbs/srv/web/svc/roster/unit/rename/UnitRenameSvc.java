package tbs.srv.web.svc.roster.unit.rename;

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

import tbs.srv.data.EntityDef;
import tbs.srv.db.models.SessionData;
import tbs.srv.db.models.UserData;
import tbs.srv.util.RenownReason;
import tbs.srv.web.WebConfig;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class UnitRenameSvc {

	public static final Logger logger = Logger.getLogger(UnitRenameSvc.class.getSimpleName());

	@Path("/{sessionKey}")
	@POST
	public Response rename_unit(String body, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);
		UserData user;
		try {
			user = new UserData(WebConfig.instance.rdsDatasource, WebConfig.instance, session.account_id);
		} catch (SQLException e1) {
			return Response.serverError().entity("Failed to load userdata").build();
		}

		JsonNode jbody = null;
		try {
			ObjectMapper mapper = new ObjectMapper();
			jbody = mapper.readTree(body);
		} catch (Exception e) {
			logger.error("rename: " + e);
		}

		final String unit_id = jbody.path("unit_id").getValueAsText();
		final String name = jbody.path("name").getValueAsText();

		final int cost = WebConfig.instance.statCosts.getRenameCost();

		if (user.renown < cost) {
			return Response.status(Status.BAD_REQUEST).entity("Not enough renown").build();
		}

		logger.info("Renaming " + session + " " + unit_id + " " + name);

		EntityDef.saveName(WebConfig.instance.rdsDatasource, user.account_id, unit_id, name);

		WebConfig.instance.renown.modifyRenown(user.account_id, -cost, RenownReason.RENAME, unit_id);

		return Response.ok(body).build();
	}

}
