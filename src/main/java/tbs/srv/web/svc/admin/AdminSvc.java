package tbs.srv.web.svc.admin;

import java.io.IOException;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.apache.log4j.Logger;
import org.codehaus.jackson.map.ObjectMapper;
import org.codehaus.jackson.node.ObjectNode;
import org.eclipse.jetty.util.ajax.JSON;

import tbs.srv.auth.AccountData;
import tbs.srv.db.DbHelper;
import tbs.srv.db.models.SessionData;
import tbs.srv.util.GameConfig;
import tbs.srv.web.WebConfig;

import com.rabbitmq.client.Channel;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class AdminSvc {

	private static final Logger logger = Logger.getLogger(AdminSvc.class.getSimpleName());

	private SessionData checkCredentials(final String sessionKey, final String adminKey, HttpServletRequest request) {

		SessionData session;
		if (!sessionKey.equals("0")) {
			session = WebConfig.instance.getSession(sessionKey);
			final AccountData ad = AccountData.getAccount(GameConfig.instance.rdsDatasource, session.account_id);
			if (!ad.isAdmin()) {
				logger.warn("checkCredentials non-admin " + session);
				throw new WebApplicationException(Response.status(Status.UNAUTHORIZED).entity("non_admin").build());
			}
			logger.info("checkCredentials SESSION " + session + " " + request.getRemoteAddr());

			return session;
		} else {
			if (WebConfig.instance.ADMIN_KEY == null || !WebConfig.instance.ADMIN_KEY.equals(adminKey)) {
				logger.warn("checkCredentials invalid sessionKey=" + sessionKey + " adminKey=" + adminKey);
				throw new WebApplicationException(Response.status(Status.UNAUTHORIZED).entity("unauthorized admin key " + adminKey).build());
			}

			logger.info("checkCredentials ADMIN_KEY " + request.getRemoteAddr());
			return null;
		}
	}

	@Path("/system_msg/{sessionKey}/{adminKey}")
	@GET
	public Response system_msg_get(@PathParam("sessionKey") String sessionKey, @PathParam("adminKey") String adminKey, @Context HttpServletRequest request) {

		checkCredentials(sessionKey, adminKey, request);

		final String msg = WebConfig.instance.systemMessage.getSystemMessage();
		ObjectNode jn = new ObjectMapper().createObjectNode();
		jn.put("msg", msg);
		final String json = jn.toString();
		return Response.ok(json).build();
	}

	@Path("/system_msg/{sessionKey}/{adminKey}")
	@POST
	public Response system_msg(String vars, @PathParam("sessionKey") String sessionKey, @PathParam("adminKey") String adminKey,
			@Context HttpServletRequest request) {

		checkCredentials(sessionKey, adminKey, request);
		WebConfig.instance.systemMessage.setSystemMessage(vars, true);

		return Response.ok().build();
	}

	@Path("/status/{sessionKey}/{adminKey}")
	@GET
	public Response status(@PathParam("sessionKey") String sessionKey, @PathParam("adminKey") String adminKey, @Context HttpServletRequest request) {

		checkCredentials(sessionKey, adminKey, request);

		Connection con = null;
		Statement s = null;
		try {
			con = WebConfig.instance.rdsDatasource.getConnection();
			CallableStatement cs = con.prepareCall("call battle_vitals");
			s = cs;

			ResultSet rs = cs.executeQuery();

			if (rs.next()) {
				// final int completed =
				// final int in_progress = rs.getInt("in progress");
				// final int avg_minutes = rs.getInt("avg minutes");
				// final int avg_turns = rs.getInt("avg turns");
				// final int turn_length = rs.getInt("turn length");
				// final int player_renown_battle = rs.getInt("player renown/battle");
				// final int player_renown_hour = rs.getInt("player renown/hour");
				// final int aborts = rs.getInt("aborts");
				// final int surrenders = rs.getInt("surrenders");
				// final int divergence = rs.getInt("divergence");

				final ObjectNode on = new ObjectMapper().createObjectNode();
				final int numCol = rs.getMetaData().getColumnCount();
				for (int i = 1; i <= numCol; ++i) {
					final String colName = rs.getMetaData().getColumnLabel(i);
					final Object colValue = rs.getObject(i);
					on.putPOJO(colName, colValue);
				}

				// final String json = jn.toString();
				return Response.ok(on).build();

			}

		} catch (SQLException exp) {
			exp.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		return Response.serverError().build();
	}

	@Path("/peek_q/{sessionKey}/{adminKey}/{q}")
	@GET
	public Response peek_q(@PathParam("sessionKey") String sessionKey, @PathParam("adminKey") String adminKey, @PathParam("q") String q,
			@Context HttpServletRequest request) throws IOException {

		checkCredentials(sessionKey, adminKey, request);

		Channel channel = WebConfig.instance.rabbit.createChannel("admin");
		final com.rabbitmq.client.AMQP.Queue.DeclareOk ok = channel.queueDeclarePassive(q);
		List<Object> msgs = new ArrayList<Object>();
		if (ok.getQueue() != null) {
			msgs = WebConfig.instance.msg.getAllMessages(q, msgs, "peek_q", 1000);
		}

		channel.close();

		String json = JSON.toString(msgs);

		return Response.ok(json).build();
	}
}
