package tbs.srv.web.providers;

import java.util.HashMap;

import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.ExceptionMapper;
import javax.ws.rs.ext.Provider;

import com.sun.jersey.api.MessageException;

@Provider
@Produces(MediaType.APPLICATION_JSON)
public class MessageExpMapper implements ExceptionMapper<MessageException> {

	public Response toResponse(MessageException exception) {

		HashMap<String, Object> jo = new HashMap<String, Object>();
		HashMap<String, Object> err = new HashMap<String, Object>();

		err.put("message", exception.getMessage());
		err.put("class", exception.getClass().toString());
		err.put("stack", exception.getStackTrace());
		jo.put("error", err);

		exception.printStackTrace();

		return Response.serverError().entity(jo).build();
	}
}