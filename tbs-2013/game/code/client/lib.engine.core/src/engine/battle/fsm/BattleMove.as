package engine.battle.fsm
{
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	
	import engine.battle.ability.def.BattleAbilityDef;
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.board.model.IBattleMove;
	import engine.battle.sim.TileDiamond;
	import engine.battle.sim.TileRectHugger;
	import engine.core.logging.ILogger;
	import engine.path.IPath;
	import engine.path.IPathGraphLink;
	import engine.path.IPathGraphNode;
	import engine.path.Path;
	import engine.path.PathEvent;
	import engine.path.PathFloodSolver;
	import engine.path.PathFloodSolverNode;
	import engine.path.PathStatus;
	import engine.stat.def.StatType;
	import engine.stat.model.StatEvent;
	import engine.tile.Tile;
	import engine.tile.def.TileLocation;
	import engine.tile.def.TileRect;
	import engine.tile.def.TileRectRange;

	public class BattleMove extends EventDispatcher implements IBattleMove
	{
		private var _entity : IBattleEntity;
		public var wayPointTile : Tile;
		public var wayPointSteps : int = 1;

		protected var steps : Vector.<Tile> = new Vector.<Tile>;
		private var _path : IPath;
		public var flood : PathFloodSolver;
		private var _executed : Boolean;
		private var _executing : Boolean;
		private var _committed : Boolean;
		private var _interrupted : Boolean;
		private var _forcedMove : Boolean = false;
		private var _reactToEntityIntersect : Boolean = false;

		private var _maxStars : int = 1000;
		private var _searchBonus : int = 0;

		public function BattleMove(entity : IBattleEntity, maxStars : int = 1000, searchBonus : int = 0)
		{
			if (!entity)
			{
				throw new ArgumentError("BattleMove null entity");
			}

			this._entity = entity;
			steps.push(entity.tile);

			_maxStars = maxStars;
			_searchBonus = searchBonus;
			updateFloods();
		}

		public function listenForWillpower() : void
		{
			if (entity)
			{
				entity.stats.getStat(StatType.WILLPOWER).addEventListener(StatEvent.CHANGE, entityWillpowerHandler);
			}
		}

		public function unlistenForWillpower() : void
		{
			if (entity)
			{
				entity.stats.getStat(StatType.WILLPOWER).removeEventListener(StatEvent.CHANGE, entityWillpowerHandler);
			}
		}

		public function cleanup() : void
		{
			unlistenForWillpower();
			_entity = null;
			steps = null;
			flood = null;
			_path = null;
		}

		private function entityWillpowerHandler(event : StatEvent) : void
		{

		}

		override public function toString() : String
		{
			return "[" + entity.id + " " + first + " -> " + last + "]";
		}

		public function copy(rhs : BattleMove) : void
		{
			if (committed)
			{
				throw new IllegalOperationError("BattleMove.copy already committed " + this);
			}

			if (rhs.entity != this.entity)
			{
				throw new ArgumentError("BattleMove.copy incompatible entities");
			}

			if (rhs.first != entity.tile)
			{
				throw new IllegalOperationError("BattleMove.copy " + this + " bad tiles " + steps + " should start with " + entity.tile);
			}

			steps = rhs.steps.concat();
			_executed = false;
			_executing = false;
			_committed = false;
		}

		public function equals(rhs : BattleMove) : Boolean
		{
			if (steps.length == rhs.steps.length)
			{
				for (var i : int = 0; i < steps.length; ++i)
				{
					if (!steps[i].equals(rhs.steps[i]))
					{
						return false;
					}
				}

				return true;
			}

			return false;
		}

		public function get forcedMove() : Boolean
		{
			return _forcedMove;
		}

		public function set forcedMove(val : Boolean) : void
		{
			_forcedMove = val;
		}

		public function get reactToEntityIntersect() : Boolean
		{
			return _reactToEntityIntersect;
		}

		public function set reactToEntityIntersect(val : Boolean) : void
		{
			_reactToEntityIntersect = val;
		}

		public function get numSteps() : int
		{
			return steps.length;
		}

		public function getStep(index : int) : Tile
		{
			return steps[index];
		}

		public function addStep(tile : Tile) : void
		{
			steps.push(tile);
		}

		public function get first() : Tile
		{
			return steps[0];
		}

		public function get last() : Tile
		{
			return steps[steps.length - 1];
		}

		public function getStepIndex(tile : Tile) : int
		{
			return steps.indexOf(tile);
		}

		public function hasStep(tile : Tile) : Boolean
		{
			return steps.indexOf(tile) >= 0;
		}

		public function get executed() : Boolean
		{
			return _executed;
		}

		public function setExecuted() : void
		{
			if (!_committed)
			{
				setCommitted("BattleMove.setExecuted");
			}

			if (_executed)
			{
				throw new IllegalOperationError("already executed");
			}

			_executing = false;
			_executed = true;

			entity.logger.info("BattleMove EXECUTED " + this);

			dispatchEvent(new BattleMoveEvent(BattleMoveEvent.EXECUTED));
		}

		public function get committed() : Boolean
		{
			return _committed;
		}

		public function setCommitted(reason : String) : void
		{
			if (_committed)
			{
				throw new IllegalOperationError("already committed");
			}

			if (first != entity.tile)
			{
				throw new IllegalOperationError("Attempt to teleport " + entity + " to " + first);
			}

			entity.logger.debug("BattleMove.setCommitted " + this + " reason=" + reason);

			_committed = true;
			dispatchEvent(new BattleMoveEvent(BattleMoveEvent.COMMITTED));
		}

		////////////////////////////////////////////////////

		public function get path() : IPath
		{
			return _path;
		}

		private function setPath(value : IPath) : void
		{
			if (committed)
			{
				throw new IllegalOperationError("BattleMove.setPath already committed " + this);
			}

			if (_path == value)
			{
				return;
			}

			if (_path)
			{
				_path.dispatcher.removeEventListener(PathEvent.EVENT_PATH_STATUS_CHANGED, pathStatusChangedHandler);
				_path.status = PathStatus.TERMINATE;
				_path = null;
			}

			_path = value;

			if (_path)
			{
				_path.dispatcher.addEventListener(PathEvent.EVENT_PATH_STATUS_CHANGED, pathStatusChangedHandler);
			}

		}

		public function reset(loc : Tile) : void
		{
			if (!loc)
			{
				throw new ArgumentError("uuuuuuhhhh");
			}

			//			_executed = false;
			//			complete = false;
			setPath(null);

			if (loc != entity.tile)
			{
				throw new IllegalOperationError("BattleMove.reset " + this + " invalid tile " + loc);
			}

			if (committed)
			{
				throw new IllegalOperationError("BattleMove.reset already committed " + this);
			}

			steps.splice(0, steps.length, loc);

			setWayPoint(loc);
//			wayPointTile = loc;
//			wayPointSteps = 1;

			updateFloods();

			handlePlanChanged(false);
		}

		public function setWayPoint(tile : Tile) : void
		{
			if (tile && tile != last)
			{
				throw new IllegalOperationError("bad waypoint");
			}

			if (committed)
			{
				throw new IllegalOperationError("BattleMove.setWayPoint Attempt to modify committed move " + this);
			}

			wayPointSteps = numSteps;
			wayPointTile = tile;

			updateFloods();

			dispatchEvent(new BattleMoveEvent(BattleMoveEvent.WAYPOINT));
		}

		public function trimStepsToWaypoint() : void
		{
			if (wayPointSteps < steps.length)
			{
				steps.splice(wayPointSteps, steps.length);
				handlePlanChanged(true);
			}
		}

		public function trimStepsTo(index : int) : void
		{
			if (index < (steps.length - 1))
			{
				steps.splice(index + 1, steps.length - index - 1);
			}
			handlePlanChanged(true);
		}

		public function trimStepsInLoop(loc : Tile) : Boolean
		{
			var index : int = steps.indexOf(loc);
			if (index >= 0)
			{
				if (index < (steps.length - 1))
				{
					steps.splice(index + 1, steps.length - index);
				}

				handlePlanChanged(true);
				return true;
			}

			return false;
		}

		public function pathToDiamond(target : TileRect, minDist : int, maxDist : int, allowTrim : Boolean, maxSteps : int) : Boolean
		{
			if (maxDist < 0)
			{			
				throw new ArgumentError("No need to path when maxDist < 0");
				// hmm
			}
			
			var toward : TileRect = new TileRect(last.location, entity.width, entity.length);
			var trh : TileDiamond = new TileDiamond(target, minDist, maxDist, toward, maxSteps);

			// first just check if we are already there, yo
			if (trh.hugs.indexOf(last.location) >= 0)
			{
				return true;
			}

			for each (var tl : TileLocation in trh.hugs)
			{
				// no need to check for occlusions, the flood fill has already taken care of that
				var tile : Tile = entity.board.tiles.getTile(tl.x, tl.y);
				var node : PathFloodSolverNode = flood.resultSet[tile];
				if (node)
				{
					process(tile, allowTrim);

					if (numSteps > (maxSteps + 1))
					{
						// too far away
						trimStepsTo(maxSteps);
					}

					return true;
				}
			}

			// maybe we couldn't get there from our last step, but try from the original location
			if (numSteps > 1)
			{
				// erase the path
				reset(steps[0]);

				// now try to path TO the entity one more time
				// this will not recurse again because numSteps is now zero
				return pathToDiamond(target, minDist, maxDist, allowTrim, maxSteps);
			}

			return false;
		}

		public function pathToRect(target : TileRect, allowTrim : Boolean, maxSteps : int) : Boolean
		{
			var trh : TileRectHugger = new TileRectHugger(
				new TileRect(last.location, entity.width, entity.length),
				target
				);

			// first just check if we are already there, yo
			if (trh.hugs.indexOf(last.location) >= 0)
			{
				return true;
			}

			for each (var tl : TileLocation in trh.hugs)
			{
				// no need to check for occlusions, the flood fill has already taken care of that
				var tile : Tile = entity.board.tiles.getTile(tl.x, tl.y);
				var node : PathFloodSolverNode = flood.resultSet[tile];
				if (node)
				{
					process(tile, allowTrim);

					if (numSteps > (maxSteps + 1))
					{
						// too far away
						trimStepsTo(maxSteps);
					}

					return true;
				}
			}

			// maybe we couldn't get there from our last step, but try from the original location
			if (numSteps > 1)
			{
				// erase the path
				reset(steps[0]);

				// now try to path TO the entity one more time
				// this will not recurse again because numSteps is now zero
				return pathToRect(target, allowTrim, maxSteps);
			}

			return false;
		}

		public function process(loc : Tile, allowTrim : Boolean) : void
		{
			if (!loc)
			{
				throw new ArgumentError("uuuuuuhhhh");
			}

			if (committed)
			{
				throw new ArgumentError("Can't process when turn has already been commited.");
			}

			if (loc == last)
			{
				// already there
				return;
			}

			if (allowTrim)
			{
				if (trimStepsInLoop(loc))
				{
					return;
				}
			}

			var oldLength : int = steps.length;
			var dst : IPathGraphNode = entity.board.tiles.pathGraph.getNode(loc);

			// a path segment from the current last step to the destination
			var ps : IPath;

			trimStepsToWaypoint();

			ps = flood.reconstructPathTo(dst);

			if (!ps)
			{
//				if (steps.length > 1)
//				{
//					// did not generate a path, reset
//					reset(steps[0]);
//
//					updateFloods();
//					process(loc, allowTrim);
//				}
				return;
			}

			if (ps.status == PathStatus.COMPLETE)
			{
				for (var i : int = 0; i < ps.links.length; ++i)
				{
					var link : IPathGraphLink = ps.links[i];
					steps.push(link.dst.key);
				}
			}

			if (oldLength > 1)
			{
				var e : IBattleEntity = entity;
				var availWillPower : int = Math.min(e.stats.getStat(StatType.EXERTION).value, e.stats.getStat(StatType.WILLPOWER).value);
				var rangeStarred : int = e.stats.getStat(StatType.MOVEMENT).value + availWillPower;

				// tried to keep going too far, just recalculate
				if (steps.length > (rangeStarred + 1))
				{
					reset(steps[0]);
					updateFloods();
					process(loc, allowTrim);
					return;
				}
			}

			if (allowTrim)
			{
				trimLoops();
			}

			handlePlanChanged(true);

		}

		private function trimLoops() : void
		{
			// remove any loops we might find
			for (var i : int = 0; i < steps.length - 1; ++i)
			{
				var step : Tile = steps[i];

				var loopIndex : int = steps.indexOf(step, i + 1);
				if (loopIndex > i)
				{
					// remove the loop from (i, loopIndex]				
					steps.splice(i + 1, loopIndex - i);
				}
			}
		}

		protected function pathStatusChangedHandler(event : PathEvent) : void
		{
			if (event.path != path)
			{
				throw new IllegalOperationError("balls");
			}

			if (path.status == PathStatus.WAITING || path.status == PathStatus.WORKING)
			{
				// keep waiting for it to calculate
				return;
			}

			if (path.status == PathStatus.COMPLETE)
			{
				for (var i : int = 0; i < path.links.length; ++i)
				{
					var link : IPathGraphLink = path.links[i];
					steps.push(link.dst.key);
				}
			}

			setPath(null);

			handlePlanChanged(true);
		}

		private static function heuristicFloodDistance(src : Tile, dst : Tile) : Number
		{
			var dx : int = Math.abs(src.x - dst.x);
			var dy : int = Math.abs(src.y - dst.y);

			// horizontal is considered farther, which causes paths to want to traverse horizontal faster
			return dx * 100 + dy;
		}

		public function getFlood(tile : Tile, costLimit : int, stepsBlock : Boolean) : PathFloodSolver
		{
			if (tile)
			{
				var pgn : IPathGraphNode = entity.board.tiles.pathGraph.getNode(tile);
				var nbc : NodeBlockedChecker = new NodeBlockedChecker(this);
				nbc.stepsBlock = stepsBlock;
				var pfs : PathFloodSolver = new PathFloodSolver(pgn, heuristicFloodDistance, nbc.nodeBlockedFunc, costLimit);
				return pfs;
			}
			return null;
		}

		private function handlePlanChanged(dispatch : Boolean) : void
		{
			var e : IBattleEntity = entity;
			if (e)
			{
				updateFloods();
			}
			else
			{
				flood = null;
			}

			if (steps.length > 1)
			{
				var src : IPathGraphNode = entity.board.tiles.pathGraph.getNode(first);
				var dst : IPathGraphNode = entity.board.tiles.pathGraph.getNode(last);
				var p : Path = new Path(src, dst);

				var prev : IPathGraphNode = src;

				for (var i : int = 1; i < steps.length; ++i)
				{
					var t : Tile = steps[i];
					var n : IPathGraphNode = entity.board.tiles.pathGraph.getNode(t);
					var link : IPathGraphLink = prev.getLink(n);
					p.links.push(link);
					prev = n;
				}

				p.status = PathStatus.COMPLETE;
				setPath(p);
			}
			else
			{
				setPath(null);
			}

			dispatchEvent(new BattleMoveEvent(BattleMoveEvent.MOVE_CHANGED));
		}

		public function updateFloods() : void
		{
			var e : IBattleEntity = entity;
			if (!e)
			{
				return;
			}

			var remain : int = e.stats.getValue(StatType.MOVEMENT) - wayPointSteps + 1;

			var availWillpower : int = Math.min(e.stats.getValue(StatType.EXERTION), e.stats.getValue(StatType.WILLPOWER));
			var remainStarred : int = remain + Math.max(0, Math.min(_maxStars, availWillpower));

			remainStarred += _searchBonus;

			var center : Tile = wayPointTile;

			if (!center)
			{
				center = first;
			}

			if (flood)
			{
				if (flood.src.key == center)
				{
					if (flood.costLimit == remainStarred)
					{
						// already have this flood, don't regenerate it
						return;
					}
				}
			}

			flood = getFlood(center, remainStarred, true);
			flood.update(-1, null);

			dispatchEvent(new BattleMoveEvent(BattleMoveEvent.FLOOD_CHANGED));
		}

		public function isInRange(tile : Tile) : Boolean
		{
			if (flood)
			{
				return flood.inResultSet(tile);
			}

			return false;
		}

		public function get executing() : Boolean
		{
			return _executing;
		}

		public function setExecuting() : void
		{
			_executing = true;
			dispatchEvent(new BattleMoveEvent(BattleMoveEvent.EXECUTING));

		}

		public function get interrupted() : Boolean
		{
			return _interrupted;
		}

		public function setInterrupted() : void
		{
			_interrupted = true;
			dispatchEvent(new BattleMoveEvent(BattleMoveEvent.INTERRUPTED));
		}

		public function handleIntersectEntity() : void
		{
			dispatchEvent(new BattleMoveEvent(BattleMoveEvent.INTERSECT_ENTITY));
		}

		public function get entity() : IBattleEntity
		{
			return _entity;
		}

		public static function computeMoveToRange(abl : BattleAbilityDef, caster : IBattleEntity, target : IBattleEntity, logger : ILogger, maxStars : int, gtg : Array) : BattleMove
		{
			var range : int = TileRectRange.computeRange(target.rect, caster.rect);

			var move : BattleMove = new BattleMove(caster, maxStars);
			
			var mv : int = caster.stats.getValue(StatType.MOVEMENT);

			gtg[0] = true;

			if (abl.rangeMax < 0)
			{
				logger.info("Infinite-range no move");
				return move;
			}
			
			if (abl.rangeMax > 0 && range > abl.rangeMax)
			{
				logger.debug("Op_MoveToRange execute too far");
				// too far
				if (move.pathToDiamond(target.rect, abl.rangeMin, abl.rangeMax, true, mv + maxStars))
				{
					return move;
				}
			}
			else if (abl.rangeMin > 0 && range < abl.rangeMin)
			{
				logger.debug("Op_MoveToRange execute too close");
				// too close
				if (move.pathToDiamond(target.rect, abl.rangeMin, abl.rangeMax, true, mv + maxStars))
				{
					return move;
				}
			}
			else
			{
				logger.debug("Op_MoveToRange execute range perfect " + range);
				return null;
			}

			logger.debug("Op_MoveToRange execute just get close");

			// just get as close as possible without exertion

			gtg[0] = false;

			var tr : TileRect = target.rect;
			if (move.pathToDiamond(tr, abl.rangeMin, abl.rangeMax, true, mv + maxStars))
			{

			}

			move = new BattleMove(caster, 0, 20);

			if (move.pathToRect(target.rect, true, mv))
			{
				logger.debug("Op_MoveToRange too far moving in to as close as possible " + target);
				return move;
			}

			return null;
		}
	}
}

import engine.battle.board.model.IBattleEntity;
import engine.battle.fsm.BattleMove;
import engine.path.IPathGraphNode;
import engine.tile.Tile;
import engine.tile.Tiles;

class NodeBlockedChecker
{
	public var stepsBlock : Boolean;

	public var move : BattleMove;

	public function NodeBlockedChecker(move : BattleMove)
	{
		this.move = move;
	}

	public function nodeBlockedFunc(node : IPathGraphNode) : Boolean
	{
		var tile : Tile = node.key as Tile;
		var tiles : Tiles = move.entity.board.tiles;
		var entity : IBattleEntity = move.entity as IBattleEntity;

		if (tiles.isTileBlockedForEntity(entity, tile))
		{
			return true;
		}

		if (stepsBlock)
		{
			for (var i : int = 0; i < move.numSteps; ++i)
			{
				if (tile == move.getStep(i))
				{
					return true;
				}
			}

		}

		return false;
	}

}
