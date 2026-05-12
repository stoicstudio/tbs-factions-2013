package tbs.srv.worker;

import java.io.IOException;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;

import javax.sql.DataSource;

import org.apache.log4j.Logger;

import tbs.srv.db.DbHelper;
import tbs.srv.util.GameConfig;

public class MetricsWorker extends BaseWorker {

	private static final Logger logger = Logger.getLogger(MetricsWorker.class.getSimpleName());

	public MetricsWorker(GameConfig config) throws IOException {
		// spin it every 6 hours
		super(logger, config, 6 * 60 * 60 * 1000);
	}

	@Override
	protected void startWorker() throws Exception {

	}

	@Override
	protected void runWorker(long deltaMs) throws Exception {
		//dbProc("metrics_days");
		//Thread.sleep(60 * 1000);
		//dbProc("metrics_weeks");
		//Thread.sleep(60 * 1000);
		//dbProc("metrics_months");
		//Thread.sleep(60 * 1000);
	}

	private void dbProc(String proc) {
		logger.info("dbProc START " + proc);
		long st = System.currentTimeMillis();
		DataSource ds = config.rdsDatasource;
		Connection con = null;
		CallableStatement s = null;
		try {

			con = ds.getConnection();
			s = con.prepareCall("call " + proc);
			s.execute();

		} catch (SQLException e) {
			e.printStackTrace();
		} finally {
			DbHelper.cleanup(con, s);
		}

		long et = System.currentTimeMillis();
		long dt = et - st;

		logger.info("dbProc END " + proc + " " + dt + "ms");
	}

	@Override
	protected void stopWorker() throws Exception {
		// TODO Auto-generated method stub

	}

}
