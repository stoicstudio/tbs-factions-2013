package engine.battle.board.model
{
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import engine.battle.BattleAssetsDef;
	import engine.battle.ability.def.BattleAbilityDef;
	import engine.battle.ability.def.BattleAbilityDefFactory;
	import engine.battle.ability.effect.model.BattleFacing;
	import engine.battle.ability.model.BattleAbilityEvent;
	import engine.battle.ability.model.BattleAbilityManager;
	import engine.battle.ability.phantasm.model.VfxSequence;
	import engine.battle.board.BattleBoardEvent;
	import engine.battle.board.BattleRectangleUtils;
	import engine.battle.board.def.BattleBoardDef;
	import engine.battle.board.def.BattleBoardTriggerDef;
	import engine.battle.board.def.BattleBoardTriggerSpawner;
	import engine.battle.board.def.BattleDeploymentArea;
	import engine.battle.board.def.BattleSpawnerDef;
	import engine.battle.board.view.underlay.DeploymentUnderlay;
	import engine.battle.entity.model.BattleEntity;
	import engine.battle.entity.model.BattleEntityEvent;
	import engine.battle.entity.model.BattleEntityFactory;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.sim.BattleParty;
	import engine.battle.sim.BattleSim;
	import engine.battle.sim.IBattleParty;
	import engine.core.logging.ILogger;
	import engine.entity.def.EntityDef;
	import engine.entity.def.IEntityClassDef;
	import engine.entity.def.IEntityDef;
	import engine.entity.def.IEntityListDef;
	import engine.math.Hash;
	import engine.math.MathUtil;
	import engine.resource.ResourceManager;
	import engine.saga.Saga;
	import engine.saga.SagaBucket;
	import engine.scene.model.Scene;
	import engine.sound.ISoundDriver;
	import engine.stat.def.StatType;
	import engine.stat.model.Stat;
	import engine.tile.Tile;
	import engine.tile.Tiles;
	import engine.tile.def.TileLocation;
	import engine.tile.def.TileLocationArea;
	import engine.tile.def.TileRect;
	import engine.vfx.VfxLibrary;

	public class BattleBoard extends EventDispatcher implements IBattleBoard
	{
		private var _def : BattleBoardDef;
		private var _entities : Dictionary = new Dictionary;
		private var _tiles : BattleBoardTiles;
		private var _sim : BattleSim;
		private var _logger : ILogger;
		public var abilityFactory : BattleAbilityDefFactory;
		public var _resman : ResourceManager;
		public var assets : BattleAssetsDef;
		public var phantasms : BattleBoardPhantasms;
		public var _triggers : BattleBoardTriggers;
		private var _abilityManager : BattleAbilityManager;
		private var _enabled : Boolean;
		private var soundDriver : ISoundDriver;
		private var _selectedTile : Tile;
		private var partiesById : Dictionary = new Dictionary;
		public var parties : Vector.<IBattleParty> = new Vector.<IBattleParty>;
		public var scene : Scene;
		public var vfxs : Vector.<VfxSequence> = new Vector.<VfxSequence>;

		public var bucket : String;
		public var bucket_quota : int;
		private var _spawn_tags : String;
		public var spawn_tags_dict : Dictionary;
		public var bucket_deployment : String;

		// library of vfx that is board specific -- TODO load from def
		public var vfxLibrary : VfxLibrary;

		private var _fake : Boolean;
		private var _boardSetup : Boolean;

		private var _deathOffset : Number = 0;

		public function BattleBoard(def : BattleBoardDef, scene : Scene, logger : ILogger, resman : ResourceManager, abilityFactory : BattleAbilityDefFactory, assets : BattleAssetsDef, soundDriver : ISoundDriver)
		{
			this.def = def;
			this.scene = scene;
			this._logger = logger;
			this.abilityFactory = abilityFactory;
			this._resman = resman;
			this.assets = assets;
			this._abilityManager = new BattleAbilityManager(logger, abilityFactory);
			this.soundDriver = soundDriver;
			_tiles = new BattleBoardTiles(this);
			phantasms = new BattleBoardPhantasms(this);
			_triggers = new BattleBoardTriggers(this);

			_deathOffset = -6.0;

			triggers.addEventListener(BattleBoardTriggersEvent.ADDED, triggersAddedHandler);
			triggers.addEventListener(BattleBoardTriggersEvent.REMOVED, triggersRemovedHandler);

			_abilityManager.addEventListener(BattleAbilityEvent.INCOMPLETES_EMPTY, incompletesEmptyHandler, false, 255);
		}

		private function incompletesEmptyHandler(event : BattleAbilityEvent) : void
		{
			expireDeadEntitiesEffects();
		}

		public function get selectedTile() : Tile
		{
			return _selectedTile;
		}

		public function set selectedTile(value : Tile) : void
		{
			if (_selectedTile == value)
			{
				return;
			}

			_selectedTile = value;
			dispatchEvent(new BattleBoardEvent(BattleBoardEvent.SELECT_TILE));
		}

		public function get deathOffset() : Number
		{
			return _deathOffset;
		}

		public function set deathOffset(value : Number) : void
		{
			_deathOffset = value;
		}

		public function cleanup() : void
		{
			_abilityManager.removeEventListener(BattleAbilityEvent.INCOMPLETES_EMPTY, incompletesEmptyHandler);

			triggers.removeEventListener(BattleBoardTriggersEvent.ADDED, triggersAddedHandler);
			triggers.removeEventListener(BattleBoardTriggersEvent.REMOVED, triggersRemovedHandler);

			for each (var p : BattleParty in parties)
			{
				p.cleanup();
			}

			for each (var e : BattleEntity in entities)
			{
				e.cleanup();
			}

			_abilityManager.cleanup();
			_abilityManager = null;

			_tiles.cleanup();
			_tiles = null;
			_sim.cleanup();
			_sim = null;

			phantasms.cleanup();
			phantasms = null;

			_entities = null;
			parties = null;
		}

		override public function toString() : String
		{
			return def.id;
		}

		public function get sim() : BattleSim
		{
			return _sim;
		}

		public function set sim(value : BattleSim) : void
		{
			_sim = value;

			if (_sim)
			{
				if (_sim.fsm.battleId)
				{
					_abilityManager.seedRng = Hash.DJBHash(_sim.fsm.battleId);
				}
				else
				{
					_abilityManager.seedRng = getTimer();
				}
			}
		}

		private function addEntity(entity : BattleEntity) : void
		{
			if (_fake)
			{
				return;
			}
			entities[entity.id] = entity;

			entity.addEventListener(BattleEntityEvent.DAMAGED, entityDamagedHandler);
			entity.addEventListener(BattleEntityEvent.KILLING_EFFECT, entityKillingEffectHandler);
			entity.addEventListener(BattleEntityEvent.ALIVE, entityAliveHandler);
			dispatchEvent(new BattleEntityEvent(BattleEntityEvent.ADDED, entity));
		}

		private function entityDamagedHandler(event : BattleEntityEvent) : void
		{
			dispatchEvent(new BattleBoardEvent(BattleBoardEvent.BOARD_ENTITY_DAMAGED, event.entity));
		}

		private function entityAliveHandler(event : BattleEntityEvent) : void
		{
			dispatchEvent(new BattleBoardEvent(BattleBoardEvent.BOARD_ENTITY_ALIVE, event.entity));
		}

		private function entityKillingEffectHandler(event : BattleEntityEvent) : void
		{
			dispatchEvent(new BattleBoardEvent(BattleBoardEvent.BOARD_ENTITY_KILLING_EFFECT, event.entity));
		}

		public function removeEntity(entity : BattleEntity) : void
		{
			if (_fake)
			{
				return;
			}

			entity.removeEventListener(BattleEntityEvent.DAMAGED, entityDamagedHandler);
			entity.removeEventListener(BattleEntityEvent.ALIVE, entityAliveHandler);
			entity.removeEventListener(BattleEntityEvent.KILLING_EFFECT, entityKillingEffectHandler);

			delete entities[entity.id];
			dispatchEvent(new BattleEntityEvent(BattleEntityEvent.REMOVED, entity));
		}

		public function createEntity(def : IEntityDef, id : String, x : Number, y : Number, party : IBattleParty) : BattleEntity
		{
			if (_fake)
			{
				return null;
			}

			var e : BattleEntity = BattleEntityFactory.create(this, id, def, party, soundDriver, logger);
			e.setPos(x, y);
			addEntity(e);
			return e;
		}

		/**
		 * Return the bits that intersect.  Test rects larger than area 32 are not supported.
		 * @param
		 * @param Number
		 * @param y
		 * @param w
		 * @param h
		 * @return
		 *
		 */
		public function checkAllRectIntersections(x : Number, y : Number, w : Number, l : Number, ignore : IBattleEntity) : uint
		{
			var result : uint = 0;

			for each (var e : BattleEntity in entities)
			{
				if (e == ignore)
				{
					continue;
				}
				var bits : uint = find2RectIntersections(
					x, y, w, l,
					e.x, e.y, e.def.entityClass.bounds.width, e.def.entityClass.bounds.length);

				result |= bits;
			}

			return bits;
		}

		public function findAllRectIntersectionEntities(x : Number, y : Number, w : Number, l : Number, ignore : IBattleEntity, results : Vector.<IBattleEntity>) : Boolean
		{
			for each (var e : BattleEntity in entities)
			{
				if (e == ignore)
				{
					continue;
				}

				var hit : Boolean = BattleRectangleUtils.test2RectIntersection(
					x, y, w, l,
					e.x, e.y, e.def.entityClass.bounds.width, e.def.entityClass.bounds.length);

				if (hit)
				{
					if (results)
					{
						results.push(e);
					}
					else
					{
						return true;
					}
				}
			}

			return results && results.length > 0;
		}

		public function findAllAdjacentEntities(sourceEntity : IBattleEntity, results : Vector.<IBattleEntity>) : void
		{
			const x : int = sourceEntity.tile.x;
			const y : int = sourceEntity.tile.y;
			var adjacentEntity : BattleEntity;

			if (sourceEntity.rect.width == 1)
			{
				adjacentEntity = findEntityOnTile(x, y - 1, true, null) as BattleEntity;
				if (adjacentEntity != null && results.indexOf(adjacentEntity) == -1)
				{
					results.push(adjacentEntity);
				}

				adjacentEntity = findEntityOnTile(x + 1, y, true, null) as BattleEntity;
				if (adjacentEntity != null && results.indexOf(adjacentEntity) == -1)
				{
					results.push(adjacentEntity);
				}

				adjacentEntity = findEntityOnTile(x, y + 1, true, null) as BattleEntity;
				if (adjacentEntity != null && results.indexOf(adjacentEntity) == -1)
				{
					results.push(adjacentEntity);
				}

				adjacentEntity = findEntityOnTile(x - 1, y, true, null) as BattleEntity;
				if (adjacentEntity != null && results.indexOf(adjacentEntity) == -1)
				{
					results.push(adjacentEntity);
				}
			}
			else if (sourceEntity.rect.width == 2)
			{
				adjacentEntity = findEntityOnTile(x, y - 1, true, null) as BattleEntity;
				if (adjacentEntity != null && results.indexOf(adjacentEntity) == -1)
				{
					results.push(adjacentEntity);
				}

				adjacentEntity = findEntityOnTile(x + 1, y - 1, true, null) as BattleEntity;
				if (adjacentEntity != null && results.indexOf(adjacentEntity) == -1)
				{
					results.push(adjacentEntity);
				}

				adjacentEntity = findEntityOnTile(x + 2, y, true, null) as BattleEntity;
				if (adjacentEntity != null && results.indexOf(adjacentEntity) == -1)
				{
					results.push(adjacentEntity);
				}

				adjacentEntity = findEntityOnTile(x + 2, y + 1, true, null) as BattleEntity;
				if (adjacentEntity != null && results.indexOf(adjacentEntity) == -1)
				{
					results.push(adjacentEntity);
				}

				adjacentEntity = findEntityOnTile(x, y + 2, true, null) as BattleEntity;
				if (adjacentEntity != null && results.indexOf(adjacentEntity) == -1)
				{
					results.push(adjacentEntity);
				}

				adjacentEntity = findEntityOnTile(x + 1, y + 2, true, null) as BattleEntity;
				if (adjacentEntity != null && results.indexOf(adjacentEntity) == -1)
				{
					results.push(adjacentEntity);
				}

				adjacentEntity = findEntityOnTile(x - 1, y + 1, true, null) as BattleEntity;
				if (adjacentEntity != null && results.indexOf(adjacentEntity) == -1)
				{
					results.push(adjacentEntity);
				}

				adjacentEntity = findEntityOnTile(x - 1, y, true, null) as BattleEntity;
				if (adjacentEntity != null && results.indexOf(adjacentEntity) == -1)
				{
					results.push(adjacentEntity);
				}
			}
		}

		public function findEntityOnTile(x : Number, y : Number, aliveOnly : Boolean, ignore : *) : IBattleEntity
		{
			for each (var e : BattleEntity in entities)
			{
				if (e == ignore)
				{
					continue;
				}

				if (aliveOnly && !e.alive)
				{
					continue;
				}

				if (BattleRectangleUtils.testPointInRect(x + 0.5, y + 0.5, e.x, e.y, e.def.entityClass.bounds.width, e.def.entityClass.bounds.length))
				{
					return e;
				}
			}
			return null;
		}

		/**
		 *
		 * @param x0
		 * @param y0
		 * @param w0
		 * @param h0
		 * @param x1
		 * @param y1
		 * @param w1
		 * @param h1
		 * @return the intersected bits in the space of rect0
		 *
		 */
		public function find2RectIntersections(
			x0 : Number, y0 : Number, w0 : Number, l0 : Number,
			x1 : Number, y1 : Number, w1 : Number, l1 : Number
			) : uint
		{
			if (x0 >= (x1 + w1) ||
				(x0 + w0) <= x1 ||
				y0 >= (y1 + l1) ||
				(y0 + l0) <= y1)
			{
				return 0;
			}

			// TODO
			return 1;
		}

		public function get enabled() : Boolean
		{
			return _enabled;
		}

		public function set enabled(value : Boolean) : void
		{
			if (_enabled != value)
			{
				_enabled = value;

				if (_enabled)
				{
					spawn(bucket_deployment, null);
					addBoardTriggers();
				}

				dispatchEvent(new BattleBoardEvent(BattleBoardEvent.ENABLED));
			}
		}

		public function createLocalParty(partyName : String ,id : String, team : String, deployment : String, timer : int) : void
		{
			createParty(partyName, id, team, deployment, BattlePartyType.LOCAL, timer, true);
		}
		
		private function createParty(partyName : String, id : String, team : String, deployment : String, partyType : BattlePartyType, timer : int, isAlly : Boolean) : BattleParty
		{
			var tv : BattleParty = partiesById[id];
			if (!tv)
			{
				tv = new BattleParty(this, partyName, id, team, deployment, partyType, timer, isAlly);
				partiesById[id] = tv;
				parties.push(tv);

				dispatchEvent(new BattleBoardEvent(BattleBoardEvent.PARTY));
			}
			else
			{
				if (partyType != tv.type)
				{
					throw new ArgumentError("Bad party type");
				}

				if (isAlly && !tv.isAlly)
				{
					throw new ArgumentError("Bad enemy bool");
				}
			}

			return tv;
		}

		public function addPartyMember(
			partyName : String,
			id : String,
			partyId : String,
			team : String,
			deployment : String,
			def : IEntityDef,
			partyType : BattlePartyType,
			timer : int,
			isAlly : Boolean) : BattleEntity
		{
			var party : BattleParty = createParty(partyName, partyId, team, deployment, partyType, timer, isAlly);
			if (!id)
			{
				id = team + "+" + party.numMembers + "+" + def.id;
			}
			var m : BattleEntity = createEntity(def, id, -1, -1, party);
			m.enabled = false;

			party.addMember(m);

			var deploymentFacing : BattleFacing = this.def.getDeploymentFacing(deployment);
			m.facing = deploymentFacing;

			return m;
		}

		public function addRemoteParty(partyName : String, partyId : String, team : String, deployment : String, party : IEntityListDef, timer : int, isAlly : Boolean) : void
		{
			for (var i : int = 0; i < party.numEntityDefs; ++i)
			{
				var def : IEntityDef = party.getEntityDef(i);
				if (!def)
				{
					throw new IllegalOperationError("Found null def for party member " + i + ", party=" + party);
				}

				addPartyMember(partyName, null, partyId, team, deployment, def, BattlePartyType.REMOTE, timer, isAlly);
			}
		}

		public var shouldSpawnAi : Boolean = true;

		private function spawnerTagsOk(bsd : BattleSpawnerDef, bucket_spawner_tag : String) : Boolean
		{
			if (spawn_tags_dict && bsd.tags)
			{
				// tagged spawners only
				if (!(bsd.tags in spawn_tags_dict))
				{
					if (bsd.tags != bucket_spawner_tag)
					{
						return false;
					}
				}
			}

			if (bucket_spawner_tag && bsd.tags != bucket_spawner_tag)
			{
				return false;
			}

			return true;
		}

		public var spawner2Entity : Dictionary = new Dictionary;

		private function spawnEntity(bsd : BattleSpawnerDef, cd : IEntityDef) : int
		{
			if (!cd)
			{
				return 0;
			}

			var e : BattleEntity = null;
			if (bsd.prop == true)
			{
				e = createEntity(cd, bsd.team + "+" + cd.id, -1, -1, null);
			}
			else
			{
				// for now, all AIs are enemies.  In future, they may be allies as well
				e = addPartyMember(bsd.team, null, bsd.team, bsd.team, null, cd, BattlePartyType.AI, 0, bsd.isAlly);
			}

			if (e)
			{

				var rank : int = e.stats.getValue(StatType.RANK);
				e.enabled = true;
				e.setPos(bsd.location.x, bsd.location.y);
				e.facing = bsd.facing;

				if (bsd.stats)
				{
					// setup custom stats for the spawner
					for (var i : int = 0; i < bsd.stats.numStats; ++i)
					{
						const stat : Stat = bsd.stats.getStatByIndex(i);
						var old : Stat = e.stats.getStat(stat.type, false);
						if (!old)
						{
							e.stats.addStat(stat.type, stat.base);
						}
						else
						{
							//old.modify(stat.value - old.value);
							old.base = stat.value;
						}
					}
				}

				e.deploymentReady = true;

				return rank;
			}

			return 0;

		}

		public function spawn(bucket_deployment : String, bucket_spawner_tag : String) : void
		{
			var ranks : int = 0;

			for each (var bsd : BattleSpawnerDef in def.spawners)
			{
				if (!shouldSpawnAi && !bsd.prop)
				{
					continue;
				}

				if (!spawnerTagsOk(bsd, bucket_spawner_tag))
				{
					logger.info("BattleBoard.spawn: skipping tagged spawner " + bsd);
					continue;
				}

				var cd : IEntityDef = null;

				if (bsd.character && scene.context.spawnables)
				{
					cd = scene.context.spawnables.getEntityDefById(bsd.character);
					if (!cd)
					{
						logger.error("BattleBoard.spawn: no such entity def: " + bsd.character);
					}
				}
				else if (bsd.entityClassId && scene.context.classes)
				{
					var clazz : IEntityClassDef = scene.context.classes.fetch(bsd.entityClassId);

					if (!clazz)
					{
						logger.error("BattleBoard.spawn: no such class: " + bsd.entityClassId);
						continue;
					}

					var ed : EntityDef = new EntityDef(scene.context.locale);
					ed.entityClass = clazz;
					ed.id = clazz.id;
					ed.setupClassAbilities(scene.context.abilities);
					ed.applyClassStats(1);
					cd = ed;
				}

				ranks += spawnEntity(bsd, cd);

			}

			if (bucket)
			{
				spawnFromBucket(ranks, bucket_deployment);
			}

			for each (var p : BattleParty in parties)
			{
				if (p.type == BattlePartyType.AI)
				{
					p.deployed = true;
				}
			}

			// the NPC and prop parties are now ready
		}

//		private var bucketSpawners : Vector.<BattleSpawnerDef> = new Vector.<BattleSpawnerDef>;
//
//		private function decacheBucketSpanwer(bsd : BattleSpawnerDef) : void
//		{
//			if (spawner2Entity[bsd])
//			{
//				var bi : int = bucketSpawners.indexOf(bsd);
//				if (bi >= 0)
//				{
//					bucketSpawners.splice(bi, 1);
//				}
//			}
//		}
//
//		private function cacheBucketSpawners(bucket_spawner_tag : String) : void
//		{
//			bucketSpawners.splice(0, bucketSpawners.length);
//
//			for each (var bsd : BattleSpawnerDef in def.spawners)
//			{
//				if (bsd.prop)
//				{
//					continue;
//				}
//
//				// TODO tags?
//
//				if (bsd.character || bsd.entityClassId)
//				{
//					continue;
//				}
//
//				if (bsd.tags != bucket_spawner_tag)
//				{
//					continue;
//				}
//
//				bucketSpawners.push(bsd);
//			}
//		}
//
//		private function findFreeBucketSpawner() : BattleSpawnerDef
//		{
//			if (bucketSpawners.length == 0)
//			{
//				return null;
//			}
//			var index : int = MathUtil.randomInt(0, bucketSpawners.length - 1);
//			return bucketSpawners[index];
//
//		}

		private function pickFromBucket(sb : SagaBucket, rank_limit : int) : IEntityDef
		{
			var saga : Saga = scene.context.saga;
			var num_eligible : int = 0;
			var ed : IEntityDef;
			var id : String;

			for each (id in sb.ents)
			{
				ed = saga.def.cast.getEntityDefById(id);
				if (!ed)
				{
					logger.error("Invalid bucket entity [" + id + "]");
					continue;
				}

				if (ed.stats.getValue(StatType.RANK) <= rank_limit)
				{
					++num_eligible;
				}
			}

			if (num_eligible <= 0)
			{
				return null;
			}

			var eligible_index : int = MathUtil.randomInt(0, num_eligible - 1);

			var scan_index : int = 0;
			for each (id in sb.ents)
			{
				ed = saga.def.cast.getEntityDefById(id);
				if (ed && ed.stats.getValue(StatType.RANK) <= rank_limit)
				{
					if (scan_index == eligible_index)
					{
						return ed;
					}

					++scan_index;
				}
			}

			return null;
		}

		private function spawnFromBucket(ranks : int, bucket_deployment : String) : void
		{
			var saga : Saga = scene.context.saga;
			if (!saga)
			{
				return;
			}
			var sb : SagaBucket = saga.def.buckets.getSagaBucket(bucket);
			if (!sb)
			{
				return;
			}
			while (ranks < bucket_quota)
			{
				var index : int = MathUtil.randomInt(0, sb.ents.length - 1);
				var id : String = sb.ents[index];
				var ed : IEntityDef = pickFromBucket(sb, bucket_quota - ranks);

				var ally : Boolean;
				var e : BattleEntity = addPartyMember("npc", null, "npc", "npc", bucket_deployment, ed, BattlePartyType.AI, 0, ally);
				// party may have already existed
				(e.party as BattleParty).changeDeployment(bucket_deployment);

				var r : int = e.stats.getValue(StatType.RANK);
				ranks += r;

					//e.deploymentReady = true;
			}

			autoDeployPartyById("npc");
		}

		protected function addBoardTriggers() : void
		{
			if (def.triggerDefManager == null)
			{
				// triggerDefManager isn't setup in zeno
				return;
			}

			for each (var bbts : BattleBoardTriggerSpawner in def.triggers)
			{
				var tile : Tile = tiles.getTile(bbts.location.x, bbts.location.y);
				if (tile != null)
				{
					var battleBoardTriggerDef : BattleBoardTriggerDef = def.triggerDefManager.getDef(bbts.id);
					if (battleBoardTriggerDef != null)
					{
						var battleAbilityDef : BattleAbilityDef = this.abilityManager.factory.fetchBattleAbilityDef(battleBoardTriggerDef.ability);

						if (battleAbilityDef != null)
						{
							tiles.addAbilityBasedTrigger(tile.rect, battleAbilityDef, battleBoardTriggerDef.pulse);
						}

					}
				}
			}
		}

		public function get numParties() : int
		{
			return parties.length;
		}

		public function getParty(index : int) : IBattleParty
		{
			return parties[index];
		}

		public function getPartyById(id : String) : IBattleParty
		{
			return partiesById[id];
		}

		public function getPartyIndex(party : IBattleParty) : int
		{
			return parties.indexOf(party);
		}

		public function get entities() : Dictionary
		{
			return _entities;
		}

		public function get logger() : ILogger
		{
			return _logger;
		}

		public function get tiles() : Tiles
		{
			return _tiles;
		}

		public function get triggers() : IBattleBoardTriggers
		{
			return _triggers;
		}

		public function getEntity(id : String) : IBattleEntity
		{
			return _entities[id];
		}

		public function get abilityManager() : BattleAbilityManager
		{
			return _abilityManager;
		}

		public function autoDeployPartyById(id : String) : void
		{
			var party : IBattleParty = getPartyById(id);
			var area : BattleDeploymentArea = def.getDeploymentAreaById(party.deployment);

			if (!area)
			{

			}

			if (!area)
			{
				logger.error("BattleSim.autoDeploy Cannot autodeploy to non-existent area: " + party.deployment);
			}
			else
			{
				for (var i : int = 0; i < party.numMembers; ++i)
				{
					var e : IBattleEntity = party.getMember(i);
					if (!e.deploymentReady)
					{
						autoDeployCharacter(e, area);
					}
				}
			}
		}

		public function autoDeployCharacter(c : IBattleEntity, deployment : BattleDeploymentArea) : void
		{
			var dr : TileRect = deployment.area.rect;

			const center : Point = def.walkableTiles.rect.center;
			//area.sortByDistance(TileLocation.fetch(center.x, center.y));
			deployment.area.sortByRow(TileLocation.fetch(center.x, center.y), false);

			for each (var loc : TileLocation in deployment.area.sorted)
			{
				if (attemptDeploy(c, deployment.area, loc))
				{
					return;
				}
			}

			logger.error("Failed to autoDeployCharacter in deployment: " + deployment);
		}

		public function attemptDeploy(c : IBattleEntity, area : TileLocationArea, tile : TileLocation) : Boolean
		{
			if (!tile)
			{
				return false;
			}

			var blocked : Boolean = findAllRectIntersectionEntities(tile.x, tile.y, c.width, c.length, c, null);

			if (blocked)
			{
				//	scene.config.logger.debug("blocked spaces");
				return false;
			}

			for (var x : int = 0; x < c.width; ++x)
			{
				for (var y : int = 0; y < c.length; ++y)
				{
					var loc : TileLocation = TileLocation.fetch(tile.x + x, tile.y + y);
					if (!area.hasTile(loc))
					{
						//logger.debug("BattleSim.attemptDeploy invalid location");
						return false;
					}
				}
			}

			c.setPos(tile.x, tile.y);
			c.deploymentReady = true;
			return true;
		}

		public function get def() : BattleBoardDef
		{
			return _def;
		}

		public function set def(value : BattleBoardDef) : void
		{
			_def = value;
		}

		public function get fake() : Boolean
		{
			return _fake;
		}

		public function set fake(value : Boolean) : void
		{
			if (_fake == value)
			{
				return;
			}

			_fake = value;

			abilityManager.faking = _fake;

			for each (var e : BattleEntity in entities)
			{
				e.fake = _fake;
			}
		}

		private var updating : Boolean;

		public function update(delta : int) : void
		{
			updating = true;

			for each (var e : BattleEntity in entities)
			{
				e.update(delta);
			}

			for each (var v : VfxSequence in vfxs)
			{
				v.update(delta);
			}

			updating = false;
		}

		public function get boardSetup() : Boolean
		{
			return _boardSetup;
		}

		public function set boardSetup(value : Boolean) : void
		{
			if (_boardSetup != value)
			{
				_boardSetup = value;

				dispatchEvent(new BattleBoardEvent(BattleBoardEvent.BOARDSETUP));
			}
		}

		public function get fsm() : BattleFsm
		{
			return sim.fsm;
		}

		public function get resman() : ResourceManager
		{
			return _resman;
		}

		public function addVfxSequence(vfx : VfxSequence) : void
		{
			if (updating)
			{
				throw new IllegalOperationError("Cannot add vfx sequence during update - yet");
			}

			vfxs.push(vfx);
		}

		public function removeVfxSequence(vfx : VfxSequence) : void
		{
			if (updating)
			{
				throw new IllegalOperationError("Cannot remove vfx sequence during update - yet");
			}

			const i : int = vfxs.indexOf(vfx);
			if (i >= 0)
			{
				vfxs.splice(i, 1);
			}
		}

		private function triggersRemovedHandler(event : BattleBoardTriggersEvent) : void
		{
			const trig : BattleBoardTrigger = event.trigger;

			for each (var v : VfxSequence in trig.vfxs)
			{
				removeVfxSequence(v);
			}
		}

		private function triggersAddedHandler(event : BattleBoardTriggersEvent) : void
		{
			const trig : BattleBoardTrigger = event.trigger;

			for each (var v : VfxSequence in trig.vfxs)
			{
				addVfxSequence(v);
			}
		}

		private function expireDeadEntitiesEffects() : void
		{
			for each (var o : BattleEntity in entities)
			{
				o.expireDeadEntitiesEffects();
			}
		}

		public function get spawn_tags() : String
		{
			return _spawn_tags;
		}

		public function set spawn_tags(value : String) : void
		{
			_spawn_tags = value;
			spawn_tags_dict = new Dictionary;

			if (_spawn_tags)
			{
				var a : Array = _spawn_tags.split(" ");
				for each (var t : String in a)
				{
					spawn_tags_dict[a] = true;
				}
			}
		}

	}
}
