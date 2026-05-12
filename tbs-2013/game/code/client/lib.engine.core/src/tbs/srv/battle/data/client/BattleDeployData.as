package tbs.srv.battle.data.client
{
	import engine.core.logging.ILogger;
	import engine.tile.TileLocationVars;
	import engine.tile.def.TileLocation;

	public class BattleDeployData extends BaseBattleTurnData
	{
		public var tiles : Vector.<TileLocation> = new Vector.<TileLocation>;

		public function BattleDeployData()
		{
		}

		override public function parseJson(json : Object, logger : ILogger) : void
		{
			super.parseJson(json, logger);
			for each (var tlv : Object in json.tiles)
			{
				tiles.push(TileLocationVars.parse(tlv, logger));
			}
		}
	}
}
