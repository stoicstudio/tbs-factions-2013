package engine.battle.ability.model
{
	import engine.battle.ability.def.BattleAbilityTargetRule;
	import engine.battle.board.model.IBattleEntity;
	import engine.tile.Tile;

	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class BattleTargetSet extends EventDispatcher
	{
		public var ability : BattleAbility;
		public var targets : Vector.<IBattleEntity> = new Vector.<IBattleEntity>;
		public var tiles : Vector.<Tile> = new Vector.<Tile>;

		public function BattleTargetSet(ability : BattleAbility)
		{
			this.ability = ability;
		}

		public function get baseTarget() : IBattleEntity
		{
			return targets.length > 0 ? targets[0] : null;
		}

		public function get baseTile() : Tile
		{
			return tiles.length > 0 ? tiles[0] : null;
		}

		public function get debugIds() : String
		{
			var str : String = "";
			for each (var target : IBattleEntity in targets)
			{
				if (str.length > 0)
				{
					str += ", ";
				}
				str += target.id;
			}

			return "{" + str + "}"
		}

		public function setTarget(value : IBattleEntity) : void
		{
			if (ability.executed)
			{
				throw new IllegalOperationError("fail exe");
			}

			if (targets.length > 0)
			{
				targets.splice(0, targets.length);
			}

			if (value)
			{
				targets.push(value);
			}

			eventNotify();
		}

		public function setTile(value : Tile) : void
		{
			if (ability.executed)
			{
				throw new IllegalOperationError("fail exe");
			}

			if (tiles.length > 0)
			{
				tiles.splice(0, tiles.length);
			}

			if (value)
			{
				tiles.push(value);
			}

			eventNotify();
		}

		private var _supressEvents : Boolean;
		private var supressedEvents : Boolean;

		private function eventNotify() : void
		{
			if (!_supressEvents)
			{
				dispatchEvent(new Event(Event.CHANGE));
			}
			else
			{
				supressedEvents = true;
			}
		}

		public function toggleTarget(value : IBattleEntity) : void
		{
			if (hasTarget(value))
			{
				removeTarget(value);
			}
			else if (ability.def.targetCount == targets.length)
			{
				removeTarget(targets[0]);
				addTarget(value);
			}
			else
			{
				addTarget(value);
			}
		}

		public function addTarget(value : IBattleEntity) : void
		{
			if (ability.executed)
			{
				throw new IllegalOperationError("fail exe");
			}

			if (targets.length > 0)
			{
				if (ability.def.targetRule == BattleAbilityTargetRule.TILE_EMPTY || ability.def.targetRule == BattleAbilityTargetRule.TILE_ANY)
				{
					throw new IllegalOperationError("tile rule can't have multiple targets");
				}
			}

			if (hasTarget(value))
			{
				throw new IllegalOperationError("target already in list");
			}

			if (targets.length >= ability.def.targetCount)
			{
				throw new IllegalOperationError("too many targets");
			}

			targets.push(value);
			eventNotify();
		}

		public function addTile(value : Tile) : void
		{
			if (ability.executed)
			{
				throw new IllegalOperationError("fail exe");
			}

			if (tiles.length > 0)
			{
				if (ability.def.targetRule != BattleAbilityTargetRule.TILE_EMPTY && ability.def.targetRule != BattleAbilityTargetRule.TILE_ANY)
				{
					throw new IllegalOperationError("only tile rule can have multiple tiles");
				}
			}

			if (hasTile(value))
			{
				throw new IllegalOperationError("tile already in list");
			}

			if (tiles.length >= ability.def.targetCount)
			{
				throw new IllegalOperationError("too many tiles");
			}

			tiles.push(value);
			eventNotify();

		}

		public function removeTarget(value : IBattleEntity) : void
		{
			if (ability.executed)
			{
				throw new IllegalOperationError("fail exe");
			}

			var index : int = targets.indexOf(value);
			if (index < 0)
			{
				throw new IllegalOperationError("targets not in list");
			}

			targets.splice(index, 1);
			eventNotify();

		}

		public function removeTile(value : Tile) : void
		{
			if (ability.executed)
			{
				throw new IllegalOperationError("fail exe");
			}

			var index : int = tiles.indexOf(value);
			if (index < 0)
			{
				throw new IllegalOperationError("tile not in list");
			}

			tiles.splice(index, 1);
			eventNotify();
		}

		public function hasTarget(value : IBattleEntity) : Boolean
		{
			var index : int = targets.indexOf(value);
			return index >= 0;
		}

		public function hasTile(value : Tile) : Boolean
		{
			var index : int = tiles.indexOf(value);
			return index >= 0;
		}

		public function get supressEvents() : Boolean
		{
			return _supressEvents;
		}

		public function set supressEvents(value : Boolean) : void
		{
			if (_supressEvents == value)
			{
				return;
			}

			_supressEvents = value;

			if (!_supressEvents)
			{
				if (supressedEvents)
				{
					supressedEvents = false;
					eventNotify();
				}
			}
		}

	}
}
