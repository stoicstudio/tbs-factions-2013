package tbs.srv.util;

import java.io.IOException;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import javax.ws.rs.core.Response;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON;

import com.newrelic.api.agent.NewRelic;
import com.newrelic.api.agent.Trace;
import com.rabbitmq.client.AMQP.BasicProperties;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.GetResponse;
import com.rabbitmq.client.MessageProperties;
import com.rabbitmq.client.ShutdownSignalException;

public class MsgSystem {

	private static final Logger logger = Logger.getLogger(MsgSystem.class.getSimpleName());

	public static final boolean ZIP = true;

	private Channel pollChannel;

	public MsgSystem(GameConfig config) {
	}

	// SENDING API

	private boolean send(String exchange, BasicProperties properties, byte[] body, String key) {
		return send(getChannelFromPool(), exchange, properties, body, key);
	}

	public static boolean send(Channel channel, String exchange, BasicProperties properties, byte[] body, final String key) {
		if (channel == null) {
			return false;
		}
		try {
			channel.basicPublish(exchange, key, false, false, properties, body);
			return true;
		} catch (Exception e) {
			logger.error("FAILED " + key + ": " + e);
			e.printStackTrace();
			return false;
		}
	}

	public boolean send(String exchange, BasicProperties properties, byte[] body) {
		return send(exchange, properties, body, "");
	}

	public boolean send(String exchange, Object msg, boolean zip) {
		return send(exchange, msg, zip, "");
	}

	public static boolean send(Channel channel, String exchange, Object msg, boolean zip) {
		return send(channel, exchange, msg, zip, "");
	}

	public static boolean send(Channel channel, String exchange, Object msg, boolean zip, String key) {

		NewRelic.incrementCounter("Custom/rabbit/send/count/" + msg.getClass().getSimpleName());
		byte[] body;
		String jstr = JSON.toString(msg);
		BasicProperties properties;
		byte[] bytes = jstr.getBytes(Charset.forName("UTF-8"));
		if (zip) {
			body = Zip.compress(bytes);
			properties = MessageProperties.BASIC;
		} else {
			body = bytes;
			properties = MessageProperties.TEXT_PLAIN;
		}

		NewRelic.incrementCounter("Custom/rabbit/send/bytes/" + msg.getClass().getSimpleName(), body.length);

		if (!send(channel, exchange, properties, body, key)) {
			logger.warn("send failed for " + msg);
			return false;
		}
		return true;
	}

	public boolean send(String exchange, Object msg, boolean zip, String key) {
		try {
			final Channel c = _getChannel();
			final boolean result = send(c, exchange, msg, zip, key);
			c.close();
			return result;
		} catch (Exception e) {
			logger.error("send " + msg + ": " + e.getMessage());
		}
		return false;
	}

	// RECEIVING API

	public static String getUserQueue(long account_id) {
		return "qu_" + Long.toString(account_id);
	}

	public static boolean declareUserQueue(Channel channel, String q, final boolean bindFanout) {
		try {
			channel.queueDeclare(q, false, false, true, null);
			if (bindFanout) {
				channel.queueBind(q, "amq.fanout", "");
			}
			return true;
		} catch (Exception e) {
			logger.error("declareUserQueue " + q + ": " + e.getMessage());
			return false;
		}
	}

	public boolean declareUserQueue(final long id) {
		final String q = MsgSystem.getUserQueue(id);
		return declareUserQueue(q, true);
	}

	public boolean declareUserQueue(String q, final boolean fanout) {
		try {
			final Channel c = _getChannel();
			final boolean result = declareUserQueue(c, q, fanout);
			c.close();
			return result;
		} catch (Exception e) {
			logger.error("declareUserQueue " + q + ": " + e.getMessage());
		}
		return false;
	}

