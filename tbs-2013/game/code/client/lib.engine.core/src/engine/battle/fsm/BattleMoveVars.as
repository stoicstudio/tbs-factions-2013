package engine.battle.fsm
{
	import engine.battle.board.model.IBattleBoard;
	import engine.battle.board.model.IBattleEntity;
	import engine.core.logging.ILogger;
	import engine.def.EngineJsonDef;
	import engine.tile.Tile;
	import engine.tile.TileLocationVars;
	import engine.tile.def.TileLocation;

	public class BattleMoveVars extends BattleMove
	{
		public static const schema : Object =
			{
				name: "BattleMoveVars",
				type: "object",
				properties:
				{
					entity: {type: "string"},
					tiles: {type: "array", items: TileLocationVars.schema},
					battleId: {type: "string", optional: true},
					turn: {type: "number", optional: true},
					user: {type: "number", optional: true},
					ordinal: {type: "number", optinal: true},
					"class": {type: "string", optional: true}
				}
			};

		public function BattleMoveVars(board : IBattleBoard, vars : Object, logger : ILogger)
		{
			EngineJsonDef.validateThrow(vars, schema, logger);

			var ent : IBattleEntity = board.getEntity(vars.entity);

			super(ent);

			steps.splice(0, steps.length);

			for each (var tilev : Object in vars.tiles)
			{
				var loc : TileLocation = TileLocationVars.parse(tilev, logger);
				var step : Tile = board.tiles.getTile(loc.x, loc.y);
				steps.push(step);
			}
		}

		public static function save(rhs : BattleMove) : Object
		{
			var r : Object = {
					entity: rhs.entity.id,
					tiles: []
				};

			var step : Tile;
			for (var i : int = 0; i < rhs.numSteps; ++i)
			{
				step = rhs.getStep(i);
				r.tiles.push(TileLocationVars.save(step.location));
			}

			return r;
		}
	}
}
