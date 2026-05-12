package engine.achievement
{
	import engine.core.locale.Locale;
	import engine.core.locale.LocaleCategory;
	import engine.core.locale.Localizer;

	import engine.core.logging.ILogger;
	import engine.def.EngineJsonDef;

	public class AchievementListDefVars extends AchievementListDef
	{
		public static const schema : Object =
			{
				name: "AchievementListDefVars",
				properties:
				{
					achievements: {type: "array", item: AchievementDefVars.schema}
				}
			};

		public function AchievementListDefVars(vars : Object, logger : ILogger, locale : Locale)
		{
			var localizer : Localizer = locale.getLocalizer(LocaleCategory.ACHIEVEMENT);
			EngineJsonDef.validateThrow(vars, schema, logger);

//			var dd : String = "";
			for each (var sv : Object in vars.achievements)
			{
				const def : AchievementDef = new AchievementDefVars(sv, logger, localizer);
				addDef(def);

//				dd += def.name + "\n";
//				dd += def.description + "\n";
//				dd += def.iconUrl + "\n";
				
			}

//			logger.info("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
//			logger.info(dd);
		}
	}
}
