package engine.entity.def
{
	import flash.events.IEventDispatcher;
	
	import engine.core.locale.Locale;

	public interface IEntityListDef extends IEventDispatcher
	{
		function getEntityDefById(id : String) : IEntityDef;

		function get numEntityDefs() : int;

		function getEntityDef(index : int) : IEntityDef;

		function removeEntityDef(entity : IEntityDef) : void;

		function addEntityDef(entity : IEntityDef) : void;

		function clear() : void;

		function sort() : void;

		function copyFrom(rhs : IEntityListDef) : void;

		function get classes() : EntityClassDefList;
		
		function get locale() : Locale;
	}
}
