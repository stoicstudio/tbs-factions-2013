package tbs.srv.web.svc.account.info;

import java.sql.SQLException;
import java.util.ArrayList;

import javax.sql.DataSource;

import org.apache.log4j.Logger;

import tbs.srv.auth.AccountData;
import tbs.srv.data.EntityDef;
import tbs.srv.db.models.UserData;
import tbs.srv.util.FriendSystem;
import tbs.srv.util.GameConfig;
import tbs.srv.util.ICharacterClassProvider;
import tbs.srv.util.MsgSystem;
import tbs.srv.util.RenownReason;
import tbs.srv.web.WebConfig;

import com.newrelic.api.agent.Trace;

public class AccountInit {

	public static final Logger logger = Logger.getLogger(AccountInit.class.getSimpleName());

	@Trace
	public static UserData initializeAccount(GameConfig config, final AccountData account) throws SQLException {

		// make sure the user rabbit q is setup properly
		final String q = MsgSystem.getUserQueue(account.account_id);
		config.msg.declareUserQueue(q, true);

		final ICharacterClassProvider provider = WebConfig.instance;
		final DataSource ds = config.rdsDatasource;

		final UserData user = new UserData(ds, provider, account.account_id);

		user.incrementLoginCount(config);

		setupUser(user);

		user.checkDailyLoginStreak(false);

		// async call to the worker
		FriendSystem.collectFriends(WebConfig.instance.rabbit, account.account_id);

		return user;
	}

	@Trace
	private static void setupUser(final UserData user) throws SQLException {
		final DataSource ds = WebConfig.instance.rdsDatasource;
		final long start_date = System.currentTimeMillis();

		final boolean wasEmpty = user.rosterDefs.size() == 0;
		if (user.rosterDefs.size() < 6) {

			if (wasEmpty) {
				logger.info("setupUser CREATING STARTING ROSTER " + user);
			}

			final EntityDef[] starting_roster = WebConfig.instance.starting_roster;
			for (EntityDef def : starting_roster) {
				if (!user.rosterDefs.containsKey(def.id)) {

					if (!wasEmpty) {
						logger.info("setupUser BACKFILLING STARTING ROSTER " + user + " with " + def.id);
					}

					final EntityDef dd = def.duplicate(def.id);

					if (GameConfig.instance.KIOSK) {
						final int n = dd.characterClassDef.appearances.length;
						dd.appearance_index = Math.max(0, Math.min(n - 1, (int) Math.round(Math.random() * (n - 0.5))));
					}
					dd.start_date = start_date;
					user.rosterDefs.put(dd.id, dd);
				}
			}
		}

		if (wasEmpty && user.party.length == 0) {
			final Object[] starting_party = WebConfig.instance.starting_party;

			final ArrayList<String> added = new ArrayList<String>();

			for (Object po : starting_party) {
				final String pos = (String) po;
				if (user.rosterDefs.containsKey(pos)) {
					added.add(pos);
				}
			}
			user.party = added.toArray();
		}

		if (wasEmpty && user.renown < WebConfig.instance.starting_renown) {
			user.renown = WebConfig.instance.starting_renown;
			WebConfig.instance.renown.setRenown(user.account_id, user.renown, RenownReason.INIT, "AccountInit.setupUser");
		}

		user.saveRoster(ds);
		user.saveParty(ds);
	}
}
