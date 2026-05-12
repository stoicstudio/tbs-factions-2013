package game.cfg
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	import engine.core.logging.ILogger;
	import engine.entity.def.EntityClassDefList;
	import engine.entity.def.Legend;

	import tbs.srv.util.CurrencyData;
	import tbs.srv.util.PurchaseCounts;
	import tbs.srv.util.UnlockData;

	public class AccountInfoDef extends EventDispatcher
	{
		public static const UNLOCKS : String = "AccountInfoDef.UNLOCKS";
		public static const CURRENCY : String = "AccountInfoDef.CURRENCY";

		public const crownChitIconUrl : String = "common/battle/banner/chit/crown_jade_backer.png";
		public const crownIconUrl : String = "common/battle/banner/crown/crown_base.png";

		private var classes : EntityClassDefList;
		private var gameConfig : GameConfig;

		public var logger : ILogger;
		public var daily_login_streak : int;
		public var daily_login_bonus : int;
		private var unlocks : Vector.<UnlockData> = new Vector.<UnlockData>;
		private var unlocksById : Dictionary = new Dictionary;

		public var legend : Legend;

		public var tutorial : Boolean;

		public var purchases : PurchaseCounts = new PurchaseCounts;

		public var currency : String = "USD";

		public var iap_sandbox : Boolean;

		public var server_delta_time : Number = 0;

		public var completed_tutorial : Boolean;

		public var login_count : int = 0;

		public function AccountInfoDef(gameConfig : GameConfig)
		{
			this.logger = gameConfig.logger;
			this.classes = gameConfig.classes;
			this.gameConfig = gameConfig;
			legend = new Legend(9, logger, gameConfig.context.locale, gameConfig.classes);
		}

		public function handleUnlock(data : UnlockData) : void
		{
			setUnlock(data);
			dispatchEvent(new Event(UNLOCKS));
		}

		protected function setUnlock(data : UnlockData) : void
		{
			unlocksById[data.unlock_id] = data;

			for (var i : int = 0; i < unlocks.length; ++i)
			{
				const old : UnlockData = unlocks[i];
				if (old.unlock_id == data.unlock_id)
				{
					unlocks[i] = data;
					return;
				}
			}

			unlocks.push(data);
		}

		public function getUnlockById(unlock_id : String) : UnlockData
		{
			const data : UnlockData = unlocksById[unlock_id];
			return data;
		}

		public function hasUnlock(unlock_id : String) : Boolean
		{
			if (unlock_id)
			{
				const u : UnlockData = getUnlockById(unlock_id);
				if (!u)
				{
					return false;
				}

				if (u.unlock_duration <= 0)
				{
					return true;
				}

				// expires in the future
				return (u.unlock_time + u.unlock_duration) > ((new Date()).time + server_delta_time);
			}
			else
			{
				return true;
			}
		}

		public function handleCurrencyData(data : CurrencyData) : void
		{
			if (currency != data.currency)
			{
				currency = data.currency;
				dispatchEvent(new Event(CURRENCY));
			}

		}

	}

}
