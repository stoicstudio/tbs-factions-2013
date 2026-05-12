package stoic.server.services;

import com.sun.jersey.api.client.config.ClientConfig;
import com.sun.jersey.api.client.config.DefaultClientConfig;
import com.sun.jersey.test.framework.JerseyTest;
import com.sun.jersey.test.framework.WebAppDescriptor;

/**
 * 
 */
public class BattleServiceTest extends JerseyTest {

	static ClientConfig cc = new DefaultClientConfig();
	static WebAppDescriptor wad;
	static {
		// cc.getFeatures().put(JSONConfiguration.FEATURE_POJO_MAPPING,
		// Boolean.TRUE);
		wad = new WebAppDescriptor.Builder("stoic.server.web.services").contextPath("").servletPath("").clientConfig(cc).build();
	}

	public BattleServiceTest() throws Exception {
		super(wad);
	}

//	/**
//	 * Test that the expected response is sent back.
//	 * 
//	 * @throws java.lang.Exceptiont
//	 */
//	@Test
//	public void testDeployPlayer0() throws Exception {
//
//		WebResource webResource = resource();
//		ClientResponse r = webResource.path("battle/deploy/send/battleId/0/username/sessionKey").accept(MediaType.APPLICATION_JSON).post(ClientResponse.class);
//		Assert.assertEquals(200, r.getStatus());
//	}

}
