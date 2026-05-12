package tbs.srv.util
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	public class PurchaseCounts extends EventDispatcher
	{
		public var purchases : Vector.<PurchaseCountData> = new Vector.<PurchaseCountData>;
		private var purchasesById : Dictionary = new Dictionary;

		public function PurchaseCounts()
		{
		}

		public function getPurchaseCountData(item_id : String) : PurchaseCountData
		{
			const data : PurchaseCountData = purchasesById[item_id];
			return data;
		}

		public function getPurchaseCount(item_id : String) : int
		{
			const data : PurchaseCountData = purchasesById[item_id];
			return data ? data.purchase_count : 0;
		}

		public function addPurchase(pcd : PurchaseCountData) : void
		{
			purchases.push(pcd);
			purchasesById[pcd.item_id] = pcd;
		}

		public function incrementPurchaseCount(item_id : String) : void
		{
			var pcd : PurchaseCountData = getPurchaseCountData(item_id);
			if (pcd)
			{
				++pcd.purchase_count;
			}
			else
			{
				pcd = new PurchaseCountData;
				pcd.item_id = item_id;
				pcd.purchase_count = 1;
				addPurchase(pcd);
			}

			dispatchEvent(new Event(Event.CHANGE));
		}

		public function decrementPurchase(item_id : String) : void
		{
			var pcd : PurchaseCountData = getPurchaseCountData(item_id);
			if (pcd)
			{
				pcd.purchase_count = Math.max(0, pcd.purchase_count - 1);
			}

			dispatchEvent(new Event(Event.CHANGE));
		}
	}
}
