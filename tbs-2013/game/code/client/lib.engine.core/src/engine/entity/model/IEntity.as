package engine.entity.model
{
	import engine.core.IUpdateable;
	import engine.entity.def.IEntityDef;
	import engine.stat.model.IStatsProvider;
	
	import flash.events.IEventDispatcher;

	public interface IEntity extends IStatsProvider, IEventDispatcher, IUpdateable
	{
		function get name() : String;
		function get id() : String;
		function get def() : IEntityDef;
		function get isPlayer() : Boolean;
		function get isEnemy() : Boolean;
		function get playerControlled() : Boolean;
	}
}
