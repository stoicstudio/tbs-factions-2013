package tbs.srv.web.svc.lobby;

import java.util.Map;

import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON;

import tbs.srv.data.LobbyData;
import tbs.srv.data.LobbyOptionsData;
import tbs.srv.db.models.SessionData;
import tbs.srv.util.LobbySystem;
import tbs.srv.web.WebConfig;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class LobbySvc {

	public static final Logger logger = Logger.getLogger(LobbySvc.class.getSimpleName());

	@SuppressWarnings("rawtypes")
	@Path("/invite/{sessionKey}")
	@POST
	public Response invite(String body, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		final LobbyOptionsData data = new LobbyOptionsData();
		data.fromJSON((Map) JSON.parse(body));
		data.type = LobbyData.Type.INVITE.name();

		LobbySystem.invite(WebConfig.instance, data);
		return WebConfig.instance.msg.getResponse("LobbySvc", session.account_id);
	}

	@Path("/uninvite/{sessionKey}")
	@POST
	public Response uninvite(String body, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);
		final long invitee = Long.parseLong(body);

		LobbySystem.uninvite(WebConfig.instance, session.account_id, invitee, "need user displayname here");
		return WebConfig.instance.msg.getResponse("LobbySvc", session.account_id);
	}

	@Path("/exit/{sessionKey}")
	@POST
	public Response exit(String body, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);
		final long lobby_id = Long.parseLong(body);

		LobbySystem.exit(WebConfig.instance, lobby_id, session.account_id, session.display_name);

		return WebConfig.instance.msg.getResponse("LobbySvc", session.account_id);
	}

	@Path("/join/{sessionKey}")
	@POST
	public Response join(String body, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);
		final long lobby_id = Long.parseLong(body);

		LobbySystem.join(WebConfig.instance, lobby_id, session.account_id);

		return WebConfig.instance.msg.getResponse("LobbySvc", session.account_id);
	}

	@Path("/decline/{sessionKey}")
	@POST
	public Response decline(String body, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);
		final long lobby_id = Long.parseLong(body);

		LobbySystem.decline(WebConfig.instance, lobby_id, session.account_id, session.display_name);

		return WebConfig.instance.msg.getResponse("LobbySvc", session.account_id);
	}

	@SuppressWarnings("rawtypes")
	@Path("/options/{sessionKey}")
	@POST
	public Response options(String body, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		final LobbyOptionsData data = new LobbyOptionsData();
		data.fromJSON((Map) JSON.parse(body));
		data.type = LobbyData.Type.OPTIONS.name();

		LobbySystem.option(WebConfig.instance, data);

		return WebConfig.instance.msg.getResponse("LobbySvc", session.account_id);
	}

	@Path("/ready/{sessionKey}")
	@POST
	public Response ready(String body, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);
		final long lobby_id = Long.parseLong(body);
		LobbySystem.ready(WebConfig.instance, lobby_id, session.account_id);

		return WebConfig.instance.msg.getResponse("LobbySvc", session.account_id);
	}

	@Path("/unready/{sessionKey}")
	@POST
	public Response unready(String body, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);
		long lobby_id = 0;
		try {
			lobby_id = Long.parseLong(body);
		} catch (Exception exp) {
			return Response.status(Status.BAD_REQUEST).entity("invalid lobby").build();
		}

		LobbySystem.unready(WebConfig.instance, lobby_id, session.account_id);

		return WebConfig.instance.msg.getResponse("LobbySvc", session.account_id);
	}
}