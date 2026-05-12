package engine.entity.def
{
	import flash.events.IEventDispatcher;

	import engine.ability.IAbilityDefLevels;
	import engine.core.IId;
	import engine.core.INamed;
	import engine.saga.VariableBag;
	import engine.stat.model.IStatsProvider;

	public interface IEntityDef extends IId, INamed, IStatsProvider, IEventDispatcher
	{
		function get entityClass() : IEntityClassDef;
		function get power() : int;
		function get attacks() : IAbilityDefLevels;
		function get actives() : IAbilityDefLevels;
		function get passives() : IAbilityDefLevels;
		function get upgrades() : int;
		function get appearanceIndex() : int;
		function set appearanceIndex(value : int) : void;
		function get startDate() : Number;
		function duplicate(id : String) : IEntityDef;
		function isAppearanceAcquired(index : int) : Boolean;
		function acquireAppearance(index : int) : void;
		function readyToPromote(killsToPromote : int) : Boolean;
		function get killRenown() : int;
		function get appearance() : IEntityAppearanceDef;
		function get vars() : VariableBag;
		function synchronizeToVars() : void;
	}
}
