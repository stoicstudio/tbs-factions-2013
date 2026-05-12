package tbs.srv.web.svc.roster.party;

import java.sql.SQLException;
import java.util.Arrays;

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
import tbs.srv.util.LobbySystem;
import tbs.srv.web.WebConfig;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class PartySvc {

	public static final Logger logger = Logger.getLogger(PartySvc.class.getSimpleName());

	@Path("/arrange/{sessionKey}")
	@POST
	public Response arrange_party(String body, @PathParam("sessionKey") String sessionKey) {

		SessionData session = WebConfig.instance.getSession(sessionKey);

		UserData user;
		try {
			user = new UserData(WebConfig.instance.rdsDatasource, WebConfig.instance, session.account_id);
		} catch (SQLException e1) {
			logger.error("arrange_party " + session + " no userdata");
			return Response.serverError().entity("Failed to load userdata").build();
		}

		JsonNode jbody = null;
		try {
			ObjectMapper mapper = new ObjectMapper();
			jbody = mapper.readTree(body);
		} catch (Exception e) {
			logger.error("arrange_party: " + e);
		}

		final JsonNode party = jbody.path("party");
		Object[] pids = new Object[party.size()];
		for (int i = 0; i < party.size(); ++i) {
			final String id = party.get(i).getTextValue();
			pids[i] = id;

			if (user.getRosterDef(id) == null) {
				logger.error("arrange_party " + session + " bad entity " + id);
				return Response.status(Status.BAD_REQUEST).entity("no such " + session + " party def: " + id).build();
			}
		}

		logger.info("arrange_party " + session + " " + Arrays.toString(pids));

		if (user.setParty(pids)) {
			try {
				user.saveParty(WebConfig.instance.rdsDatasource);
			} catch (SQLException e) {
				logger.error("arrange_party " + session + " failed to save party");
				return Response.serverError().entity("Failed to save party").build();
			}
		}

		final JsonNode lobby = jbody.path("lobby");
		if (!lobby.isNull()) {
			try {
				final EntityDef[] pd = user.getPartyDefs();
				LobbySystem.notifyParty(WebConfig.instance, lobby.getLongValue(), session.account_id, pd, pids);
			} catch (Exception e) {
				logger.error("Could not get " + session + " party defs: " + e);
				return Response.status(Status.BAD_REQUEST).entity("invalid party defs").build();
			}
		}

		return Response.ok().build();

	}

}
