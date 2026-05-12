package tbs.srv.battle.data.client
{
	import engine.battle.ability.model.IBattleAbility;
	import engine.battle.board.model.IBattleEntity;
	import engine.core.logging.ILogger;
	import engine.tile.Tile;
	import engine.tile.TileLocationVars;
	import engine.tile.def.TileLocation;

	import flash.geom.Point;

	public class BattleActionData extends BaseBattleTurnData
	{
		public var level : int;
		public var action : String;
		public var tiles : Vector.<TileLocation> = new Vector.<TileLocation>;
		public var target_ids : Vector.<String> = new Vector.<String>;
		public var executed_id : int;
		public var terminator : Boolean;

		public function BattleActionData()
		{

		}

		override public function toString() : String
		{
			return super.toString() + ", [level=" + level + ", action=" + action + ", id=" + executed_id + ", target_ids=" + target_ids + ", tiles=" + tiles + "]";
		}

		public function setupBattleActionData(user_id : int, turn : int, battle_id : String, ability : IBattleAbility, ordinal : int, terminator : Boolean) : void
		{
			setupBattleTurnData(user_id, battle_id, turn, ability.caster.id, ordinal);

			action = ability.def.id;
			level = ability.def.level;
			entity = ability.caster.id;
			executed_id = ability.executedId;
			this.terminator = terminator;

			for each (var tg : IBattleEntity in ability.targetSet.targets)
			{
				target_ids.push(tg.id);
			}

			for each (var tileTarget : Tile in ability.targetSet.tiles)
			{
				var point : Point = new Point(tileTarget.x, tileTarget.y);
				tiles.push(tileTarget.location); //PointVars.save(point));
			}
		}

		override public function parseJson(json : Object, logger : ILogger) : void
		{
			super.parseJson(json, logger);
			for each (var tlv : Object in json.tiles)
			{
				tiles.push(TileLocationVars.parse(tlv, logger));
			}

			for each (var tv : Object in json.target_ids)
			{
				target_ids.push(tv as String);
			}

			action = json.action;
			level = json.level;
			ordinal = json.ordinal;
			terminator = json.terminator;
		}
	}
}
