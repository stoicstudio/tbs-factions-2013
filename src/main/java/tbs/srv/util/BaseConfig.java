package tbs.srv.util;

import org.apache.log4j.Logger;

public class BaseConfig {

	// environment

	protected Logger logger;

	public BaseConfig(Logger logger) {

		this.logger = logger;

	}

	public String getEnv(final String name, final String value, final boolean required) {
		String v = System.getenv(name);

		if (v == null) {

			if (required) {
				throw new RuntimeException("BaseConfig " + name + " MISSING FROM ENVIRONMENT");
			}

			v = value;
		}

		logger.info("BaseConfig " + name + "=" + v);
		return v;
	}

	public boolean getEnvBoolean(String name, boolean value, boolean required) {
		String v = getEnv(name, Boolean.toString(value), required);
		return Boolean.parseBoolean(v);
	}

	public int getEnvInteger(String name, int value, boolean required) {
		String v = getEnv(name, Integer.toString(value), required);
		return Integer.parseInt(v);
	}

	public long getEnvLong(final String name, final long value, final boolean required) {
		final String v = getEnv(name, Long.toString(value), required);
		return Long.parseLong(v);
	}
}
