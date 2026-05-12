package engine.battle
{
	import engine.core.logging.ILogger;
	import engine.def.EngineJsonDef;

	public class SceneListDefVars extends SceneListDef
	{
		public static const schema : Object =
			{
				name: "BattleSceneListDefVars",
				properties:
				{
					scenes: {type: "array", item: SceneListItemDefVars.schema}
				}
			};

		public function SceneListDefVars(vars : Object, logger : ILogger)
		{
			EngineJsonDef.validateThrow(vars, schema, logger);

			for each (var sv : Object in vars.scenes)
			{
				const item : SceneListItemDef = new SceneListItemDefVars(sv, logger);
				addItem(item);
			}
		}
	}
}
