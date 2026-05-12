package tbs.srv.util;

import java.io.IOException;
import java.net.URISyntaxException;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;

import org.apache.log4j.Logger;

import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;
import com.rabbitmq.client.FlowListener;
import com.rabbitmq.client.ShutdownListener;
import com.rabbitmq.client.ShutdownSignalException;

public class RabbitConfig extends BaseConfig implements ShutdownListener {

	public static final Logger logger = Logger.getLogger(RabbitConfig.class.getSimpleName());
	// environment
	public String RABBIT_URL = "amqp://localhost"; // explictly set this if you
													// want to use rabbit
	int MAX_RABBIT_GLOBAL_PREFETCH_MB = 50;
	int MAX_RABBIT_GLOBAL_PREFETCH_BYTES = MAX_RABBIT_GLOBAL_PREFETCH_MB * (1024 * 1024);
	int MAX_RABBIT_GLOBAL_PREFETCH_MSGS = 200000;
	int MAX_RABBIT_CHANNEL_PREFETCH_MSGS = 20000;
	int RABBIT_CONNECTION_ESTABLISHMENT_TIMEOUT_MS = 20000;

	public Connection connection;

	public final String name;

	private final boolean exitsOnClose;

	public RabbitConfig(final String name) {
		this(name, true);
	}

	public RabbitConfig(final String name, final boolean exitsOnClose) {

		super(logger);

		this.name = name;
		this.exitsOnClose = exitsOnClose;

		RABBIT_URL = getEnv("RABBIT_URL", null, true);

		MAX_RABBIT_GLOBAL_PREFETCH_MB = getEnvInteger("MAX_RABBIT_GLOBAL_PREFETCH_MB", MAX_RABBIT_GLOBAL_PREFETCH_MB, false);
		MAX_RABBIT_GLOBAL_PREFETCH_MB = MAX_RABBIT_GLOBAL_PREFETCH_MB * 1024 * 1024;
		MAX_RABBIT_GLOBAL_PREFETCH_MSGS = getEnvInteger("MAX_RABBIT_PREFETCH_MSGS", MAX_RABBIT_GLOBAL_PREFETCH_MSGS, false);
		MAX_RABBIT_CHANNEL_PREFETCH_MSGS = getEnvInteger("MAX_RABBIT_CHANNEL_PREFETCH_MSGS", MAX_RABBIT_CHANNEL_PREFETCH_MSGS, false);
		RABBIT_CONNECTION_ESTABLISHMENT_TIMEOUT_MS = getEnvInteger("RABBIT_CONNECTION_ESTABLISHMENT_TIMEOUT_MS", RABBIT_CONNECTION_ESTABLISHMENT_TIMEOUT_MS,
				false);

		final long CONNECT_RETRY_LIMIT_MS = 30000;
		final long CONNECT_RETRY_SLEEP_MS = 2000;
		final long start = System.currentTimeMillis();
		while ((System.currentTimeMillis() - start) < CONNECT_RETRY_LIMIT_MS) {

			try {
				initializeRabbitMq(name);
				return;
			} catch (Exception exp) {
				logger.warn("Failed to initialize RABBITMQ: " + exp.toString());
				// exp.printStackTrace();
			}

			logger.warn("Sleeping to retry rabbit connection");

			try {
				Thread.sleep(CONNECT_RETRY_SLEEP_MS);
			} catch (InterruptedException e) {
				e.printStackTrace();
				break;
			}
		}

		throw new RuntimeException("Failed to initialize RABBITMQ");
	}

	public void stop() {
		logger.info("CLOSING CONNECTION");
		try {
			connection.close(6000);
		} catch (Exception exp) {
			logger.error("stop: " + exp);
		}
	}

