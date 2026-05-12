package tbs.srv.util;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class CurrencyData implements Convertible {

	public String currency;

	public CurrencyData() {

	}

	public CurrencyData(final String currency) {
		super();
		this.currency = currency;
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("currency", currency);

	}

	@SuppressWarnings("rawtypes")
	@Override
	public void fromJSON(Map object) {
		currency = (String) object.get("currency");
	}

}
