package tbs.srv.web.svc.session.steam.overlay;

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
public class SessionSteamOverlaySvc {

	public static final Logger logger = Logger.getLogger(SessionSteamOverlaySvc.class.getSimpleName());

	@Path("/{sessionKey}/{overlay}")
	@POST
	public Response post(@PathParam("sessionKey") String sessionKey, @PathParam("overlay") boolean overlay) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);
		session.setSteamOverlay(overlay);
		return Response.ok().build();
	}
}
