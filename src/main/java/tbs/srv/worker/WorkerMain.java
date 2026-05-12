package tbs.srv.worker;

import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.Arrays;

import org.apache.log4j.Logger;

import tbs.srv.util.GameConfig;

public class WorkerMain {

	private static final Logger logger = Logger.getLogger(WorkerMain.class.getSimpleName());

	@SuppressWarnings("rawtypes")
	final public static Class[] workerClasses = new Class[] { //
	VsWorker.class, //
			SessionWorker.class,//
			RenownWorker.class,//
			FriendWorker.class,//
			AchievementWorker.class, //
			UnitAddWorker.class, //
			TourneyWorker.class, //
			SteamUserWorker.class, //
			UnlockWorker.class, //
			LeaderboardWorker.class, //
			SteamDlcWorker.class, //
			MetricsWorker.class };

	@SuppressWarnings("rawtypes")
	private static Class getWorkerClazz(final String shortname) {
		final String simple = shortname + "Worker";
		for (Class c : workerClasses) {
			if (simple.equals(c.getSimpleName())) {
				return c;
			}
		}

		throw new IllegalArgumentException("Invalid shortname=" + shortname + " simple=" + simple);
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) throws Exception {

		logger.info("STARTING WORKER");

		@SuppressWarnings("rawtypes")
		final ArrayList<Class> clazzes = new ArrayList<Class>();

		boolean battle_authority = false;
		boolean chat_authority = false;

		for (int i = 0; i < args.length; ++i) {
			if (args[i].equals("--battle_authority")) {
				battle_authority = true;
				continue;
			}
			if (args[i].equals("--chat_authority")) {
				chat_authority = true;
				continue;
			}
			clazzes.add(getWorkerClazz(args[i]));
		}

		if (clazzes.size() == 0) {
			// running everything -- this is the battle authority
			battle_authority = true;
			chat_authority = true;
		}

		final WorkerMain wm = new WorkerMain(battle_authority, chat_authority, (Class[]) clazzes.toArray(new Class[clazzes.size()]));
		wm.go();
		wm.join();
	}

	public ArrayList<Thread> threads = new ArrayList<Thread>();
	public ArrayList<BaseWorker> workers = new ArrayList<BaseWorker>();

	@SuppressWarnings("rawtypes")
	private Class[] clazzes;

	public WorkerMain(final boolean battle_authority, final boolean chat_authority, @SuppressWarnings("rawtypes") Class... _clazzes) {

		logger.info("WorkerMain battle_authority=" + battle_authority + ", _clazzes=" + Arrays.toString(_clazzes));

		this.clazzes = _clazzes;

		if (clazzes == null || clazzes.length == 0) {

			this.clazzes = workerClasses;
		}

		if (!WorkerConfig.init(battle_authority, chat_authority)) {
			logger.error("FAILED TO INIT WebConfig");
			System.exit(0);
			return;
		}

		final String webPort = System.getenv("PORT");

		logger.info("PORT=" + webPort);
	}

	public void go() throws IOException, InstantiationException, IllegalAccessException, IllegalArgumentException, SecurityException,
			InvocationTargetException, NoSuchMethodException {

		final WorkerConfig config = WorkerConfig.instance;

		for (@SuppressWarnings("rawtypes")
		Class clazz : clazzes) {
			@SuppressWarnings("unchecked")
			final BaseWorker worker = (BaseWorker) clazz.getDeclaredConstructor(GameConfig.class).newInstance(config);
			workers.add(worker);
		}

		for (BaseWorker r : workers) {
			final Thread t = new Thread(r, r.name);
			threads.add(t);
		}

		for (Thread t : threads) {
			t.start();
		}
	}

	public void join() {

		for (Thread t : threads) {
			try {
				t.join();
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
	}

	public void stop() {

		// TODO: spin through workers (BaseWorker) and call stop()

		for (Runnable r : workers) {
			if (r instanceof BaseWorker) {
				final BaseWorker bw = (BaseWorker) r;
				bw.stop();
			}
		}
	}

}
