package engine.tile
{
	import engine.battle.ability.def.IBattleAbilityDef;
	import engine.battle.ability.effect.model.Effect;
	import engine.path.IPath;
	import engine.path.IPathGraph;
	import engine.path.IPathGraphNode;
	import engine.tile.def.TileDef;
	import engine.tile.def.TileLocation;
	import engine.tile.def.TileLocationArea;
	import engine.tile.def.TileRect;

	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	public class Tiles extends EventDispatcher
	{
		public var tiles : Vector.<Tile> = new Vector.<Tile>();
		public var tilesByLocation : Dictionary = new Dictionary;
		public var pathGraph : IPathGraph;
		private var entityPositions : Dictionary = new Dictionary;

		public function Tiles(walkableTiles : TileLocationArea, unwalkableTiles : TileLocationArea)
		{

			var t : Tile;
			var rt : TileLocation;
			for each (rt in walkableTiles.locations)
			{
				if (getTileByLocation(rt))
				{
					throw new ArgumentError("Already exists: " + rt);
				}
				t = createTile(rt.x, rt.y, true);
				tilesByLocation[rt] = t;
				tiles.push(t);
			}

			for each (rt in unwalkableTiles.locations)
			{
				if (getTileByLocation(rt))
				{
					throw new ArgumentError("Already exists: " + rt);
				}
				t = createTile(rt.x, rt.y, false);
				tilesByLocation[rt] = t;
				tiles.push(t);
			}

			pathGraph = createPathGraph();
		}

		protected function createTile(x : int, y : int, walkable : Boolean) : Tile
		{
			return new Tile(new TileDef(x, y, walkable), this);
		}

		protected function createPathGraph() : IPathGraph
		{
			return null;
		}

		public function addTrigger(rect : TileRect, callback : Function, playerControlled : Boolean, params : Object, effect : Effect) : TileTrigger
		{
			// do nothing right now, let subclasses do all the work
			return null;
		}

		public function addAbilityBasedTrigger(rect : TileRect, battleAbility : IBattleAbilityDef, pulsesEveryTurn : Boolean) : TileTrigger
		{
			// do nothing right now, let subclasses do all the work
			return null;
		}

		public function removeTrigger(trigger : TileTrigger) : void
		{
			// do nothing right now, let subclasses do all the work
		}

		private function updateEntityTiles(entity : ITileResident, r : Rectangle, resident : Boolean) : void
		{
			// unblock
			for (var w : int = 0; w < r.width; ++w)
			{
				for (var h : int = 0; h < r.height; ++h)
				{
					var tile : Tile = getTile(r.x + w, r.y + h);
					if (tile)
					{
						if (!resident)
						{
							tile.removeResident(entity);
						}
						else
						{
							tile.addResident(entity);
						}
					}
				}
			}
		}

		final protected function blockTilesForEntity(entity : ITileResident) : void
		{
			if (!entity)
			{
				return;
			}

			var old : Rectangle = entityPositions[entity];
			if (old)
			{
				updateEntityTiles(entity, old, false);
			}
			else
			{
				old = new Rectangle();
			}

			if (entity.tiles != this)
			{
				return;
			}

			old.setTo(entity.x, entity.y, entity.width, entity.length);

			// block new
			updateEntityTiles(entity, old, true);

			entityPositions[entity] = old;
		}

		public function getTileByLocation(tl : TileLocation) : Tile
		{
			return tl ? tilesByLocation[tl] : null;
		}

		public function getTile(x : int, y : int) : Tile
		{
			return getTileByLocation(TileLocation.fetch(x, y));
		}

		private var nodeBlockedCheckers : Dictionary = new Dictionary(true);

		public function getPath(entity : ITileResident, dstx : int, dsty : int) : IPath
		{
			var src : Tile = entity.tile;
			var dst : Tile = getTile(dstx, dsty);

			if (src == dst || src == null || dst == null)
			{
				return null;
			}

			var nbc : NodeBlockedChecker = getNodeBlockedChecker(entity);

			return pathGraph.getPath(src, dst, nbc.nodeBlockedFunc);
		}

		private function getNodeBlockedChecker(entity : ITileResident) : NodeBlockedChecker
		{
			var nbc : NodeBlockedChecker = nodeBlockedCheckers[entity];
			if (!nbc)
			{
				nbc = new NodeBlockedChecker(this, entity);
				nodeBlockedCheckers[entity] = nbc;
			}
			return nbc;
		}

		public function isTileBlockedForEntity(entity : ITileResident, tile : Tile) : Boolean
		{
			for (var x : int = 0; x < entity.width; ++x)
			{
				for (var y : int = 0; y < entity.length; ++y)
				{
					var rtile : Tile = getTile(tile.def.x + x, tile.def.y + y);
					if (rtile == null)
					{
						return true;
					}

					// something else is blocking us
					if (!rtile.hasResident(entity) && rtile.numResidents > 0)
					{
						return true;
					}
				}
			}
			return false;
		}

		public var flyText : String;
		public var flyTextColor : uint;
		public var flyTextTile : Tile;
		public var flyTextFontName : String;
		public var flyTextFontSize : int;

		public function emitFlyText(tile : Tile, str : String, color : uint, fontName : String, fontSize : int) : void
		{
			flyTextTile = tile;
			flyText = str;
			flyTextColor = color;
			flyTextFontName = fontName;
			flyTextFontSize = fontSize;
			dispatchEvent(new TilesEvent(TilesEvent.TILE_FLYTEXT));
		}
	}
}
import engine.tile.ITileResident;
import engine.tile.Tile;
import engine.tile.Tiles;
import engine.path.IPathGraphNode;

class NodeBlockedChecker
{
	public var entity : ITileResident;
	public var tiles : Tiles;

	public function NodeBlockedChecker(tiles : Tiles, entity : ITileResident)
	{
		this.entity = entity;
		this.tiles = tiles;
	}

	public function nodeBlockedFunc(node : IPathGraphNode) : Boolean
	{
		var tile : Tile = node.key as Tile;
		return tiles.isTileBlockedForEntity(entity, tile);
	}

}
