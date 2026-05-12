package engine.core.util
{
	import flash.geom.Rectangle;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	import engine.battle.board.model.IBattleEntity;
	import engine.tile.ITileResident;
	import engine.tile.Tile;
	import engine.tile.def.TileRect;

	public class UtilFunctions
	{
		private static function newSibling(sourceObj : Object) : *
		{
			if (sourceObj)
			{

				var objSibling : *;

				var classOfSourceObj : Class = getDefinitionByName(getQualifiedClassName(sourceObj)) as Class;
				objSibling = new classOfSourceObj();

				return objSibling;
			}
			return null;
		}

		public static function clone(source : Object) : Object
		{

			var clone : Object;
			if (source)
			{
				clone = newSibling(source);

				if (clone)
				{
					copyData(source, clone);
				}
			}

			return clone;
		}

		private static function copyData(source : Object, destination : Object) : void
		{

			//copies data from commonly named properties and getter/setter pairs
			if ((source) && (destination))
			{

				var sourceInfo : XML = describeType(source);
				var prop : XML;

				for each (prop in sourceInfo.variable)
				{

					if (destination.hasOwnProperty(prop.@name))
					{
						destination[prop.@name] = source[prop.@name];
					}

				}

				for each (prop in sourceInfo.accessor)
				{
					if (prop.@access == "readwrite")
					{
						if (destination.hasOwnProperty(prop.@name))
						{
							destination[prop.@name] = source[prop.@name];
						}

					}
				}

				for (var key : String in source)
				{
					destination[key] = source[key];
				}

			}
		}

		// taking entity width into account are any occupied tiles axial between these 2 entities
		public static function isAxialEntity2Entity(entity1 : IBattleEntity, entity2 : IBattleEntity) : Boolean
		{
			if (entity1 != null && entity2 != null)
			{
				var tileRect1 : TileRect = entity1.rect;
				var tileRect2 : TileRect = entity2.rect;

				return isAxialRect2Rect(tileRect1, tileRect2);
			}

			return false;
		}

		public static function isAxialEntity2Tile(entity : IBattleEntity, tile : Tile) : Boolean
		{
			if (entity != null && tile != null)
			{
				var tileRect1 : TileRect = entity.rect;
				var tileRect2 : TileRect = tile.rect;

				return isAxialRect2Rect(tileRect1, tileRect2);
			}

			return false;
		}

		public static function isAxialRect2Rect(tileRect1 : TileRect, tileRect2 : TileRect) : Boolean
		{
			if (tileRect1 != null && tileRect2 != null)
			{
				// ju: switching these over to rectangles.  It looks like the internal tilerect location is shared

				var rect1LeftRight : Rectangle = new Rectangle(tileRect1.loc.x, tileRect1.loc.y, tileRect1.width, tileRect1.length);
				var rect1TopBottom : Rectangle = new Rectangle(tileRect1.loc.x, tileRect1.loc.y, tileRect1.width, tileRect1.length);
				var rect2 : Rectangle = new Rectangle(tileRect2.loc.x, tileRect2.loc.y, tileRect2.width, tileRect2.length);

				// force overlaps
				rect1LeftRight.right += 1000.0;
				rect1LeftRight.left -= 1000.0;
				rect1TopBottom.top -= 1000.0;
				rect1TopBottom.bottom += 1000.0;

				return (rect2.intersects(rect1LeftRight) || rect2.intersects(rect1TopBottom));
			}
			return false;
		}

		private static function isTileAvailable(tile : Tile, ignore : IBattleEntity = null) : Boolean
		{
			if (tile != null)
			{
				for each (var a : ITileResident in tile.residents)
				{

					if (a is IBattleEntity)
					{
						if (ignore == null || ignore != a)
						{
							var battleEntity : IBattleEntity = a as IBattleEntity;
							if (battleEntity.alive == true)
							{
								return false;
							}
						}
					}

				}
				return true;
			}

			return false;
		}

		// JU_TODO: these are somewhat ability specfic in regards to entity1 or entity2 referenced.

		// returns the available tile for entity1 behind entity2 in relation to entity1. Available means empty or no alive entities on tile
		public static function getTileAvailableBehind(entity1 : IBattleEntity, entity2 : IBattleEntity) : Tile
		{
			// crude and unrolled, but works.

			var x : int = 0;
			var y : int = 0;

			var foundTile : Boolean = false;

			var tileRect1 : TileRect = entity1.rect;
			var tileRect2 : TileRect = entity2.rect;

			var rectangle1 : Rectangle = new Rectangle(tileRect1.loc.x, tileRect1.loc.y, tileRect1.width, tileRect1.length);
			var rectangle2 : Rectangle = new Rectangle(tileRect2.loc.x, tileRect2.loc.y, tileRect2.width, tileRect2.length);

			rectangle1.right += 1000.0; //se
			if (rectangle2.intersects(rectangle1) == true)
			{
				// +x
				x = rectangle2.left + entity2.width;
				y = rectangle1.top;
				foundTile = true;
			}
			else
			{
				rectangle1 = new Rectangle(tileRect1.loc.x, tileRect1.loc.y, tileRect1.width, tileRect1.length);
				rectangle1.left -= 1000.0; //nw
				if (rectangle2.intersects(rectangle1) == true)
				{
					// -x
					x = rectangle2.left - entity1.width;
					y = rectangle1.top;
					foundTile = true;
				}
				else
				{
					rectangle1 = new Rectangle(tileRect1.loc.x, tileRect1.loc.y, tileRect1.width, tileRect1.length);
					rectangle1.top -= 1000.0; //ne
					if (rectangle2.intersects(rectangle1) == true)
					{
						// -y
						x = rectangle1.left;
						y = rectangle2.top - entity1.width;
						foundTile = true;
					}
					else
					{
						rectangle1 = new Rectangle(tileRect1.loc.x, tileRect1.loc.y, tileRect1.width, tileRect1.length);
						rectangle1.bottom += 1000.0; //sw
						if (rectangle2.intersects(rectangle1) == true)
						{
							// +y
							x = rectangle1.left;
							y = rectangle2.top + entity2.width;
							foundTile = true;
						}
					}
				}
			}

			if (foundTile == true)
			{
				var potentialTile : Tile = entity1.board.tiles.getTile(x, y);

				if (potentialTile != null)
				{
					if (isTileAvailable(potentialTile) == true)
					{
						if (entity1.width == 2)
						{
							if (isTileAvailable(entity1.board.tiles.getTile(x + 1, y)) == true
								&& isTileAvailable(entity1.board.tiles.getTile(x, y + 1)) == true
								&& isTileAvailable(entity1.board.tiles.getTile(x + 1, y + 1)) == true)
							{
								return potentialTile;
							}
						}
						else
						{
							return potentialTile;
						}
					}
				}

			}

			return null;
		}

		// returns the available tile at tile distance 'dist' for entity2 behind entity2 in relation to entity1. Available means empty or no alive entities on tile
		public static function getTileAvailableBehindAtDist(entity1 : IBattleEntity, entity2 : IBattleEntity, dist : int) : Tile
		{
			var x : int = 0;
			var y : int = 0;

			var foundTile : Boolean = false;

			var tileRect1 : TileRect = entity1.rect;
			var tileRect2 : TileRect = entity2.rect;

			var rectangle1 : Rectangle = new Rectangle(tileRect1.loc.x, tileRect1.loc.y, tileRect1.width, tileRect1.length);
			var rectangle2 : Rectangle = new Rectangle(tileRect2.loc.x, tileRect2.loc.y, tileRect2.width, tileRect2.length);

			rectangle1.right += 1000.0; //se
			if (rectangle2.intersects(rectangle1) == true)
			{
				// +x
				x = rectangle2.left + dist;
				y = rectangle2.top;
				foundTile = true;
			}
			else
			{
				rectangle1 = new Rectangle(tileRect1.loc.x, tileRect1.loc.y, tileRect1.width, tileRect1.length);
				rectangle1.left -= 1000.0; //nw
				if (rectangle2.intersects(rectangle1) == true)
				{
					// -x
					x = rectangle2.left - dist;
					y = rectangle2.top;
					foundTile = true;
				}
				else
				{
					rectangle1 = new Rectangle(tileRect1.loc.x, tileRect1.loc.y, tileRect1.width, tileRect1.length);
					rectangle1.top -= 1000.0; //ne
					if (rectangle2.intersects(rectangle1) == true)
					{
						// -y
						x = rectangle2.left;
						y = rectangle2.top - dist;
						foundTile = true;
					}
					else
					{
						rectangle1 = new Rectangle(tileRect1.loc.x, tileRect1.loc.y, tileRect1.width, tileRect1.length);
						rectangle1.bottom += 1000.0; //sw
						if (rectangle2.intersects(rectangle1) == true)
						{
							// +y
							x = rectangle2.left;
							y = rectangle2.top + dist;
							foundTile = true;
						}
					}
				}
			}

			if (foundTile == true)
			{
				var potentialTile : Tile = entity1.board.tiles.getTile(x, y);

				if (potentialTile != null)
				{
					if (isTileAvailable(potentialTile, entity2) == true)
					{
						if (entity2.width == 2)
						{
							if (isTileAvailable(entity1.board.tiles.getTile(x + 1, y), entity2) == true
								&& isTileAvailable(entity1.board.tiles.getTile(x, y + 1), entity2) == true
								&& isTileAvailable(entity1.board.tiles.getTile(x + 1, y + 1), entity2) == true)
							{
								return potentialTile;
							}
						}
						else
						{
							return potentialTile;
						}
					}
				}

			}

			return null;
		}

		// JU_TODO: change this to deal with actual props that are blockers.  Right now just does a tile check
		public static function axialPathClearOfBlockers(entity : IBattleEntity, destX : int, destY : int) : Boolean
		{
			const deltaOnX : Boolean = (entity.y == destY);
			var delta : int = deltaOnX ? destX - entity.x : destY - entity.y;
			var increment : int = (delta > 0) ? 1 : -1;
			var step : int = increment;

			while (delta != 0)
			{
				var tile : Tile = null;

				if (deltaOnX)
				{
					tile = entity.board.tiles.getTile(entity.x + step, entity.y);
				}
				else
				{
					tile = entity.board.tiles.getTile(entity.x, entity.y + step);
				}

				if (tile == null)
				{
					return false;
				}

				if (entity.width == 2)
				{
					if (entity.board.tiles.getTile(tile.x + 1, tile.y) == null
						|| entity.board.tiles.getTile(tile.x, tile.y + 1) == null
						|| entity.board.tiles.getTile(tile.x + 1, tile.y + 1) == null)
					{
						return false;
					}

				}

				step += increment;
				delta -= increment;
			}

			return true;
		}

	}
}
