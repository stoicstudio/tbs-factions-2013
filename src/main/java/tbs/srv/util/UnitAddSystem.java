package tbs.srv.util;

import java.io.IOException;

import org.apache.log4j.Logger;

import tbs.srv.data.EntityDef;

public class UnitAddSystem {

	public static final Logger logger = Logger.getLogger(UnitAddSystem.class.getSimpleName());

	public static final String KEY = "key_unit_add";

	public UnitAddSystem() throws IOException {
	}

	public void addUnit(final long account_id, final EntityDef unit) {
		final UnitAddData data = new UnitAddData(account_id, unit);
		logger.info("unlocking " + data);
		GameConfig.instance.msg.send("amq.direct", data, MsgSystem.ZIP, KEY);
	}
}
