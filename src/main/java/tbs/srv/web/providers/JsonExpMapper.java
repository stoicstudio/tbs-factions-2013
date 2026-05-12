package tbs.srv.web.providers;

import java.util.HashMap;

import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.ExceptionMapper;
import javax.ws.rs.ext.Provider;

@Provider
@Produces(MediaType.APPLICATION_JSON)
public class JsonExpMapper implements ExceptionMapper<Exception> {

	public Response toResponse(Exception exception) {

		HashMap<String, Object> jo = new HashMap<String, Object>();
		HashMap<String, Object> err = new HashMap<String, Object>();

		err.put("message", exception.getMessage());
		err.put("class", exception.getClass().toString());
		jo.put("error", err);

		exception.printStackTrace();

		return Response.serverError().entity(jo).build();
	}
}