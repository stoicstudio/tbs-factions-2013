package engine.ability
{

	public interface IAbilityDefLevel
	{
		function get id() : String;
		function get def() : IAbilityDef;
		function get level() : int;
	}
}
