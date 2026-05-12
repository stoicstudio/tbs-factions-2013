package engine.entity.model
{
	import engine.entity.def.IEntityDef;
	import engine.stat.model.Stats;

	import flash.events.EventDispatcher;

	public class Entity extends EventDispatcher implements IEntity
	{
		private static var lastId : int = 0;
		public var _def : IEntityDef;
		private var _stats : Stats;
		private var _fakeStats : Stats;
		private var _id : String;

		public function Entity(def : IEntityDef, id : String)
		{
			this._def = def;
			this._id = makeId(def, id);
			_stats = new Stats(this, false);
		}

		public static function makeId(def : IEntityDef, value : String) : String
		{
			if (value)
			{
				return value;
			}
			else
			{
				return def.id + "_" + (++lastId).toString(16);
			}
		}

		public function get id() : String
		{
			return _id;
		}

		public function get name() : String
		{
			return def.name;
		}

		public function get stats() : Stats
		{
			return _fakeStats ? _fakeStats : _stats;
		}

		public function get def() : IEntityDef
		{
			return _def;
		}

		override public function toString() : String
		{
			return id;
		}

		public function set fake(value : Boolean) : void
		{
			if (value)
			{
				_fakeStats = _stats.clone(this);
			}
			else
			{
				_fakeStats = null;
			}
		}

		final public function get fake() : Boolean
		{
			return _fakeStats != null;
		}

		public function get isPlayer() : Boolean
		{
			return true;
		}

		public function get isEnemy() : Boolean
		{
			return false;
		}

		public function get playerControlled() : Boolean
		{
			return true;
		}

		public function update(deltaMs : int) : void
		{
			// TODO Auto-generated method stub
		}

	}
}
