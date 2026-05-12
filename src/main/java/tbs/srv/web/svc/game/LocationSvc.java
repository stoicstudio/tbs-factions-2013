package tbs.srv.web.svc.game;

import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import org.apache.log4j.Logger;

import tbs.srv.chat.ChatSystem;
import tbs.srv.db.models.SessionData;
import tbs.srv.util.FriendSystem;
import tbs.srv.util.GameConfig;
import tbs.srv.web.WebConfig;

@Path("/location")
@Produces(MediaType.APPLICATION_JSON)
public class LocationSvc {

	public static final Logger logger = Logger.getLogger(LocationSvc.class.getSimpleName());

	@Path("/{sessionKey}")
	@POST
	public Response post(String body, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);
		final String location = body;

		FriendSystem.notifyLocation(WebConfig.instance.rabbit, session.account_id, location);

		if (location != null) {
			if (location.equals("loc_strand") || location.equals("loc_versus")) {
				GameConfig.instance.chat.getRoom(ChatSystem.ROOM_GLOBAL, true).addMember(session.account_id, session.display_name);
			}
		}

		return Response.ok().build();
	}
}