package tbs.srv.web.svc.account.tutorial;

import java.sql.SQLException;

import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import org.apache.log4j.Logger;

import tbs.srv.db.models.SessionData;
import tbs.srv.db.models.UserData;
import tbs.srv.web.WebConfig;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class AccountTutorialSvc {

	public static final Logger logger = Logger.getLogger(AccountTutorialSvc.class.getSimpleName());

	@Path("/{sessionKey}")
	@POST
	public Response post(String vars, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		try {
			UserData.saveTutorialCompleted(session.account_id);
		} catch (SQLException e) {
			return Response.serverError().entity("Failed to save tutorial").build();
		}
		

		return Response.ok().build();
	}
}
