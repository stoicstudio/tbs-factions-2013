package tbs.srv.web.providers;

import java.util.HashMap;

import javax.ws.rs.Produces;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.ExceptionMapper;
import javax.ws.rs.ext.Provider;

import org.eclipse.jetty.util.ajax.JSON;

@Provider
@Produces(MediaType.APPLICATION_JSON)
public class WebApplicationExpMapper implements ExceptionMapper<WebApplicationException> {

	public static final org.apache.log4j.Logger logger = org.apache.log4j.Logger.getLogger(WebApplicationException.class);

	public Response toResponse(WebApplicationException exception) {

		final Response r = exception.getResponse();
		logger.error("Web App:" + exception.getMessage() + ": " + r.getStatus() + "/" + r.getEntity());

		final HashMap<String, Object> jo = new HashMap<String, Object>();
		final HashMap<String, Object> err = new HashMap<String, Object>();

		// err.put("class", "tbs.srv.web.providers.WebApplicationExceptionMapper");
		err.put("message", r.getEntity());
		err.put("exception_class", exception.getClass().toString());
		jo.put("error_msg", err);

		return Response.status(r.getStatus()).entity(JSON.toString(jo)).build();
	}
}