package engine.ability
{
	import engine.stat.model.Stats;

	public interface IAbilityDef
	{
		function get id() : String;
		function get name() : String;
		function get description() : String;
		function get descriptionBrief() : String;
		function get maxLevel() : int;
		function get level() : int;
		function get root() : IAbilityDef;
		function get iconUrl() : String;
		function get iconLargeUrl() : String;
		function get iconBuffUrl() : String;
		function get costs() : Stats;
		function get horn() : int;
		function get displayDamageUI() : Boolean;
		function get optionalStars() : int;

		function getAbilityDefForLevel(level : int) : IAbilityDef;
	}
}
