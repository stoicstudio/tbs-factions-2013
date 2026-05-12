package tbs.srv.web.svc.game;

import javax.ws.rs.GET;
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
public class GameSvc {

	public static final Logger logger = Logger.getLogger(GameSvc.class.getSimpleName());

	@Path("/check")
	@GET
	public Response get() {

		try {
			Thread.sleep(1000);
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return Response.ok("ok " + System.currentTimeMillis()).build();
	}

	@Path("/{sessionKey}")
	@GET
	public Response get(@PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		return WebConfig.instance.msg.getResponse("GameSvc.get", session.account_id);
	}
}