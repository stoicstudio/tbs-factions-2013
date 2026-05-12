package game.entity
{
	

	public class GameStatCosts
	{
		protected var stats : Vector.<int> = new Vector.<int>;
		protected var promotes : Vector.<int> = new Vector.<int>;
		protected var killsToPromote : Vector.<int> = new Vector.<int>;
		protected var rename : int;
		public var variation : int;
		public var roster_row_cost : int;
		public var max_num_roster_rows : int;
		public var roster_slots_per_row : int;

		public function GameStatCosts()
		{
		}

		public function getTotalCost(rank : int, delta : int) : int
		{
			if (delta < 0)
			{
				return 0;
			}

			const index : int = rank - 1;
			if (index < 0 || index >= stats.length)
			{
				throw new ArgumentError("invalid rank " + rank);
			}
			return stats[index] * delta;
		}

		public function getPromotionCost(fromRank : int) : int
		{
			const index : int = fromRank - 1;
			if (index < 0 || index >= stats.length)
			{
				throw new ArgumentError("invalid rank " + fromRank);
			}
			//setting rank from 1 based to zero based.
			return promotes[index];
		}

		public function getKillsRequiredToPromote(rank : int) : int
		{
			const index : int = rank - 1;
			if (index < 0)
			{
				throw new ArgumentError("invalid rank " + rank);
			}
			if (killsToPromote.length <= index)
			{
				return -1;
			}
			return killsToPromote[index];
		}

		public function getRenameCost() : int
		{
			return rename;
		}
		
		public function getVariationCost() : int
		{
			return variation;
		}
	}
}
