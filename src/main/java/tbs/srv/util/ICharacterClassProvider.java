package tbs.srv.util;

import tbs.srv.data.CharacterClassDef;

public interface ICharacterClassProvider {
	public CharacterClassDef getCharacterClassDef(final String id);
}
