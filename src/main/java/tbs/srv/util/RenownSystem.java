package tbs.srv.util;

import java.io.IOException;

import org.apache.log4j.Logger;

import com.rabbitmq.client.Channel;

public class RenownSystem {

	public static final Logger logger = Logger.getLogger(RenownSystem.class.getSimpleName());
	public static final String EXCHANGE = "renown";
	// public static final String KEY = "key_renown";

	private final GameConfig config;

	public RenownSystem(GameConfig config) throws IOException {
		final Channel channel = config.rabbit.createChannel(this);
		this.config = config;
		channel.exchangeDeclare(EXCHANGE, "direct", true, false, null);
		channel.close();
	}

	public void modifyRenown(final long user, final int delta, final RenownReason reason, final String note) {
		final ModifyRenownData data = new ModifyRenownData(user, false, delta, reason, note);
		logger.debug("modifying " + data);
		config.msg.send(EXCHANGE, data, MsgSystem.ZIP, "");
	}

	public void setRenown(final long user, final int amount, final RenownReason reason, final String note) {
		final ModifyRenownData data = new ModifyRenownData(user, true, amount, reason, note);
		logger.debug("set " + data);
		config.msg.send(EXCHANGE, data, MsgSystem.ZIP, "");
	}
}