	public void purgeUser(final long account_id) {
		final String q = MsgSystem.getUserQueue(account_id);
		declareUserQueue(q, false);

		logger.debug("Purging user queue " + q);
		try {
			final Channel c = getChannelFromPool();
			if (c != null) {
				c.queuePurge(q);
			}
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public static Object getMessage(Channel channel, String q) {

		// TODO we have many threads spamming the same channel, creating locking contention.
		// see about using some kind of channel pool

		if (channel == null) {
			return null;
		}

		try {
			final GetResponse gr = channel.basicGet(q, true);
			return parseResponsePoll(gr);
		} catch (Exception e) {
			logger.warn("Failed to get message for " + q + ": " + e);
		}
		return null;
	}

	public static Object parseResponsePoll(GetResponse gr) {
		return parseResponse(gr, "poll");
	}

	public static Object parseResponseConsume(final byte[] body, final BasicProperties properties, final String tag) {
		return parseResponse(body, properties, "cons/");
	}

	public static Object parseResponse(GetResponse gr, final String type) {
		if (gr == null) {
			return null;
		}

		final byte[] body = gr.getBody();
		final BasicProperties props = gr.getProps();
		return parseResponse(body, props, type);
	}

	public static Object parseResponse(byte[] body, BasicProperties properties, final String type) {
		if (body == null || properties == null) {
			return null;
		}

		final String ct = properties.getContentType();

		if (ct == null) {
			return null;
		}

		String jstr = null;
		if (ct.equals(MessageProperties.BASIC.getContentType())) {
			byte[] raw = Zip.decompress(body);
			jstr = new String(raw, Charset.forName("UTF-8"));
		} else {
			jstr = new String(body);
		}

		final Object parsed = JSON.parse(jstr);

		if (parsed != null) {
			final String cn = parsed.getClass().getSimpleName();
			NewRelic.incrementCounter("Custom/rabbit/" + type + "/count/" + cn);
			NewRelic.incrementCounter("Custom/rabbit/" + type + "/bytes/" + cn, jstr.length());
		}

		return parsed;

	}

	public static List<Object> getAllMessages(final Channel channel, long account_id, List<Object> results, final Object tag, final int max) {
		String q = getUserQueue(account_id);
		declareUserQueue(channel, q, true);
		return getAllMessages(channel, q, results, tag, max);
	}

	@Trace
	public List<Object> getAllMessages(String q, List<Object> results, final Object tag, final int max) {
		final List<Object> msgs = getAllMessages(getChannelFromPool(), q, results, tag, max);
		return msgs;
	}

	@Trace
	public static List<Object> getAllMessages(final Channel channel, String q, List<Object> results, final Object tag, final long allow_ms) {

		if (channel == null) {
			return null;
		}

		final long start_time = System.currentTimeMillis();

		Object msg = getMessage(channel, q);
		while (msg != null) {
			if (results == null) {
				results = new ArrayList<Object>();
			}

			logger.debug("[" + tag + "] POPPED " + q + ": " + msg);

			results.add(msg);

			final long end_time = System.currentTimeMillis();
			final long delta_time = end_time - start_time;
			if (delta_time > allow_ms) {
				break;
			}

			msg = getMessage(channel, q);
		}

		return results;
	}

	private static AtomicInteger utilChannelCounter = new AtomicInteger();

	private static Channel _getChannel() throws IOException {
		return GameConfig.instance.rabbit.createTemporaryChannel("MsgSystem_util_" + utilChannelCounter.incrementAndGet(), RabbitConfig.Consume.NO);
	}

	// private ArrayList<Channel> channels = new ArrayList<Channel>();
	// private int numPooledChannels = 0;
	// private int MAX_NUM_POOLED_CHANNELS = 100;

	private Object[] channelLock = new Object[0];

	private Channel getChannelFromPool() {

		synchronized (channelLock) {
			if (pollChannel == null || !pollChannel.isOpen()) {
				try {
					pollChannel = null;
					pollChannel = GameConfig.instance.rabbit.createTemporaryChannel("MsgSystem poll", RabbitConfig.Consume.NO);// , RabbitConfig.Consume.NO);
				} catch (ShutdownSignalException e) {
					if (!e.isInitiatedByApplication()) {
						logger.warn("Failed to create pollChannel: " + e);
						e.printStackTrace();
					}
				} catch (Exception e) {
					logger.warn("Failed to create pollChannel: " + e.getCause());
				}
			}

			return pollChannel;
		}

		// Channel c = null;
		//
		// synchronized (channels) { if (channels.isEmpty()) { try { if (numPooledChannels > MAX_NUM_POOLED_CHANNELS) { return null; } c =
		// config.rabbit.createChannel(this); ++numPooledChannels; } catch (IOException e) { // TODO Auto-generated catch block e.printStackTrace(); return
		// null; } } else { return channels.remove(channels.size() - 1); } }
		//
		// logger.info("getChannelFromPool count=" + numPooledChannels); return c;

	}

	private void returnChannelToPool(final Channel c) {

		/*
		 * synchronized (channels) { channels.add(c); }
		 */
	}

	public static final int MAX_MSG_POPPING_MS = 300;

	@Trace
	public Response getResponse(final String tag, long user, Object... additional) {
		List<Object> msgs = null;
		final Channel c = getChannelFromPool();
		if (c != null) {
			msgs = getAllMessages(c, user, null, tag, MAX_MSG_POPPING_MS);
			returnChannelToPool(c);
		} else {
			logger.warn("getResponse " + tag + "/" + user + " unable to get a channel");
		}

		if (additional != null) {
			for (Object other : additional) {
				if (msgs == null) {
					msgs = new ArrayList<Object>();
				}
				msgs.add(other);
			}
		}

		if (msgs != null) {
			final String json = JSON.toString(msgs);
			return Response.ok(json).build();
		}

		return Response.ok().build();

	}

}
