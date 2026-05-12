package game.session.actions
{
	import engine.core.http.HttpJsonAction;
	import engine.core.http.HttpRequestMethod;
	import engine.entity.def.IEntityDef;

	import game.cfg.AccountInfoDefVars;
	import game.cfg.GameConfig;

	public class AccountInfoTxn extends HttpJsonAction
	{
		public static const PATH : String = "services/account/info";
		public var config : GameConfig;
		private var initialized : Boolean;

		public function AccountInfoTxn(callback : Function, config : GameConfig)
		{
			super(PATH + config.fsm.credentials.urlCred, HttpRequestMethod.GET, null, callback, config.logger);
			this.config = config;
		}

		override protected function handleJsonResponseProcessing() : void
		{
			if (jsonObject)
			{
				consumedTxn = true;
				try
				{
					var ac : AccountInfoDefVars = new AccountInfoDefVars(jsonObject, config);
					if (ac.legend.roster.numEntityDefs > 0)
					{
						for (var i : int = 0; i < ac.legend.roster.numEntityDefs; )
						{
							const ent : IEntityDef = ac.legend.roster.getEntityDef(i);
							if (config.runMode.isClassAvailable(ent.entityClass.id))
							{
								++i;
							}
							else
							{
								logger.info("AccountInfoTxn PRUNING " + ent);
								ac.legend.roster.removeEntityDef(ent);									
								ac.legend.party.removeMember(ent.id);
							}
						}

						// if we have chars on the server, use them
						// otherwise just stick with the default

						if (config.stashed_account_info)
						{
							config.stashed_account_info = ac;
						}
						else
						{
							config.accountInfo = ac;
						}

						if (config.options.partyOverride)
						{
							ac.legend.party.reset(config.options.partyOverride);
						}
					}
				}
				catch (e : Error)
				{
					config.logger.error("AccountInfoAction fail: " + e.getStackTrace());
				}
			}
			else
			{
				config.accountInfo = null;
			}
		}
	}
}
