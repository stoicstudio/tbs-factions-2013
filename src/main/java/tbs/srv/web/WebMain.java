package tbs.srv.web;

import java.net.BindException;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

import org.apache.log4j.Logger;
import org.eclipse.jetty.server.AbstractConnector;
import org.eclipse.jetty.server.Connector;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.util.thread.ExecutorThreadPool;
import org.eclipse.jetty.webapp.WebAppContext;

import tbs.srv.worker.WorkerConfig;
import tbs.srv.worker.WorkerMain;

/**
 * 
 * This class launches the web application in an embedded Jetty container. This is the entry point to your application. The Java command that is used for
 * launching should fire this main method.
 * 
 */
public class WebMain {

	public static final Logger logger = Logger.getLogger(WebMain.class.getSimpleName());

	private Server server;
	private WorkerMain wm = null;

	/**
	 * @param args
	 */
	public static void main(String[] args) throws Exception {

		new WebMain(args);
	}

	public WebMain(String[] args) throws Exception {
		logger.debug("_____________________debug_____________________");
		logger.info("STARTING GameServer WEB APP");
		if (!WebConfig.init()) {
			logger.error("FAILED TO INIT WebConfig");
			System.exit(0);
			return;
		}

		Runtime.getRuntime().addShutdownHook(new ShutdownHook());

		Class<?> clazz = Class.forName(WebConfig.instance.JDBC_DRIVER);

		if (clazz == null) {
			logger.error("Failed to load JDBC_DRIVER: " + WebConfig.instance.JDBC_DRIVER);
			System.exit(1);
		} else {
			logger.info("Initialized JDBC_DRIVER: " + clazz);
		}

		String webappDirLocation = "src/main/webapp/";

		server = new Server(WebConfig.instance.PORT);

		int acceptors = 0;
		for (Connector c : server.getConnectors()) {
			final AbstractConnector ac = (AbstractConnector) c;
			acceptors += ac.getAcceptors();
		}

		logger.info("Jetty acceptor threads: " + acceptors + " across connectors: " + server.getConnectors().length);

		final LinkedBlockingQueue<Runnable> queue = new LinkedBlockingQueue<Runnable>(acceptors + WebConfig.instance.JETTY_MAX_QUEUE);
		final ExecutorThreadPool pool = new ExecutorThreadPool(//
				acceptors + WebConfig.instance.JETTY_MIN_THREADS, //
				acceptors + WebConfig.instance.JETTY_MAX_THREADS, //
				WebConfig.instance.JETTY_THREAD_IDLE_MS, //
				TimeUnit.MILLISECONDS, //
				queue);
		server.setThreadPool(pool);

		server.setGracefulShutdown(5000);
		final WebAppContext root = new WebAppContext();

		root.setContextPath("/");
		root.setDescriptor(webappDirLocation + "/WEB-INF/web.xml");
		root.setResourceBase(webappDirLocation);

		// Parent loader priority is a class loader setting that Jetty accepts.
		// By default Jetty will behave like most web containers in that it will
		// allow your application to replace non-server libraries that are part
		// of the
		// container. Setting parent loader priority to true changes this
		// behavior.
		// Read more here:
		// http://wiki.eclipse.org/Jetty/Reference/Jetty_Classloading
		root.setParentLoaderPriority(true);

		server.setHandler(root);

		try {
			server.start();
		} catch (BindException exp) {
			logger.error("Unable to start server: " + exp);
			System.exit(0);
		}

		for (int i = 0; i < args.length; ++i) {
			String arg = args[i];

			if (arg.equals("--worker")) {
				wm = new WorkerMain(true, true);
				wm.go();
			}
		}

		server.join();

		System.exit(0);
		// if (wm != null) {
		// wm.interrupt();
		// }
	}

	public class ShutdownHook extends Thread {
		@Override
		public void run() {

			try {
				doShutdown();
			} catch (Exception exp) {
				exp.printStackTrace();
			}
		}

		private void doShutdown() {
			logger.info("o--vvvv SHUTDOWN HOOK RUNNING...");
			logger.info("o--vvvv STOPPING WEB APP");

			if (server != null) {
				try {
					server.stop();
				} catch (Exception e) {
					logger.error("webserver stop: " + e);
				}
			}

			if (wm != null) {
				logger.info("o--vvvv STOPPING WORKER MAIN");
				wm.stop();
				WorkerConfig.instance.stop();
			}

			logger.info("o--vvvv STOPPING WEBCONFIG");

			WebConfig.instance.stop();
		}
	}
}
