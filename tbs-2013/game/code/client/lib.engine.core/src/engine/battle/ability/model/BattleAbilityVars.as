package engine.battle.ability.model
{
	import engine.battle.ability.def.BattleAbilityDef;
	import engine.battle.board.model.IBattleBoard;
	import engine.battle.board.model.IBattleEntity;
	import engine.core.logging.ILogger;
	import engine.def.PointVars;
	import engine.tile.Tile;

	import flash.geom.Point;

	import tbs.srv.battle.data.client.BattleActionData;

	public class BattleAbilityVars
	{
		public static function parse(vars : BattleActionData, board : IBattleBoard, logger : ILogger, manager : BattleAbilityManager) : BattleAbility
		{
			var def : BattleAbilityDef = manager.factory.fetch(vars.action) as BattleAbilityDef;
			var level : int = int(vars.level);
			var ldef : BattleAbilityDef = def.getBattleAbilityDefLevel(level);
			var caster : IBattleEntity = board.getEntity(vars.entity);

			var ba : BattleAbility = new BattleAbility(caster, ldef, manager);

			for each (var tgv : Object in vars.target_ids)
			{
				var id : String = tgv as String;
				var ent : IBattleEntity = board.getEntity(id);
				if (vars.target_ids.length == 1)
				{
					ba.targetSet.setTarget(ent);
				}
				else
				{
					ba.targetSet.addTarget(ent);
				}
			}

			for each (var tileTarget : Object in vars.tiles)
			{
				var point : Point = PointVars.parse(tileTarget, logger) as Point;
				var tile : Tile = board.tiles.getTile(point.x, point.y);
				ba.targetSet.addTile(tile);
			}

			ba.internalSetexecutedId(vars.executed_id);
			return ba;
		}

		public static function save(ability : IBattleAbility) : Object
		{
			var r : Object =
				{
					action: ability.def.id,
					level: ability.def.level,
					entity: ability.caster.id,
					targetIds: [],
					tiles: [],
					executedId: ability.executedId
				};

			for each (var tg : IBattleEntity in ability.targetSet.targets)
			{
				r.targetIds.push(tg.id);
			}

			for each (var tileTarget : Tile in ability.targetSet.tiles)
			{
				var point : Point = new Point(tileTarget.x, tileTarget.y);
				r.tiles.push(PointVars.save(point));
			}

			return r;
		}
	}
}
