package engine.ability.def
{
	import engine.ability.IAbilityDef;
	import engine.core.locale.Localizer;
	import engine.stat.model.Stats;

	public class AbilityDef implements IAbilityDef
	{
		private var _id : String;
		private var _displayDamageUI : Boolean = false;
		private var _name : String;
		private var _description : String;
		protected var _descriptionBrief : String;
		private var _provingGroundsDescription : String;
		private var _root : AbilityDef;
		private var _level : int;
		protected var _iconUrl : String;
		protected var _iconLargeUrl : String;
		protected var _iconBuffUrl : String;
		protected var _costs : Stats = new Stats(null, true);
		protected var _horn : int = 0;
		protected var _optionalStars : int = 0;

		protected var levels : Vector.<AbilityDef> = new Vector.<AbilityDef>;

		public function AbilityDef(root : AbilityDef = null)
		{
			if (!root)
			{
				root = this;
			}

			this._root = root;
		}

		public function get displayDamageUI() : Boolean
		{
			return _displayDamageUI;
		}

		public function set displayDamageUI(value : Boolean) : void
		{
			_displayDamageUI = value;
		}

		public function get provingGroundsDescription() : String
		{
			return _provingGroundsDescription;
		}

		protected function setId(id : String, localizer : Localizer, abl_rank : int) : void
		{
			_id = id;

			_name = localizer.translate(this.id);
			_description = localizer.translate(this.id + "_description_rank_" + abl_rank);
			_descriptionBrief = localizer.translate(this.id + "_description_brief");
			_provingGroundsDescription = localizer.translate(this.id + "_proving_grounds_description");

		}

		public function get level() : int
		{
			return _level;
		}

		public function set level(value : int) : void
		{
			_level = value;
		}

		final public function get maxLevel() : int
		{
			if (root != this)
			{
				return root.maxLevel;
			}
			return levels.length;
		}

		public function toString() : String
		{
			return id;
		}

		public function addLevel(ad : AbilityDef) : void
		{
			levels.push(ad);
			ad.level = levels.length;
		}

		public function link(factory : AbilityDefFactory) : void
		{

		}

		public function get id() : String
		{
			return _id;
		}

		public function get name() : String
		{
			return _name;
		}

		public function get description() : String
		{
			return _description;
		}

		public function get descriptionBrief() : String
		{
			return _descriptionBrief;
		}

		public function get root() : IAbilityDef
		{
			return _root;
		}

		public function get iconUrl() : String
		{
			return _iconUrl;
		}

		public function get iconLargeUrl() : String
		{
			return _iconLargeUrl;
		}

		/**
		 * Levels everywhere to are referred as one-based.
		 * @param level
		 * @return
		 *
		 */

		public function getAbilityDefForLevel(level : int) : IAbilityDef
		{
			if (root != this)
			{
				return root.getAbilityDefForLevel(level);
			}
			if ((level - 1) >= levels.length || level <= 0)
			{
				throw new ArgumentError("invalid ability level " + level + " for " + id + ". Must be in [1," + maxLevel + "]");
			}
			return levels[level - 1];
		}

		public function get costs() : Stats
		{
			return _costs;
		}

		public function get horn() : int
		{
			return _horn;
		}

		public function get iconBuffUrl() : String
		{
			return _iconBuffUrl;
		}

		public function get optionalStars() : int
		{
			return _optionalStars;
		}

	}
}
