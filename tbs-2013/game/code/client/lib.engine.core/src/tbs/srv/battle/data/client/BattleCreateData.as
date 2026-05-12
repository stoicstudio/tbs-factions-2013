package tbs.srv.battle.data.client
{
	import engine.core.logging.ILogger;

	import tbs.srv.battle.data.BattlePartyData;

	public class BattleCreateData extends BaseBattleTurnData
	{
		public var parties : Vector.<BattlePartyData> = new Vector.<BattlePartyData>;
		public var scene : String;
		public var friendly : Boolean;

		public function BattleCreateData()
		{
		}

		public function setupBattleCreateData(battle_id : String) : BattleCreateData
		{
			this.battle_id = battle_id;
			return this;
		}

		override public function parseJson(json : Object, logger : ILogger) : void
		{
			super.parseJson(json, logger);

			this.scene = json.scene;
			this.friendly = json.friendly;

			for each (var po : Object in json.parties)
			{
				var bpd : BattlePartyData = new BattlePartyData;
				bpd.parseJson(po, logger);
				parties.push(bpd);
			}
		}

	}
}
