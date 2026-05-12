package tbs.srv.util;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class PurchaseCountData implements Convertible {

	public long account_id;
	public String item_id;
	public int purchase_count;

	public PurchaseCountData() {

	}

	public PurchaseCountData(ResultSet rs) throws SQLException {

		account_id = rs.getLong("account_id");
		item_id = rs.getString("item_id");
		purchase_count = rs.getInt("purchase_count");
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("account_id", account_id);
		out.add("item_id", item_id);
		out.add("purchase_count", purchase_count);

	}

	@SuppressWarnings("rawtypes")
	@Override
	public void fromJSON(Map object) {
		account_id = ((Number) object.get("account_id")).longValue();
		purchase_count = ((Number) object.get("purchase_count")).intValue();
		item_id = (String) object.get("item_id");
	}

}
