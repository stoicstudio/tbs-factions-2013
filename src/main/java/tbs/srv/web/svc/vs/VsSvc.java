package tbs.srv.web.svc.vs;

import java.util.HashMap;

import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import org.eclipse.jetty.util.ajax.JSON;

import tbs.srv.data.ServerStatusData;
import tbs.srv.db.models.SessionData;
import tbs.srv.util.VsType;
import tbs.srv.web.WebConfig;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class VsSvc {

	@Path("/cancel/{sessionKey}")
	@POST
	public Response cancel(String vars, @PathParam("sessionKey") String sessionKey) {

		SessionData session = WebConfig.instance.getSession(sessionKey);

		@SuppressWarnings("unchecked")
		HashMap<String, Object> body = (HashMap<String, Object>) JSON.parse(vars);
		final int match_handle = ((Number) body.get("match_handle")).intValue();

		WebConfig.instance.vs.cancel(session.account_id, match_handle);

		final Response response = WebConfig.instance.msg.getResponse("VsSvc.cancel", session.account_id);

		return response;
	}

	@Path("/start/{sessionKey}")
	@POST
	public Response start(final String vars, @PathParam("sessionKey") String sessionKey) {

		SessionData session = WebConfig.instance.getSession(sessionKey);

		@SuppressWarnings("unchecked")
		final HashMap<String, Object> body = (HashMap<String, Object>) JSON.parse(vars);
		final Object[] party = (Object[]) body.get("party");
		long forcematch = 0;
		if (body.containsKey("forcematch")) {
			final Long forcematchId = (Long) body.get("forcematch");
			forcematch = forcematchId != null ? forcematchId.longValue() : 0;
		}
		String scene = (String) body.get("scene");

		final int match_handle = ((Number) body.get("match_handle")).intValue();

		final int timer = ((Number) body.get("timer")).intValue();
		final int tourney_id = ((Number) body.get("tourney_id")).intValue();
		final VsType type = VsType.valueOf((String) body.get("vs_type"));

		WebConfig.instance.vs.start(session.getSessionKey(), session.account_id, session.display_name, party, forcematch, scene, timer, type, match_handle,
				tourney_id);

		final ServerStatusData msg = new ServerStatusData(SessionData.getSessionCount(WebConfig.instance.rdsDatasource));

		final Response response = WebConfig.instance.msg.getResponse("VsSvc.start", session.account_id, msg);

		return response;
	}

}
