package engine.battle.entity.model
{
	import engine.battle.board.model.BattleBoard;
	import engine.battle.sim.IBattleParty;
	import engine.core.logging.ILogger;
	import engine.entity.def.IEntityDef;
	import engine.sound.ISoundDriver;

	public class BattleEntityFactory
	{
		public function BattleEntityFactory()
		{
		}

		public static function create(board : BattleBoard, id : String, def : IEntityDef, party : IBattleParty, soundDriver : ISoundDriver, logger : ILogger) : BattleEntity
		{
			if (!def || !board)
			{
				throw new ArgumentError("BattleEntityFactory null def or board: def=" + def + ", board=" + board + " for id=" + id);
			}

			return new BattleEntity(def, id, board, soundDriver, logger);
		}
	}
}
