package engine.battle.board.def
{
	import engine.battle.ability.effect.model.BattleFacing;
	import engine.tile.def.TileLocationArea;

	public class BattleDeploymentArea
	{
		public var id : String;
		public var facing : BattleFacing = BattleFacing.SW;
		public var area : TileLocationArea = new TileLocationArea;

		public function BattleDeploymentArea()
		{
		}

	}
}
