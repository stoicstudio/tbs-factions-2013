package tbs.srv.data;

import java.util.Calendar;
import java.util.Map;

import org.apache.log4j.Logger;
import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

import tbs.srv.util.GameConfig;

public class TourneyDef implements Convertible {

	private static final Logger logger = Logger.getLogger(Logger.class.getSimpleName());

	public String name;
	public int start_day;
	public long start_time_of_day;
	public long end_time_of_day;
	public int days;
	public long duration;
	public int[] rewards;
	public int entry_fee;
	public int daily_limit;
	public String parent;
	public boolean meta;
	public int power_requirement;
	public boolean enabled = true;

	private static final String[] weekdays = java.text.DateFormatSymbols.getInstance().getShortWeekdays();

	public String toString() {
		return "TourneyDef [" + name + "]";
	}

	public TourneyDef() {

	}

	public TourneyDef(final TourneyDef rhs) {
		copy(rhs);
	}

	public TourneyDef copy(final TourneyDef rhs) {
		this.name = rhs.name;
		this.start_day = rhs.start_day;
		this.start_time_of_day = rhs.start_time_of_day;
		this.end_time_of_day = rhs.end_time_of_day;
		this.days = rhs.days;
		this.duration = rhs.duration;
		this.rewards = new int[rhs.rewards.length];
		System.arraycopy(rhs.rewards, 0, this.rewards, 0, rhs.rewards.length);
		this.entry_fee = rhs.entry_fee;
		this.daily_limit = rhs.daily_limit;
		this.parent = rhs.parent;
		this.meta = rhs.meta;
		this.power_requirement = rhs.power_requirement;
		this.enabled = rhs.enabled;
		return this;
	}

	public TourneyDef(Map<String, Object> data) {

		name = (String) data.get("name");
		parent = (String) data.get("parent");

		start_day = parseShortWeekday((String) data.get("start_day"));
		start_time_of_day = ((Number) data.get("start_time_of_day")).intValue();
		end_time_of_day = ((Number) data.get("end_time_of_day")).intValue();

		// comes in in hour/minute format, e.g. 1845 hours
		start_time_of_day = convertHourMinute(start_time_of_day);
		end_time_of_day = convertHourMinute(end_time_of_day);

		days = ((Number) data.get("days")).intValue();
		{
			final long DAY_MS = 24 * 60 * 60 * 1000;
			duration = days * DAY_MS - start_time_of_day + end_time_of_day;
		}

		{
			final Boolean mb = (Boolean) data.get("meta");
			meta = mb != null ? mb.booleanValue() : false;
		}

		{
			Object[] rv = (Object[]) data.get("rewards");
			rewards = new int[rv.length];
			for (int i = 0; i < rv.length; ++i) {
				final int r = ((Number) rv[i]).intValue();
				rewards[i] = r;
			}
		}

		entry_fee = ((Number) data.get("entry_fee")).intValue();
		daily_limit = ((Number) data.get("daily_limit")).intValue();

		{
			final Boolean eb = (Boolean) data.get("enabled");
			enabled = eb != null ? eb.booleanValue() : enabled;
		}

		{
			final Number prn = (Number) data.get("power_requirement");
			power_requirement = prn != null ? prn.intValue() : power_requirement;
		}

	}

	private static long convertHourMinute(final long hm) {
		final int start_hour = (int) (hm / 100);
		final int start_minute = (int) hm - start_hour * 100;
		return (start_hour * 60 + start_minute) * 60 * 1000;
	}

	private int parseShortWeekday(String s) {
		if (s == null || s.isEmpty()) {
			return -1;
		}
		for (int i = 0; i < weekdays.length; ++i) {
			if (weekdays[i].equals(s)) {
				return i;
			}
		}

		throw new IllegalArgumentException("invalid weekday " + s);
	}

	public long getStartTime() {
		if (start_day > 0) {
			final Calendar cal = Calendar.getInstance();
			final int day = cal.get(Calendar.DAY_OF_WEEK);

			cal.set(Calendar.HOUR_OF_DAY, 0);
			cal.set(Calendar.MINUTE, 0);
			cal.set(Calendar.SECOND, 0);
			cal.set(Calendar.MILLISECOND, 0);
			cal.add(Calendar.MILLISECOND, (int) start_time_of_day);

			int delta_day = 0;
			if (day < start_day) {
				delta_day = start_day - day;
			} else if (day > start_day) {
				delta_day = start_day + 7 - day;
			} else if (day == start_day) {
				// should have already started, so starts next week
				if (cal.getTimeInMillis() < System.currentTimeMillis()) {
					delta_day += 7;
				}
			}

			logger.info("getStartTime delta_day=" + delta_day);
			cal.add(Calendar.DATE, delta_day);

			return cal.getTimeInMillis();

		}
		return -1;
	}

	@Override
	public void toJSON(Output out) {
		out.addClass(TourneyDef.class);

		out.add("name", name);
		out.add("rewards", rewards);
		out.add("entry_fee", entry_fee);
		out.add("daily_limit", daily_limit);
		out.add("power_requirement", power_requirement);
	}

	@SuppressWarnings("rawtypes")
	@Override
	public void fromJSON(Map object) {

		name = (String) object.get("name");

		final TourneyDef rhs = GameConfig.instance.tourney_defs.find(name);
		copy(rhs);

		final Object[] rr = (Object[]) object.get("rewards");

		rewards = new int[rr.length];
		for (int i = 0; i < rr.length; ++i) {
			rewards[i] = ((Number) rr[i]).intValue();
		}

		entry_fee = ((Number) object.get("entry_fee")).intValue();
		daily_limit = ((Number) object.get("daily_limit")).intValue();
		power_requirement = ((Number) object.get("power_requirement")).intValue();
	}
}