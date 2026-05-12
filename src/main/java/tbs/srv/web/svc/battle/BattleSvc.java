package tbs.srv.web.svc.battle;

import java.util.HashMap;

import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON;

import tbs.srv.battle.BattleReplay;
import tbs.srv.battle.BattleSystem;
import tbs.srv.battle.data.BattleQueryData;
import tbs.srv.battle.data.BattleReplayData;
import tbs.srv.battle.data.base.BaseBattleData;
import tbs.srv.battle.data.client.BattleActionData;
import tbs.srv.battle.data.client.BattleDeltaData;
import tbs.srv.battle.data.client.BattleDeployData;
import tbs.srv.battle.data.client.BattleExitData;
import tbs.srv.battle.data.client.BattleKilledData;
import tbs.srv.battle.data.client.BattleMoveData;
import tbs.srv.battle.data.client.BattleReadyData;
import tbs.srv.battle.data.client.BattleSurrenderData;
import tbs.srv.battle.data.client.BattleSyncData;
import tbs.srv.db.models.SessionData;
import tbs.srv.web.WebConfig;

@Path("")
@SuppressWarnings("unchecked")
@Produces(MediaType.APPLICATION_JSON)
public class BattleSvc {

	private static final Logger logger = Logger.getLogger(BattleSvc.class.getSimpleName());

	private Response process(String vars, String sessionKey, Class<? extends BaseBattleData> clazz, final String tag) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		HashMap<String, Object> data = null;
		try {
			data = (HashMap<String, Object>) JSON.parse(vars);
		} catch (Exception exp) {
			logger.warn("INVALID BATTLE MSG " + tag + " [" + vars + "]: " + exp);
			return Response.status(Status.BAD_REQUEST).build();
		}

		if (data == null) {
			logger.warn("Data parsed without error, but is null, " + tag + ": " + vars);
			return Response.status(Status.BAD_REQUEST).build();
		}

		BaseBattleData msg;
		try {
			msg = (BaseBattleData) clazz.newInstance();
		} catch (InstantiationException e) {
			logger.error("Failed to process " + clazz + ": " + e);
			return Response.serverError().build();
		} catch (IllegalAccessException e) {
			logger.error("Failed to process " + clazz + ": " + e);
			return Response.serverError().build();
		}

		data.put("user_id", session.account_id);
		msg.fromJSON(data);

		if (msg instanceof BattleKilledData) {
			logger.info("killed " + msg);
		}

		// new BattleMoveData(session.userId, data);

		logger.debug("Process " + msg);
		BattleSystem.send(msg);

		Response ret = WebConfig.instance.msg.getResponse(tag, session.account_id);

		return ret;
	}

	@Path("/action/{sessionKey}")
	@POST
	public Response action(String vars, @PathParam("sessionKey") String sessionKey) {
		Response ret = process(vars, sessionKey, BattleActionData.class, "BattleSvc.action");

		return ret;
	}

	@Path("/delta/{sessionKey}")
	@POST
	public Response delta(String vars, @PathParam("sessionKey") String sessionKey) {
		return process(vars, sessionKey, BattleDeltaData.class, "BattleSvc.delta");
	}

	@Path("/deploy/{sessionKey}")
	@POST
	public Response deploy(String vars, @PathParam("sessionKey") String sessionKey) {
		return process(vars, sessionKey, BattleDeployData.class, "BattleSvc.deploy");
	}

	@Path("/move/{sessionKey}")
	@POST
	public Response move(String vars, @PathParam("sessionKey") String sessionKey) {
		return process(vars, sessionKey, BattleMoveData.class, "BattleSvc.move");
	}

	@Path("/ready/{sessionKey}")
	@POST
	public Response ready(String vars, @PathParam("sessionKey") String sessionKey) {
		return process(vars, sessionKey, BattleReadyData.class, "BattleSvc.ready");
	}

	@Path("/surrender/{sessionKey}")
	@POST
	public Response surrender(String vars, @PathParam("sessionKey") String sessionKey) {
		Response ret = process(vars, sessionKey, BattleSurrenderData.class, "BattleSvc.surrender");

		return ret;
	}

	@Path("/sync/{sessionKey}")
	@POST
	public Response sync(String vars, @PathParam("sessionKey") String sessionKey) {
		return process(vars, sessionKey, BattleSyncData.class, "BattleSvc.sync");
	}

	@Path("/exit/{sessionKey}")
	@POST
	public Response exit(String vars, @PathParam("sessionKey") String sessionKey) {
		return process(vars, sessionKey, BattleExitData.class, "BattleSvc.exit");
	}

	@Path("/killed/{sessionKey}")
	@POST
	public Response killed(String vars, @PathParam("sessionKey") String sessionKey) {
		return process(vars, sessionKey, BattleKilledData.class, "BattleSvc.killed");
	}

	@Path("/query/{sessionKey}")
	@POST
	public Response query(String vars, @PathParam("sessionKey") String sessionKey) {

		return process(vars, sessionKey, BattleQueryData.class, "BattleSvc.query");
	}

	@Path("/replay/{sessionKey}")
	@POST
	public Response replay(String vars, @PathParam("sessionKey") String sessionKey) {
		final String battle_id = vars;
		final BattleReplayData data = BattleReplay.getReplay(WebConfig.instance, battle_id);
		if (data != null) {
			return Response.ok(JSON.toString(data)).build();
		}
		return Response.status(Status.BAD_REQUEST).build();
	}

}
