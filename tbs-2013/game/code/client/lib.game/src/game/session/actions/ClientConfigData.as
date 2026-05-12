package game.session.actions
{
	import flash.system.Capabilities;

	public class ClientConfigData
	{
		public var os : String;
		public var os_language : String;
		public var client_language : String;
		public var screen_w : int;
		public var screen_h : int;
		public var screen_dpi : int;

		public function ClientConfigData(clang : String)
		{
			os = Capabilities.os;
			os_language = Capabilities.language;
			this.client_language = clang ? clang : "";
			screen_w = Capabilities.screenResolutionX;
			screen_h = Capabilities.screenResolutionY;
			screen_dpi = Capabilities.screenDPI
		}
	}
}
