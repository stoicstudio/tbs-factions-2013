package game.cfg
{
	import engine.def.BooleanVars;
	import engine.def.EngineJsonDef;
	import engine.entity.def.EntityListDefVars;
	import engine.entity.def.PartyDefVars;

	import tbs.srv.data.PurchasableUnitsData;
	import tbs.srv.util.PurchaseCountData;
	import tbs.srv.util.UnlockData;

	public class AccountInfoDefVars extends AccountInfoDef
	{

		public static const schema : Object =
			{
				name: "AccountInfoDefVars",
				type: "object",
				properties: {
					roster: {type: EntityListDefVars.schema},
					party: {type: PartyDefVars.schema},
					renown: {type: "number"},
					purchasable_units: {type: PurchasableUnitsData.schema},
					daily_login_streak: {type: "number"},
					daily_login_bonus: {type: "number"},
					unlocks: {type: "array", item: UnlockData.schema},
					purchases: {type: "array", item: PurchaseCountData.schema},
					roster_rows: {type: "number"},
					iap_sandbox: {type: "boolean", optional: true},
					server_time: {type: "number", optional: true},
					completed_tutorial: {type: "boolean", optional: true},
					login_count: {type: "number", optional: true}
				}
			};

		public function AccountInfoDefVars(vars : Object, gameConfig : GameConfig)
		{
			super(gameConfig);

			EngineJsonDef.validateThrow(vars, schema, logger);

			legend.roster = new EntityListDefVars(gameConfig.context.locale).fromJson(vars.roster, logger, gameConfig.abilityFactory, gameConfig.classes);
			legend.party = new PartyDefVars(vars.party, legend.roster, logger);
			legend.renown = vars.renown;

			// supply the purchasable units to the manager
			const pusd : PurchasableUnitsData = new PurchasableUnitsData;
			pusd.parseJson(vars.purchasable_units, logger);

			daily_login_streak = vars.daily_login_streak;
			daily_login_bonus = vars.daily_login_bonus;

			gameConfig.purchasableUnits.update(pusd);

			for each (var udv : Object in vars.unlocks)
			{
				const unlock : UnlockData = new UnlockData();
				unlock.parseJson(udv, logger);
				setUnlock(unlock);
			}

			for each (var pcdv : Object in vars.purchases)
			{
				const pcd : PurchaseCountData = new PurchaseCountData();
				pcd.parseJson(pcdv, logger);
				purchases.addPurchase(pcd);
			}

			legend.rosterRowCount = vars.roster_rows;

			iap_sandbox = vars.iap_sandbox;

			if (vars.server_time != undefined)
			{
				server_delta_time = vars.server_time - (new Date).time;

				logger.info("AccountInfoDefVars server_delta_time=" + server_delta_time);
			}

			completed_tutorial = BooleanVars.parse(vars.completed_tutorial, false);

			if (vars.login_count != undefined)
			{
				login_count = vars.login_count;
			}
		}

//		public static function save(rhs : AccountInfoDef) : Object
//		{
//			var r : Object = {};
//
//			r.roster = EntityListDefVars.save(rhs.roster);
//			r.party = PartyDefVars.save(rhs.party);
//			r.renown = rhs.renown;
//
//			return r;
//		}
	}
}
