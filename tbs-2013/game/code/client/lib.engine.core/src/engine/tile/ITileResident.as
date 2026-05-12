package engine.tile
{
	import engine.tile.def.TileRect;

	public interface ITileResident
	{
		function get mobile() : Boolean;
		function get collidable() : Boolean;
		function get x() : Number;
		function get y() : Number;
		function get width() : Number;
		function get length() : Number;
		function get tiles() : Tiles;
		function get centerX() : Number;
		function get centerY() : Number;
		function get rect() : TileRect;
		function get tile() : Tile;
	}
}
