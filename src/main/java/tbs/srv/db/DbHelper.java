package tbs.srv.db;

import java.sql.Connection;
import java.sql.Statement;
import java.sql.Timestamp;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

import org.apache.log4j.Logger;

public class DbHelper {

	private static final Logger logger = Logger.getLogger(DbHelper.class.getSimpleName());

	public static final String DateFormatString = "yyyy/MM/dd HH:mm:ss";

	public static final boolean DBHELPER_DEBUG = false;

	public static final DateFormat dateFormat() {
		return new SimpleDateFormat(DateFormatString);
	}

	public static final Timestamp sqlTimestamp() {
		Date date = new java.util.Date();
		return new Timestamp(date.getTime());
	}

	public static final void cleanup(Connection con, Statement s) {
		try {
			if (s != null)
				s.close();
		} catch (Exception e) {
			logger.error("DbHelper failed to close statement: " + e);
			e.printStackTrace();
		}

		try {
			if (con != null)
				con.close();
		} catch (Exception e) {
			logger.error("DbHelper FAILED TO CLOSE CONNECTION: " + e);
			e.printStackTrace();
		}

	}
}
