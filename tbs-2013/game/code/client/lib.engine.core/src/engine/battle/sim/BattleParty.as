package engine.battle.sim
{
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	import engine.battle.board.model.BattlePartyType;
	import engine.battle.board.model.IBattleBoard;
	import engine.battle.board.model.IBattleEntity;
	import engine.math.MathUtil;
	import engine.stat.def.StatType;
	import engine.stat.model.StatEvent;

	public class BattleParty extends EventDispatcher implements IBattleParty
	{
		private var members : Vector.<IBattleEntity> = new Vector.<IBattleEntity>;
		private var _team : String;
		private var _type : BattlePartyType;
		private var _board : IBattleBoard;
		private var _deployed : Boolean;
		private var iterator : int;
		private var _deployment : String;
		private var _isPlayer : Boolean;
		private var _isAlly : Boolean;
		private var _id : String;
		private var _surrendered : Boolean;
		private var _partyName : String;
		private var _aborted : Boolean;
		private var _hornSize : int;
		private var _timer : int;

		private var _trauma : Number = 0;
		private var _initialVitality : Number = 0;
		private var _vitality : Number = 0;

		public function BattleParty(board : IBattleBoard, partyName : String, id : String, team : String, deployment : String, type : BattlePartyType, timer : int, isAlly : Boolean = false)
		{
			this._partyName = partyName;
			this._id = id;
			this._team = team;
			this._deployment = deployment;
			this._board = board;
			this._type = type;
			this._isPlayer = type == BattlePartyType.LOCAL;
			this._timer = timer;
			if (!_isPlayer)
			{
				this._isAlly = _isAlly;
			}
		}

		public function changeDeployment(dp : String) : void
		{
			_deployment = dp;
		}

		public function get partyName() : String
		{
			return _partyName;
		}

		override public function toString() : String
		{
			return team + ", type=" + type;
		}

		public function cleanup() : void
		{
			for each (var m : IBattleEntity in members)
			{
				if (m.party == this)
				{
					m.party = null;
				}
				m.stats.getStat(StatType.STRENGTH).removeEventListener(StatEvent.BASE_CHANGE, statChangeHandler);
				m.stats.getStat(StatType.ARMOR).removeEventListener(StatEvent.BASE_CHANGE, statChangeHandler);
			}

			members = null;
			_board = null;
		}

		public function addMember(m : IBattleEntity) : void
		{
			m.party = this;
			members.push(m);

			m.stats.getStat(StatType.STRENGTH).addEventListener(StatEvent.BASE_CHANGE, statChangeHandler);
			m.stats.getStat(StatType.ARMOR).addEventListener(StatEvent.BASE_CHANGE, statChangeHandler);
		}

		private function statChangeHandler(event : Event) : void
		{
			var v : Number = computeVitality();
			setVitality(v);
		}

		public function randomizeOrder() : void
		{
			for (var i : int = 0; i < members.length; ++i)
			{
				var r : int = MathUtil.randomInt(i, members.length - 1);
				var e : IBattleEntity = members[r];
				// swap
				members[r] = members[i];
				members[i] = e;
			}
		}

		public function resetIterator() : void
		{
			iterator = 0;
		}

		public function next() : IBattleEntity
		{
			if (iterator < members.length)
			{
				return members[iterator++];
			}
			return null;
		}

		public function set deployed(value : Boolean) : void
		{
			if (_deployed == value)
			{
				return;
			}

			if (value)
			{
				for each (var e : IBattleEntity in members)
				{
					if (!e.deploymentReady)
					{
						throw new IllegalOperationError("Cannot deploy -- " + e + " is not ready");
					}
				}
			}

			var v : Number = computeVitality();
			_initialVitality = v;
			_vitality = v;
			_trauma = 0;

			_deployed = value;

			dispatchEvent(new BattlePartyEvent(BattlePartyEvent.DEPLOYED));
		}

		private function setVitality(value : Number) : void
		{
			if (value != _vitality)
			{
				_vitality = value;
				if (_initialVitality)
				{
					_trauma = (_initialVitality - _vitality) / _initialVitality;
					_trauma = Math.min(1, Math.max(0, _trauma));
				}

				//board.logger.info(">>>>> TRAUMA " + id + " vitality=" + _vitality + "/" + _initialVitality + ", trauma=" + _trauma);

				dispatchEvent(new BattlePartyEvent(BattlePartyEvent.TRAUMA));
			}
		}

		private function computeVitality() : Number
		{
			var v : Number = 0;
			for each (var e : IBattleEntity in members)
			{
				if (e.alive)
				{
					var str : int = e.stats.getBase(StatType.STRENGTH);
					var arm : int = e.stats.getBase(StatType.ARMOR);
					v += str + arm * 0.5;
				}
			}

			return v;
		}

		public function get deployed() : Boolean
		{
			return _deployed;
		}

		public function get numMembers() : int
		{
			return members.length;
		}

		public function getMember(index : int) : IBattleEntity
		{
			return members[index];
		}

		public function get board() : IBattleBoard
		{
			return _board;
		}

		public function get team() : String
		{
			return _team;
		}

		public function get type() : BattlePartyType
		{
			return _type;
		}

		public function get deployment() : String
		{
			return _deployment;
		}

		public function get isPlayer() : Boolean
		{
			return _isPlayer;
		}

		public function get isEnemy() : Boolean
		{
			return !_isPlayer && !_isAlly;
		}

		public function get isAlly() : Boolean
		{
			return _isAlly;
		}

		public function get id() : String
		{
			return _id;
		}

		public function get surrendered() : Boolean
		{
			return _surrendered;
		}

		public function set surrendered(value : Boolean) : void
		{
			_surrendered = value;
		}

		public function getAllMembers(all : Vector.<IBattleEntity>) : Vector.<IBattleEntity>
		{
			if (!all)
			{
				all = new Vector.<IBattleEntity>;
			}

			for each (var m : IBattleEntity in members)
			{
				if (m.alive)
				{
					all.push(m);
				}
			}

			return all;
		}

		public function get aborted() : Boolean
		{
			return _aborted;
		}

		public function set aborted(value : Boolean) : void
		{
			_aborted = value;
		}

		public function get hornSize() : int
		{
			return _hornSize;
		}

		public function set hornSize(value : int) : void
		{
			if (_hornSize == value)
			{
				return;
			}

			const old : int = _hornSize;

			_hornSize = value;

			dispatchEvent(new BattlePartyHornEvent(BattlePartyHornEvent.HORN, old));
		}

		public function get timer() : int
		{
			return _timer;
		}

		public function get vitality() : Number
		{
			return _vitality;
		}

		public function get initialVitality() : Number
		{
			return _initialVitality;
		}

		public function get trauma() : Number
		{
			return _trauma;
		}

		public function get numAlive() : int
		{
			var a : int = 0;
			for each (var e : IBattleEntity in members)
			{
				if (e.alive)
				{
					++a;
				}
			}

			return a;
		}

	}
}
