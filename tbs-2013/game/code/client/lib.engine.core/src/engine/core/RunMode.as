package engine.core
{
	import engine.core.util.Enum;

	import flash.utils.Dictionary;

	public class RunMode extends Enum
	{
		public static const DEVELOPER : RunMode = new RunMode("DEVELOPER", false, false, true, true, true, enumCtorKey);
		public static const KIOSK : RunMode = new RunMode("KIOSK", true, true, true, false, false, enumCtorKey);
		public static const BETA : RunMode = new RunMode("BETA", true, false, true, false, false, enumCtorKey);
		public static const FACTIONS : RunMode = new RunMode("FACTIONS", true, false, true, false, false, enumCtorKey);

		public var fullscreen : Boolean;
		public var autologin : Boolean;
		public var town : Boolean;
		public var developer : Boolean;
		public var mainMenu : Boolean;

		private static var available_classes : Dictionary;

		public function RunMode(name : String, fullscreen : Boolean, autologin : Boolean, town : Boolean, mainMenu : Boolean, developer : Boolean, key : Object)
		{
			super(name, key);
			this.fullscreen = fullscreen;
			this.autologin = autologin;
			this.town = town;
			this.mainMenu = mainMenu;
			this.developer = developer;
		}

		public function isClassAvailable(str : String) : Boolean
		{
			if (!available_classes)
			{
				available_classes = new Dictionary;

				available_classes["warhawk"] = true;
				available_classes["provoker"] = true;
				available_classes["skystriker"] = true;
				available_classes["thrasher"] = true;
				available_classes["backbiter"] = true;
				available_classes["siegearcher"] = true;
				available_classes["archer"] = true;
				available_classes["axeman"] = true;
				available_classes["shieldbanger"] = true;
				available_classes["warrior"] = true;
				available_classes["strongarm"] = true;
				available_classes["warmaster"] = true;
				available_classes["bowmaster"] = true;
				available_classes["axemaster"] = true;
				available_classes["shieldmaster"] = true;
				available_classes["warleader"] = true;
			}

			if (developer)
			{
				return true;
			}

			return str in available_classes;
		}
	}
}
