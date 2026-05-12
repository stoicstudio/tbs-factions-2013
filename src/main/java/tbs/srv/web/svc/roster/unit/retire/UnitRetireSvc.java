package tbs.srv.web.svc.roster.unit.retire;

import java.sql.SQLException;

import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import org.apache.log4j.Logger;
import org.codehaus.jackson.JsonNode;
import org.codehaus.jackson.map.ObjectMapper;

import tbs.srv.db.models.SessionData;
import tbs.srv.db.models.UserData;
import tbs.srv.web.WebConfig;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class UnitRetireSvc {

	public static final Logger logger = Logger.getLogger(UnitRetireSvc.class.getSimpleName());

	@Path("/{sessionKey}")
	@POST
	public Response retire_unit(String body, @PathParam("sessionKey") String sessionKey) {

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

		logger.info("Retiring " + session + " " + unit_id);

		try {
			user.retireUnit(WebConfig.instance.rdsDatasource, unit_id);
		} catch (SQLException e) {
			return Response.serverError().entity("Failed to retire unit").build();
		}

		return Response.ok(body).build();
	}

}
