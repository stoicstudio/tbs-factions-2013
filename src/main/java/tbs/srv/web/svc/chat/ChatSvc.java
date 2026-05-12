package tbs.srv.web.svc.chat;

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
public class ChatSvc {

	public static final Logger logger = Logger.getLogger(ChatSvc.class);

	@Path("/{room}/{sessionKey}")
	@POST
	public Response post(String vars, @PathParam("sessionKey") String sessionKey, @PathParam("room") String room) throws IOException {

		final SessionData session = WebConfig.instance.getSession(sessionKey);
		WebConfig.instance.chat.sendToRoom(session.getSessionKey(), session.account_id, session.display_name, room, vars);
		return Response.ok().build();
	}

}