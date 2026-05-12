package tbs.srv.data;

import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON.Output;

public class LobbyPartyData extends LobbyData {

	public Object[] party;

	public LobbyPartyData() {
		super.type = Type.PARTY.name();
	}

	public LobbyPartyData(final long lobby_id, final long account_id, final Object[] party, final Type type) {
		super(lobby_id, account_id, null, type);
		this.party = party;
	}

	public String toString() {
		return super.toString();
	}

	@Override
	public void toJSON(Output out) {
		super.toJSON(out);
		out.add("party", party);
	}

	@Override
	public void fromJSON(@SuppressWarnings("rawtypes") Map jo) {
		super.fromJSON(jo);
		party = (Object[]) jo.get("party");
	}
}