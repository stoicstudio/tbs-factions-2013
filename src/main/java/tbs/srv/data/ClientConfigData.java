package tbs.srv.data;

import java.util.Map;

import org.apache.log4j.Logger;
import org.codehaus.jackson.JsonNode;
import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class ClientConfigData implements Convertible {

	public static final Logger logger = Logger.getLogger(ClientConfigData.class.getSimpleName());

	public String os;
	public String client_language;
	public String os_language;
	public int screen_width;
	public int screen_height;
	public int screen_dpi;

	public ClientConfigData() {

	}

	public ClientConfigData(JsonNode json) {

		try {
			os = json.get("os").getTextValue();
			
			if (!json.has("os_language")) {
				logger.warn("Missing os_language in json node " + json.toString());
				os_language = "??";
			} else {
				os_language = json.get("os_language").getTextValue();
			}					
			
			if (!json.has("client_language")) {
				logger.warn("Missing client_language in json node " + json.toString());
				client_language = os_language != null ? os_language.substring(0, 2) : "??";
			} else {
				client_language = json.get("client_language").getTextValue();
			}
			screen_width = json.get("screen_w").getIntValue();
			screen_height = json.get("screen_h").getIntValue();
			screen_dpi = json.get("screen_dpi").getIntValue();
		} catch (Exception exp) {
			logger.error("Malformed: " + json + ": " + exp);
			exp.printStackTrace();
		}
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(getClass());
		out.add("os", os);
		out.add("client_language", client_language);
		out.add("os_language", os_language);
		out.add("screen_width", screen_width);
		out.add("screen_height", screen_height);
		out.add("screen_dpi", screen_dpi);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map object) {
		os = (String) object.get("os");
		client_language = (String) object.get("client_language");
		os_language = (String) object.get("os_language");
		screen_width = ((Number) object.get("screen_width")).intValue();
		screen_height = ((Number) object.get("screen_height")).intValue();
		screen_dpi = ((Number) object.get("screen_dpi")).intValue();

	}
}
