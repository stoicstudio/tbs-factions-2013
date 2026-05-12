package tbs.srv.web.svc.monitor;

import java.util.HashMap;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import net.sf.ehcache.Ehcache;

import org.apache.log4j.Logger;

import tbs.srv.web.WebConfig;

@Path("")
@Produces(MediaType.APPLICATION_JSON)
public class MonitorSvc {

	public static final Logger logger = Logger.getLogger(MonitorSvc.class.getSimpleName());

	@GET
	public Response get() {

		// AmazonSimpleDB db = WebConfig.db();
		HashMap<String, Object> r = new HashMap<String, Object>();

		Runtime runtime = Runtime.getRuntime();
		r.put("freeMemory", runtime.freeMemory() / (1024 * 1024));
		r.put("maxMemory", runtime.maxMemory() / (1024 * 1024));
		r.put("totalMemory", runtime.totalMemory() / (1024 * 1024));

		r.put("authCache", getCacheInfo(WebConfig.instance.authVbbCache));
//		r.put("sessionCache", getCacheInfo(WebConfig.instance.sessionCache));

		return Response.ok(r).build();
	}

	private HashMap<String, Object> getCacheInfo(Ehcache cache) {
		HashMap<String, Object> r = new HashMap<String, Object>();

		long start = System.currentTimeMillis();
		r.put("calculateInMemorySize", WebConfig.instance.authVbbCache.calculateInMemorySize());
		r.put("calculateOffHeapSize", WebConfig.instance.authVbbCache.calculateOffHeapSize());
		r.put("calculateOnDiskSize", WebConfig.instance.authVbbCache.calculateOnDiskSize());
		r.put("getMemoryStoreSize", WebConfig.instance.authVbbCache.getMemoryStoreSize());
		r.put("getDiskStoreSize", WebConfig.instance.authVbbCache.getDiskStoreSize());
		r.put("getOffHeapStoreSize", WebConfig.instance.authVbbCache.getOffHeapStoreSize());
		r.put("getAverageGetTime", WebConfig.instance.authVbbCache.getAverageGetTime());
		long delta = System.currentTimeMillis() - start;

		r.put("monitorTime", delta);

		return r;

	}

}