	private void initializeRabbitMq(final Object name) throws KeyManagementException, NoSuchAlgorithmException, URISyntaxException, IOException {
		if (RABBIT_URL != null && !RABBIT_URL.isEmpty()) {
			logger.info("RABBIT INIT " + name);
			// Rabbit MQ
			final ConnectionFactory factory = new ConnectionFactory();
			factory.setUri(RABBIT_URL);
			factory.setConnectionTimeout(RABBIT_CONNECTION_ESTABLISHMENT_TIMEOUT_MS);
			connection = factory.newConnection();

			logger.info("RABBIT " + name + " FACTORY: " + factory.getHost() + ":" + factory.getPort() + " CONNECTION: " + connection);

			logger.info("RABBIT " + name + " CONNECTION:" + //
					" channelMax=" + connection.getChannelMax() + //
					" frameMax=" + connection.getFrameMax() + //
					" heartbeat=" + connection.getHeartbeat() + //
					" client_version=" + connection.getClientProperties().get("version") + //
					" server_version=" + connection.getServerProperties().get("version"));

			connection.addShutdownListener(this);

			// TODO: NON-GLOBAL and PREFETCH SIZES are NOT IMPLEMENTED by RABBIT
			// UGH

			// final Channel channel = createChannel("INIT");
			// channel.basicQos(MAX_RABBIT_GLOBAL_PREFETCH_BYTES,
			// MAX_RABBIT_GLOBAL_PREFETCH_MSGS, true);
			// channel.close();
		}
	}

	@Override
	public void shutdownCompleted(ShutdownSignalException cause) {
		if (cause.isInitiatedByApplication()) {
			logger.info("RABBIT " + name + " SHUTDOWN CLEAN " + this);
		} else {
			logger.error("RABBIT " + name + " SHUTDOWN: " + cause.toString());
			if (exitsOnClose)
			{
			System.exit(1);
			}
		}
	}

	public Channel createChannel(final Object name) throws IOException {
		return createChannel(name, true);
	}

	public Channel createChannel(final Object name, final boolean log) throws IOException {
		return createChannel(name, connection, MAX_RABBIT_CHANNEL_PREFETCH_MSGS, true, log, exitsOnClose);
	}

	public static enum Consume {
		YES, NO
	};

	public Channel createTemporaryChannel(final Object name) throws IOException {
		return createTemporaryChannel(name, Consume.NO);
	}

	public Channel createTemporaryChannel(final Object name, final Consume consume) throws IOException {

		final int qos = consume == Consume.YES ? MAX_RABBIT_CHANNEL_PREFETCH_MSGS : 1;

		return createChannel(name, connection, qos, false, true, exitsOnClose);
	}

	public static synchronized Channel createChannel(final Object channel_name, final Connection con, final int max_channel_prefetch_msgs,
			final boolean permanent, final boolean log, final boolean exitsOnClose) throws IOException {

		// logger.info("Creating new channel...");

		final Channel channel = con.createChannel();

		if (permanent) {
			logger.debug("createChannel PERM: " + channel_name + " " + channel);
		} else if (log) {
			logger.debug("createChannel TEMP: " + channel_name + " " + channel);
		}

		if (channel == null) {
			logger.error("Failed to create channel");
			if (permanent && exitsOnClose) {				
				System.exit(1);
			} else {
				return null;
			}
		}

		channel.addShutdownListener(new ShutdownListener() {
			public void shutdownCompleted(ShutdownSignalException cause) {

				if (!cause.isInitiatedByApplication()) {
					if (permanent && exitsOnClose) {
						logger.error("Channel Shutdown " + channel_name + ": " + cause);
						cause.printStackTrace();
						System.exit(1);
					} else {
						logger.debug("Channel Shutdown " + channel_name + ": " + cause);
					}
				} else {
					// logger.info("Channel Shutdown CLEAN: " +
					// cause.getMessage());
				}
			}
		});

		channel.addFlowListener(new FlowListener() {

			@Override
			public void handleFlow(boolean active) throws IOException {
				logger.debug("handleFlow " + channel_name + " " + active);
			}
		});

		channel.basicQos(max_channel_prefetch_msgs);

		return channel;
	}
}
