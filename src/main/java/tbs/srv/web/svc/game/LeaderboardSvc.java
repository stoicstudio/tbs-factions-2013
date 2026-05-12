package tbs.srv.web.svc.game;

import java.util.ArrayList;
import java.util.List;
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

import tbs.srv.data.LeaderboardData;
import tbs.srv.data.LeaderboardType;
import tbs.srv.data.LeaderboardsData;
import tbs.srv.db.models.SessionData;
import tbs.srv.util.GameConfig;
import tbs.srv.util.Tourney;
import tbs.srv.web.WebConfig;

@Path("/leaderboards")
@Produces(MediaType.APPLICATION_JSON)
public class LeaderboardSvc {

	public static final Logger logger = Logger.getLogger(LeaderboardSvc.class.getSimpleName());

	@SuppressWarnings("unchecked")
	@Path("/{sessionKey}")
	@POST
	public Response post(String vars, @PathParam("sessionKey") String sessionKey) {

		final SessionData session = WebConfig.instance.getSession(sessionKey);

		Map<String, Object> body = null;
		int tourney_id = 0;
		Object[] board_ids = null;

		try {
			body = (Map<String, Object>) JSON.parse(vars);
			tourney_id = ((Number) body.get("tourney_id")).intValue();
			board_ids = (Object[]) body.get("board_ids");
		} catch (Exception exp) {
			return Response.status(Status.BAD_REQUEST).entity("invalid body").build();
		}

		final LeaderboardsData boards = getLeaderboards(session.account_id, tourney_id, board_ids);

		final String str = JSON.toString(boards);
		return Response.ok(str).build();
	}

	private LeaderboardsData getLeaderboards(final long userid, final int tourney_id, final Object[] ids) {
		LeaderboardsData lsd = null;

		String tourney_name = null;
		if (tourney_id > 0) {
			final Tourney t = Tourney.get(tourney_id);
			if (t != null) {
				tourney_name = t.def.name;
			}
		}

		final List<LeaderboardData> boards = new ArrayList<LeaderboardData>();

		for (int i = 0; i < ids.length; ++i) {
			final String id = (String) ids[i];
			final LeaderboardType leaderboard_type = LeaderboardType.valueOf(id);
			final LeaderboardData board = LeaderboardData.getLeaderboard(leaderboard_type, userid, tourney_id, tourney_name);
			boards.add(board);
		}

		lsd = new LeaderboardsData();
		lsd.max_entries = GameConfig.instance.LEADERBOARD_MAX_ENTRIES;
		lsd.boards = boards.toArray();

		return lsd;
	}

}