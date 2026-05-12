package tbs.srv.web.svc.iap;

import tbs.srv.util.InAppPurchaseItemDef;

public class IapCartItem {
	public final InAppPurchaseItemDef item;
	public final int qty;
	public final int unit_price;
	public final int usd_estimate;
	public final String description;

	public IapCartItem(InAppPurchaseItemDef item, int qty, int unit_price, final int usd_estimate, final String description) {
		super();
		this.item = item;
		this.qty = qty;
		this.unit_price = unit_price;
		this.description = description;
		this.usd_estimate = usd_estimate;
	}

	public String toString() {
		return item + "/" + usd_estimate;
	}

}