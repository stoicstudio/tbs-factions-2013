package engine.entity.def
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	import engine.core.logging.ILogger;

	public class EntityClassDefList extends EventDispatcher
	{
		private var _entityClasses : Dictionary = new Dictionary;
		private var skus : Dictionary = new Dictionary;
		public var meta : EntitiesMetadata;
		public var ok : Boolean = true;
		public var url : String;
		public var type : String;
		public var parentUrl : String;

		public var parent : EntityClassDefList;

		public function EntityClassDefList()
		{

		}

//		public function clone(logger : ILogger) : EntityClassDefList
//		{
//			var c : EntityClassDefList = new EntityClassDefList;
//			for (var sku : String in skus)
//			{
//				throw new IllegalOperationError("Don't clone merged");
//			}
//
//			c.meta = meta;
//			for each (var e : EntityClassDef in _entityClasses)
//			{
//				c.register(e, logger);
//			}
//
//			return c;
//		}

		public function fetch(id : String) : EntityClassDef
		{
			var e : EntityClassDef = _entityClasses[id];
			if (e)
			{
				return e;
			}

			return parent ? parent.fetch(id) : null;
		}

		public function get entityClasses() : Dictionary
		{
			return _entityClasses;
		}

		public function registerAll(rhs : EntityClassDefList, logger : ILogger) : void
		{
			if (!meta)
			{
				meta = rhs.meta;
			}

			for each (var ecd : EntityClassDef in rhs.entityClasses)
			{
				register(ecd, logger);
			}
		}

//
//		public function replaceMeta(rhs : EntitiesMetadata) : void
//		{
//			for each (var ecd : EntityClassDef in _entityClasses)
//			{
//				ecd.meta = rhs;
//			}
//		}

		public function register(entityClass : EntityClassDef, logger : ILogger) : void
		{
			if (entityClass.id in _entityClasses)
			{
				logger.info("EntityClassDefManager.register overrideing " + entityClass.id);
			}
			_entityClasses[entityClass.id] = entityClass;
		}

		public function unregister(entityClass : EntityClassDef) : void
		{
			delete _entityClasses[entityClass.id];
		}

		internal function init() : void
		{
			var ecd : EntityClassDef;

			for each (ecd in _entityClasses)
			{
				ecd.purge();
			}

			for each (ecd in _entityClasses)
			{
				ecd.link(this);
			}
		}

//		public function mergeSku(sku : String, rhs : EntityClassDefList, logger : ILogger) : void
//		{
//			//	purgeSku(sku);
//
//			if (!rhs)
//			{
//				return;
//			}
//
//			skus[sku] = rhs;
//			registerAll(rhs, logger);
//			this.meta = rhs.meta;
//			//replaceMeta(rhs.meta);
//		}

		public function removeEntityClass(id : String) : void
		{
			delete _entityClasses[id];
		}

		public function setClassId(clazz : EntityClassDef, id : String) : void
		{
			if (fetch(id))
			{
				// already using id
				return;
			}

			delete _entityClasses[clazz.id];
			clazz.id = id;
			_entityClasses[clazz.id] = clazz;
			dispatchEvent(new Event(Event.CHANGE));
		}
	}
}
