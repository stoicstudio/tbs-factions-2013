package tbs.srv.web.svc.auth.logout;

import java.io.IOException;

import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import org.apache.log4j.Logger;

import tbs.srv.db.models.SessionData;
import tbs.srv.web.WebConfig;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class LogoutSvc {

	private static final Logger logger = Logger.getLogger(LogoutSvc.class.getSimpleName());

	@POST
	@Path("/{sessionKey}")
	public Response logout(String vars, @PathParam("sessionKey") String sessionKey) throws IOException {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		logger.debug("logout " + session);

		session.stop(WebConfig.instance, false);

		SessionData.recordSessionConcurrency();

		return Response.ok().build();
	}
}
