package engine.battle.ability.effect.model
{
	import engine.core.util.Enum;

	public class EffectTag extends Enum
	{
		public static const DAMAGED_ARM : EffectTag = new EffectTag("DAMAGED_ARM", enumCtorKey);
		public static const DAMAGED_STR : EffectTag = new EffectTag("DAMAGED_STR", enumCtorKey);
		public static const NEGATIVE : EffectTag = new EffectTag("NEGATIVE", enumCtorKey);
		public static const KILLING : EffectTag = new EffectTag("KILLING", enumCtorKey);
		public static const RESISTING : EffectTag = new EffectTag("RESISTING", enumCtorKey);
		public static const NO_FAKING : EffectTag = new EffectTag("NO_FAKING", enumCtorKey);
		public static const TEMPEST : EffectTag = new EffectTag("TEMPEST", enumCtorKey);
		public static const POSSESSED_MOVE : EffectTag = new EffectTag("POSSESSED_MOVE", enumCtorKey);
		public static const NO_RETALIATE : EffectTag = new EffectTag("NO_RETALIATE", enumCtorKey);
		public static const MOVED_THIS_TURN : EffectTag = new EffectTag("MOVED_THIS_TURN", enumCtorKey);
		public static const SPECIAL_SUNDERINGIMPACT_ACTIVE : EffectTag = new EffectTag("SPECIAL_SUNDERINGIMPACT_ACTIVE", enumCtorKey);
		public static const SPECIAL_BRINGTHEPAIN_ACTIVE : EffectTag = new EffectTag("SPECIAL_BRINGTHEPAIN_ACTIVE", enumCtorKey);
		public static const SPECIAL_PUNCTURE_BONUS : EffectTag = new EffectTag("SPECIAL_PUNCTURE_BONUS", enumCtorKey);

		public static const FLAMMABLE : EffectTag = new EffectTag("FLAMMABLE", enumCtorKey);
		public static const ONFIRE : EffectTag = new EffectTag("ONFIRE", enumCtorKey);

		public static const MALICE_RESPONSE : EffectTag = new EffectTag("MALICE_RESPONSE", enumCtorKey);

		public function EffectTag(name : String, key : Object)
		{
			super(name, key);
		}
	}
}
