package tbs.srv.util
{

	public interface IIapItemListDef
	{
		function getItem(id : String) : InAppPurchaseItemDef;
		function get mkt() : IapMkt;
		function getPrice(usd_cents : int, currency : String, sale : Boolean) : int;
		function findItemsByUnlock(unlock_id : String) : Vector.<InAppPurchaseItemDef>;
	}
}
