package engine.ability
{

	public interface IAbilityDefLevels
	{
		function get numAbilities() : int
		function getAbilityDef(index : int) : IAbilityDef
		function getAbilityDefLevel(index : int) : IAbilityDefLevel
		function getAbilityIndex(id : String) : int
		function getAbilityDefById(id : String) : IAbilityDef
		function getAbilityDefLevelById(id : String) : IAbilityDefLevel
		function getAbilityLevel(index : int) : int
		function hasAbility(id : String) : Boolean;
		function setAbilityDefLevel(def : IAbilityDef, level : int) : void;
		function clone() : IAbilityDefLevels;
	}
}
