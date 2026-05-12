package engine.entity.def
{
	import flash.events.Event;
	import flash.events.EventDispatcher;

	import engine.core.locale.Locale;
	import engine.core.logging.ILogger;
	import engine.stat.def.StatPurchaseInfo;
	import engine.stat.def.StatType;

	import tbs.srv.util.UnitAddData;

	public class Legend extends EventDispatcher
	{
		public static const ROSTERROWS : String = "Legend.ROSTERROWS";
		public static const ROSTER_ADD : String = "Legend.ROSTER_ADD";
		public static const RENOWN : String = "Legend.RENOWN";

		private var _renown : int;
		protected var _roster : IEntityListDef;
		protected var _party : IPartyDef = null;
		protected var _rosterRowCount : int = 1;

		public var rosterSlotsPerRow : int;

		private var logger : ILogger;

		function Legend(rosterSlotsPerRow : int, logger : ILogger, locale : Locale, classes : EntityClassDefList)
		{
			_roster = new EntityListDef(locale, classes);
			_roster.classes
			this.rosterSlotsPerRow = rosterSlotsPerRow;
			this.logger = logger;
			_party = new PartyDef(_roster);
		}

		public function dismissEntity(entity : IEntityDef) : void
		{
			_party.removeMember(entity.id);
			_roster.removeEntityDef(entity);
		}

		public function get rosterSlotAvailable() : Boolean
		{
			return _roster.numEntityDefs < rosterSlotCount;
		}

		public function get rosterRowCount() : int
		{
			return _rosterRowCount;
		}

		public function set rosterRowCount(value : int) : void
		{
			if (value == _rosterRowCount)
			{
				return;
			}

			_rosterRowCount = value;
			dispatchEvent(new Event(ROSTERROWS));
		}

		public function get rosterSlotCount() : int
		{
			return rosterSlotsPerRow * _rosterRowCount;
		}

		public function unlockRosterRow(callback : Function) : Boolean
		{
			++_rosterRowCount;
			callback(null);
			return true;
		}

		public function get roster() : IEntityListDef
		{
			return _roster;
		}

		public function get party() : IPartyDef
		{
			return _party;
		}

		public function set roster(value : IEntityListDef) : void
		{
			_roster = value;
			_roster.sort();
			_party = new PartyDef(_roster);
		}

		public function set party(party : IPartyDef) : void
		{
			if (party.roster != _roster)
			{
				throw new ArgumentError("invalide roster");
			}

			_party = party;

			for each (var pid : String in(_party as PartyDef).memberIds)
			{
				if (!roster.getEntityDefById(pid))
				{
					logger.error("Error Loading Account party character def: " + pid);
				}
			}
		}

		public function hireRosterUnit(pu : IPurchasableUnit, fake : Boolean, callback : Function) : void
		{

		}

		public function handleUnitAdd(data : UnitAddData) : void
		{

		}

		public function purchaseStat(id : String, type : StatType, delta : int) : void
		{

		}

		public function purchaseStats(id : String, stats : Vector.<StatPurchaseInfo>) : void
		{

		}

		public function rename(id : String, name : String) : void
		{

		}

		public function promote(id : String, classId : String, name : String, callback : Function) : void
		{

		}

		public function get renown() : int
		{
			return _renown;
		}

		public function set renown(value : int) : void
		{
			if (_renown != value)
			{
				_renown = value;
				dispatchEvent(new Event(RENOWN));
			}
		}

		public function purchaseVariation(entity : IEntityDef, variationIndex : int) : void
		{

		}
	}
}
