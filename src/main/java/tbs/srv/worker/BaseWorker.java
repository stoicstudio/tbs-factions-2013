package tbs.srv.worker;

import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

import org.apache.log4j.Logger;

import tbs.srv.util.GameConfig;

abstract public class BaseWorker implements Runnable {

	protected final Logger logger;
	protected final GameConfig config;
	private long periodMs;
	public final String name;

	// protected boolean stopping;

	private Semaphore stopper = new Semaphore(0);

	public BaseWorker(Logger logger, GameConfig config, final long periodMs) {
		this.logger = logger;
		this.config = config;
		this.periodMs = periodMs;
		this.name = getClass().getSimpleName();
	}

	private long lastRun = System.currentTimeMillis();

	@Override
	public final void run() {

		logger.info("run");
		
		try {
			startWorker();
		} catch (Exception exp) {
			exp.printStackTrace();
			System.exit(0);
		}

		boolean terminate = false;

		for (;;) {

			final long now = System.currentTimeMillis();
			final long delta = now - lastRun;
			lastRun = now;
			try {
				runWorker(delta);
			} catch (Exception exp) {
				logger.error("Failed to runWorker: " + exp);
				exp.printStackTrace();
				System.exit(1);
				break;
			}

			if (!delay()) {
				terminate = true;
				break;
			}
		}
		
		logger.info("Worker ENDING terminate=" + terminate);

		if (terminate) {
			System.exit(0);
		}
	}

	private boolean delay() {
		try {
			if (periodMs > 0) {
				// wait for the period to elapse and run the worker
				if (stopper.tryAcquire(periodMs, TimeUnit.MILLISECONDS)) {
					// stopper acquired means we are cleanly shutting down
					return false;
				}
			} else {
				// wait for ever and never run the worker
				stopper.acquire();
				return false;
			}
		} catch (InterruptedException e) {
			e.printStackTrace();
			return false;
		}

		return true;

	}

	public void stop() {
		logger.info("Worker STOP " + this);
		stopper.release();
	}

	abstract protected void startWorker() throws Exception;

	abstract protected void runWorker(final long deltaMs) throws Exception;

	abstract protected void stopWorker() throws Exception;
}
