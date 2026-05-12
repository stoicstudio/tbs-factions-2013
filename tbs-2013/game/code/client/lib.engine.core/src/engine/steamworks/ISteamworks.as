package engine.steamworks
{
	import flash.events.IEventDispatcher;

	public interface ISteamworks extends IEventDispatcher
	{
		function create() : Boolean;
		function get enabled() : Boolean;
		function get initialized() : Boolean;

		function SteamID_GetAccountId(sid : String) : int;
		function SteamAPI_RestartAppIfNecessary(appId : int) : Boolean;
		function SteamAPI_Init() : Boolean;
		function SteamAPI_RunCallbacks() : void;
		function SteamAPI_Shutdown() : void;
		function SteamUser_GetSteamID() : String;
		function SteamUser_GetAuthSessionTicketHandle() : int;
		function SteamUser_GetAuthSessionTicket(ticketHandle : int) : String;
		function SteamUser_CancelAuthTicket(ticket : int) : void;
		function SteamFriends_GetFriendCount(flags : int) : int;
		function SteamFriends_GetFriendByIndex(index : int, flags : int) : String;
		function SteamFriends_GetPersonaName() : String;
		function SteamApps_GetCurrentGameLanguage() : String;
		function SteamUtils_BOverlayNeedsPresent() : Boolean;
		function SteamUtils_IsOverlayEnabled() : Boolean;
		function SteamFriends_ActivateGameOverlay(location : String) : void;
		function SteamFriends_ActivateGameOverlayToUser(location : String, steamId : String) : void;
		function SteamFriends_ActivateGameOverlayToWebPage(url : String) : void;
		function SteamFriends_ActivateGameOverlayToStore(appid : int, flag : int) : void;
	}
}
