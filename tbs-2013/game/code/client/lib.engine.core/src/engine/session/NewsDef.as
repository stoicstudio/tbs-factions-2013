package engine.session
{

	public class NewsDef
	{
		public var entries : Vector.<NewsEntryDef> = new Vector.<NewsEntryDef>;

		public function NewsDef()
		{
		}

		public function findFirstIndexAfterDate(date : Date) : int
		{
			if (date == null)
			{
				return -1;
			}
			for (var i : int = 0; i < entries.length; ++i)
			{
				var e : NewsEntryDef = entries[i];
				if (e.date.time > date.time)
				{
					return i;
				}
			}

			return -1;
		}

		public function getLastDate() : Date
		{
			return entries.length > 0 ? entries[entries.length - 1].date : null;
		}

		public function sortEntries() : void
		{
			entries = entries.sort(function(a : NewsEntryDef, b : NewsEntryDef) : Number
			{
				return a.date.time - b.date.time;
			});
		}
	}
}
