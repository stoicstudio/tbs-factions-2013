package engine.entity.def
{
	import engine.core.IDescribed;
	import engine.core.IId;
	import engine.core.INamed;
	import engine.math.Box;
	import engine.stat.def.IStatRangeOwner;

	public interface IEntityClassDef extends IId, INamed, IDescribed, IStatRangeOwner
	{
		function get parentEntityClass() : IEntityClassDef;
		function get allChildEntityClasses() : Vector.<IEntityClassDef>;
		function get playerOnlyChildEntityClasses() : Vector.<IEntityClassDef>;
		function get passive() : String;
		function get attacks() : Vector.<String>;
		function get actives() : Vector.<String>;
		function get race() : String;
		function get bounds() : Box;
		function get propAnimUrl() : String;
		function get mobile() : Boolean;
		function get collidable() : Boolean;
		function get partyTag() : String;
		function getPartyTagLimit(meta : EntitiesMetadata) : int;
		function setPartyTagLimit(meta : EntitiesMetadata, value : int) : void;
		function get partyTagDisplay() : String;
		function get briefDescription() : String;
		function getEntityClassAppearanceDef(index : int) : IEntityAppearanceDef;
		function getAppearanceName(index : int) : String
		function get appearanceDefs() : Vector.<IEntityAppearanceDef>;
		function get playerClass() : Boolean;
	}
}
