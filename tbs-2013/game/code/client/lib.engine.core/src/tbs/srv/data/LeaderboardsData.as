package tbs.srv.data
{
	import engine.core.logging.ILogger;

	public class LeaderboardsData
	{
		private var boards : Vector.<LeaderboardData> = new Vector.<LeaderboardData>;

		public var max_entries : int;

		public function LeaderboardsData()
		{
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			max_entries = json.max_entries;
			for each (var boardo : Object in json.boards)
			{
				var board : LeaderboardData = new LeaderboardData;
				board.parseJson(boardo, logger);
				boards.push(board);
			}
		}

		public function replaceBoard(rhs : LeaderboardData) : void
		{
			for (var i : int = 0; i < boards.length; ++i)
			{
				const old : LeaderboardData = boards[i];
				if (old.leaderboard_type == rhs.leaderboard_type && old.tourney_id == rhs.tourney_id)
				{
					boards[i] = rhs;
					return;
				}
			}

			boards.push(rhs);
		}

		public function get allBoards() : Vector.<LeaderboardData>
		{
			return boards;
		}

		public function getBoardsForRankingGroup(ranking_group : int, result : Vector.<LeaderboardData>) : Vector.<LeaderboardData>
		{
			if (result == null)
			{
				result = new Vector.<LeaderboardData>;
			}

			for (var i : int = 0; i < boards.length; ++i)
			{
				const old : LeaderboardData = boards[i];
				if (old.tourney_id == ranking_group)
				{
					result.push(old);
				}
			}

			return result;
		}

		public function findBoard(ranking_group : int, leaderboard_type : String) : LeaderboardData
		{
			for (var i : int = 0; i < boards.length; ++i)
			{
				const old : LeaderboardData = boards[i];
				if (old.leaderboard_type == leaderboard_type && old.tourney_id == ranking_group)
				{
					return old;
				}
			}

			return null;
		}
	}
}
