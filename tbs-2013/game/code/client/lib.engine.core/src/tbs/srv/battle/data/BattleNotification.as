package tbs.srv.battle.data
{
	import engine.core.logging.ILogger;
	import engine.session.Chat;
	import engine.session.ChatMsg;

	import flash.utils.Dictionary;

	public class BattleNotification
	{
		public var start : Boolean;
		public var victor : String;
		public var teamMembers : Dictionary = new Dictionary;
		public var numTeams : int;

		public function BattleNotification()
		{
		}

		public function parseJson(json : Object, logger : ILogger) : void
		{
			start = json.start;
			victor = json.victor;

			var index : int = 0;
			for each (var team : String in json.teams)
			{
				const members : Vector.<String> = new Vector.<String>;
				teamMembers[team] = members;

				for each (var tms : String in json.members[index])
				{
					members.push(tms);
				}
				++numTeams;
			}
		}

		public function generateChatMsg() : ChatMsg
		{
			const cm : ChatMsg = new ChatMsg;

			cm.room = Chat.GLOBAL_ROOM;
			cm.user = 0;
			cm.username = "BATTLE";

			if (start)
			{
				cm.msg = generateStartString();
			}

			else if (victor)
			{
				cm.msg = generateVictoryString();
			}

			return cm;
		}

		private function generateStartString() : String
		{
			var r : String = "Starting ";
			var index : int = 0;
			for (var team : String in teamMembers)
			{
//				const team : String = teamo as String;

				var ts : String = generateTeamString(team);

				if (index > 0)
				{
					r += " vs. " + ts;
				}
				else
				{
					r += ts;
				}

				++index;
			}

			r += ".";

			return r;
		}

		private function generateVictoryString() : String
		{
			var r : String = "";
			const vs : String = generateTeamString(victor);

			r += vs + " defeated ";

			var index : int = 0;
			for (var team : String in teamMembers)
			{
				if (team == victor)
				{
					continue;
				}

				var ts : String = generateTeamString(team);

				if (index > 0)
				{
					r += " and " + ts;
				}
				else
				{
					r += ts;
				}

				++index;
			}

			r += ".";

			return r;
		}

		private function generateTeamString(team : String) : String
		{
			var r : String = "";
			const tms : Vector.<String> = teamMembers[team];
			if (!tms)
			{
				return "ERROR";
			}

			for (var i : int = 0; i < tms.length; ++i)
			{
				var tm : String = tms[i];

				if (i == 0)
				{
					r += tm;
				}
				else if (i == (tms.length - 1))
				{
					r += ", and " + tm;
				}
				else
				{
					r += ", " + tm;
				}
			}

			return r;
		}
	}
}
