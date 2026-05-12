package tbs.srv.web.svc.iap.info;

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
public class IapInfoSvc {

	public static final Logger logger = Logger.getLogger(IapInfoSvc.class.getSimpleName());

	@Path("/{sessionKey}")
	@POST
	public Response info(String body, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		logger.info("info: " + session + " " + body);
		return Response.ok().build();

	}
}