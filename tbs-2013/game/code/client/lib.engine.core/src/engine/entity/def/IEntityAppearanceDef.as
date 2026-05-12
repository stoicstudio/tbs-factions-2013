package engine.entity.def
{

	public interface IEntityAppearanceDef
	{
		function get portraitUrl() : String;
		function get backPortraitUrl() : String;
		function get versusPortraitUrl() : String;
		function get promotePortraitUrl() : String;
		function get soundsUrl() : String;
		function get animsUrl() : String;
		function get vfxUrl() : String;
		function getIconUrl(type : EntityIconType) : String;
		function setIconUrl(type : EntityIconType, val : String) : void;
		function get baseIconUrl() : String;
		function get unlock_id() : String;
		function get acquire_id() : String;
	}
}
