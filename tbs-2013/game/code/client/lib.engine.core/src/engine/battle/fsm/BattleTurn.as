package engine.battle.fsm
{
	import flash.errors.IllegalOperationError;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	import engine.ability.def.AbilityDefLevel;
	import engine.battle.ability.def.BattleAbilityDef;
	import engine.battle.ability.def.BattleAbilityDefLevels;
	import engine.battle.ability.def.BattleAbilityTag;
	import engine.battle.ability.def.BattleAbilityTargetRule;
	import engine.battle.ability.model.BattleAbility;
	import engine.battle.ability.model.BattleAbilityEvent;
	import engine.battle.ability.model.BattleAbilityValidation;
	import engine.battle.ability.model.BattleTargetSet;
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.entity.model.BattleEntity;
	import engine.core.cmd.CmdExec;
	import engine.core.cmd.ShellCmdManager;
	import engine.core.logging.ILogger;
	import engine.core.util.UtilFunctions;
	import engine.tile.ITileResident;
	import engine.tile.Tile;
	import engine.tile.def.TileRectRange;

	public class BattleTurn extends EventDispatcher
	{
		private var _entity : IBattleEntity;
		private var _interact : IBattleEntity;
		private var _move : BattleMove;
		public var logger : ILogger;
		private var _ability : BattleAbility;
		private var _number : int;
		private var _complete : Boolean;
		private var _committed : Boolean;
		private var _suspended : Boolean;
		private var _attackMode : Boolean;
		public var selfPopupAnimating : Boolean;
		public var shell : ShellCmdManager;
		public var inRange : Dictionary = new Dictionary;
		public var inRangeTiles : Dictionary = new Dictionary;
		public var hash : int;
		public var abilityTargets : BattleTargetSet;
		public var timerSecs : int;

		public function BattleTurn(entity : IBattleEntity, number : int, hash : int, logger : ILogger)
		{
			this.logger = logger;
			this._entity = entity;
			this._number = number;
			this.move = new BattleMove(entity);
			this.shell = new ShellCmdManager(logger);
			this.hash = hash;
			this.timerSecs = entity.party.timer;

			this.shell.add("info", shellCmdFuncInfo);
			this.shell.add("ability", shellCmdFuncAbility);

			move.addEventListener(BattleMoveEvent.MOVE_CHANGED, moveEventHandler);
			move.addEventListener(BattleMoveEvent.EXECUTED, moveExecutedHandler);
			cacheInRanges();
		}

		public function targetsUpdated() : void
		{
			ability.targetSet = abilityTargets;
			dispatchEvent(new BattleTurnEvent(BattleTurnEvent.ABILITY_TARGET));
		}

		public function get attackMode() : Boolean
		{
			return _attackMode;
		}

		public function set attackMode(value : Boolean) : void
		{
			if (value == _attackMode)
			{
				return;
			}

			_attackMode = value;
			dispatchEvent(new BattleTurnEvent(BattleTurnEvent.ATTACK_MODE));
			cacheInRanges();
		}

		private function moveExecutedHandler(event : BattleMoveEvent) : void
		{
			cacheInRanges();
		}

		private function moveEventHandler(event : BattleMoveEvent) : void
		{
			cacheInRanges();
		}

		public function cleanup() : void
		{
			move.removeEventListener(BattleMoveEvent.MOVE_CHANGED, moveEventHandler);
			move.removeEventListener(BattleMoveEvent.EXECUTED, moveEventHandler);
		}

		public function get ability() : BattleAbility
		{
			return _ability;
		}

		public function set ability(value : BattleAbility) : void
		{
			if (_ability == value)
			{
				return;
			}

			if (_ability)
			{
				if (_ability.executed || _ability.executing)
				{
					throw new IllegalOperationError("Can't change the ability while it is executing, or afterwards");
				}

				_ability.removeEventListener(BattleAbilityEvent.FINAL_COMPLETE, abilityFinalCompleteHandler);
				_ability.removeEventListener(BattleAbilityEvent.EXECUTING, abilityExecutingHandler);
			}

			_ability = value;
			abilityTargets = new BattleTargetSet(_ability);

			if (_ability)
			{
				_ability.addEventListener(BattleAbilityEvent.FINAL_COMPLETE, abilityFinalCompleteHandler);
				_ability.addEventListener(BattleAbilityEvent.EXECUTING, abilityExecutingHandler);
			}

			// check in ranges
			cacheInRanges();

			dispatchEvent(new BattleTurnEvent(BattleTurnEvent.ABILITY));
		}

		private function abilityExecutingHandler(event : BattleAbilityEvent) : void
		{
			dispatchEvent(new BattleTurnEvent(BattleTurnEvent.ABILITY_EXECUTING));
		}

		private function cacheInRanges() : void
		{
			var batks : BattleAbilityDefLevels = _entity.def.attacks as BattleAbilityDefLevels;
			var atkstr : AbilityDefLevel = ability ? null : batks.getFirstAbilityByTag(BattleAbilityTag.ATTACK_STR);
			var atkarm : AbilityDefLevel = ability ? null : batks.getFirstAbilityByTag(BattleAbilityTag.ATTACK_ARM);

			inRange = new Dictionary;
			inRangeTiles = new Dictionary;

			var valid : BattleAbilityValidation = null;
			var tile : Tile;

			const highest : BattleAbilityDef = ability ? entity.highestAvailableAbilityDef() as BattleAbilityDef : null;

			if (highest && (highest.targetRule == BattleAbilityTargetRule.TILE_EMPTY || highest.targetRule == BattleAbilityTargetRule.TILE_ANY))
			{
				for each (tile in _entity.board.tiles.tiles)
				{
					if (move.last == tile)
					{
						// we're going to end up here, so don't allow tile placement here 
						continue;
					}
					valid = BattleAbilityValidation.validate(highest, _entity, move, null, tile, false, false);
					if (valid == BattleAbilityValidation.OK)
					{
						inRangeTiles[tile.location] = tile.location;
					}
				}
			}
			else
			{
				if (highest)
				{
					def = highest;
				}

				if (!def && atkstr)
				{
					def = (atkstr.def as BattleAbilityDef);
				}

				if (!def && atkarm)
				{
					def = (atkarm.def as BattleAbilityDef);
				}

				if (def)
				{
					for each (tile in _entity.board.tiles.tiles)
					{
						// AXIAL
						if (def.targetRule == BattleAbilityTargetRule.SPECIAL_RUN_THROUGH || def.targetRule == BattleAbilityTargetRule.SPECIAL_BATTERING_RAM)
						{
							// axial check
							if (UtilFunctions.isAxialEntity2Tile(_entity, tile) == false)
							{
								continue;
							}
						}

						var trr : int = TileRectRange.computeRange(_entity.rect, tile.rect);
						if (trr > 0 && trr >= def.rangeMin && trr <= def.rangeMax)
						{
							inRangeTiles[tile.location] = tile.location;
						}
					}
				}

				for each (var e : BattleEntity in _entity.board.entities)
				{
					if (e == _entity)
					{
						continue;
					}

					if (!e.alive)
					{
						continue;
					}

					valid = null;

					var def : BattleAbilityDef;

					if (highest)
					{
						if (highest.targetRule != BattleAbilityTargetRule.NONE)
						{
							valid = BattleAbilityValidation.validate(highest, _entity, move, e, null, false, false);
						}
					}
					else if (e.team != _entity.team)
					{
						if (atkstr)
						{
							valid = BattleAbilityValidation.validateRange(atkstr.def as BattleAbilityDef, _entity, move, e, null);
						}

						if (valid != BattleAbilityValidation.OK && atkarm)
						{
							valid = BattleAbilityValidation.validateRange(atkarm.def as BattleAbilityDef, _entity, move, e, null);
						}
					}

					if (valid == BattleAbilityValidation.OK)
					{
						inRange[e] = e;
					}
				}
			}

			dispatchEvent(new BattleTurnEvent(BattleTurnEvent.IN_RANGE));
		}

		private function abilityFinalCompleteHandler(event : BattleAbilityEvent) : void
		{
			complete = _complete || _ability && _ability.finalCompleted;
		}

		public function get turnInteract() : IBattleEntity
		{
			return _interact;
		}

		internal function setTurnInteract(value : IBattleEntity) : void
		{
			if (value != _interact)
			{
//				ability = null;
				_interact = value;
				dispatchEvent(new BattleTurnEvent(BattleTurnEvent.TURN_INTERACT));
			}
		}

		public function get complete() : Boolean
		{
			return _complete;
		}

		public function set complete(value : Boolean) : void
		{
			if (_complete == value)
			{
				return;
			}

			_complete = value;
			dispatchEvent(new BattleTurnEvent(BattleTurnEvent.COMPLETE));
		}

		public function get committed() : Boolean
		{
			return _committed;
		}

		public function set committed(value : Boolean) : void
		{
			if (_committed == value)
			{
				return;
			}

			_committed = value;

			dispatchEvent(new BattleTurnEvent(BattleTurnEvent.COMMITTED));
		}

		private function shellCmdFuncInfo(c : CmdExec) : void
		{
			logger.info("Turn: ");
			logger.info("    number = " + _number);
			logger.info("   ability = " + ability);
		}

		private function shellCmdFuncAbility(c : CmdExec) : void
		{
			var argv : Array = c.param;

			if (argv.length > 1)
			{
				var id : String = argv[1];

				logger.info("shellCmdFuncAbility id = " + id);

				if (id == "exec")
				{
					if (ability)
					{
						ability.execute(null);
					}
					return;
				}

				var requestedAbilityDef : BattleAbilityDef = _entity.board.abilityManager.factory.fetchBattleAbilityDef(id);

				if (requestedAbilityDef != null)
				{
					var requestedAbility : BattleAbility = new BattleAbility(_entity, requestedAbilityDef, _entity.board.abilityManager);

					if (requestedAbility != null)
					{
						var abilityOK : Boolean = false;

						switch (id)
						{
							case "abl_tempest":
							{
								abilityOK = handleAbilityTempest(requestedAbility, argv);
							}
								break;
							case "abl_bloodyflail":
							{
								abilityOK = handleAbilityBloodyFlail(requestedAbility, argv);
							}
								break;
							case "abl_rainofarrows":
							{
								if (argv[2] == "*")
								{
									// let the controller take over the targeting
									ability = requestedAbility;
									return;
								}
								abilityOK = handleAbilityRainOfArrows(requestedAbility, argv);
							}
								break;
							case "abl_malice":
							{
								abilityOK = handleAbilityMalice(requestedAbility, argv);
							}
								break;
						}

						if (abilityOK == true)
						{
							ability = requestedAbility;
							logger.info("executing ability : " + ability.def.name);

							ability.execute(abilityExecuteCallback);
						}
					}
					else
					{
						logger.error("shellCmdFuncAbility not able to find ability for id=" + id + "  def=" + requestedAbilityDef.id);
					}
				}
				else
				{
					logger.error("shellCmdFuncAbility not able to find abilitydef for id=" + id);
				}

			}

			logger.info("Turn Ability " + ability);
		}

		private function abilityExecuteCallback(battleAbility : BattleAbility) : void
		{

		}

		// ----------
		// Tempest
		// ----------
		private function handleAbilityTempest(requestedAbility : BattleAbility, argv : Array) : Boolean
		{
			if (argv.length > 2)
			{
				var targetName : String = argv[2];
				var targetBattleEntity : BattleEntity = findBattleEntity(targetName);

				if (targetBattleEntity != null)
				{
					if (isBattleEntityAdjacent(_entity as BattleEntity, targetBattleEntity) == true)
					{
						setupTempestAbilityTargetSet(targetBattleEntity, requestedAbility);
						return true;

					}
					else
					{
						logger.error("handleAbilityTempest: entity [ " + targetName + "] is not adjacent");
					}
				}
				else
				{
					logger.error("handleAbilityTempest: could not find target entity: " + targetName);
				}
			}
			else
			{
				logger.error("handleAbilityTempest : not enough arguments. argv.length = " + argv.length);
			}

			return false;
		}

		private function setupTempestAbilityTargetSet(startingEntity : BattleEntity, requestedAbility : BattleAbility) : void
		{
			requestedAbility.targetSet.targets.splice(0, requestedAbility.targetSet.targets.length);

			if (startingEntity.team == _entity.team)
			{
				logger.error("setupTempestAbilityTargetSet : first target must be an enemy ");
				return;
			}

			var adjacentEntities : Array = getAdjacentBattleEntitiesClockwise(_entity as BattleEntity);

			const maxEntitiesToHit : int = requestedAbility.def.level + 1;

			var startingIndex : int = adjacentEntities.indexOf(startingEntity);
			if (startingIndex == -1)
			{
				startingIndex = 0;
			}

			var i : int;

			for (i = startingIndex; i < adjacentEntities.length; ++i)
			{
				if (requestedAbility.targetSet.targets.length < maxEntitiesToHit)
				{
					requestedAbility.targetSet.targets.push(adjacentEntities[i]);
				}
			}
			if (startingIndex != 0)
			{
				for (i = 0; i < startingIndex; ++i)
				{
					if (requestedAbility.targetSet.targets.length < maxEntitiesToHit)
					{
						requestedAbility.targetSet.targets.push(adjacentEntities[i]);
					}
				}
			}

		}

		// ----------
		// End Tempest
		// ----------

		// ----------
		// Bloody Flail
		// ----------

		private function handleAbilityBloodyFlail(requestedAbility : BattleAbility, argv : Array) : Boolean
		{
			if (argv.length > 2)
			{
				var targetName : String = argv[2];
				var targetBattleEntity : BattleEntity = findBattleEntity(targetName);

				if (targetBattleEntity != null)
				{
					requestedAbility.targetSet.targets.splice(0, requestedAbility.targetSet.targets.length);
					requestedAbility.targetSet.targets.push(targetBattleEntity);
					return true;

				}
				else
				{
					logger.error("handleAbilityBloodyFlail: could not find target entity: " + targetName);
				}
			}
			else
			{
				logger.error("handleAbilityBloodyFlail : not enough arguments. argv.length = " + argv.length);
			}

			return false;
		}

		// ----------
		// End Bloody Flail
		// ----------

		// ----------
		// Rain of Arrows
		// ----------

		private function handleAbilityRainOfArrows(requestedAbility : BattleAbility, argv : Array) : Boolean
		{
			if (argv.length > 2)
			{

				var parsedString : Array = argv[2].split(',');
				if (parsedString.length == 2)
				{
					var sourceBattleEntity : BattleEntity = _entity as BattleEntity;

					const sourceEntityX : int = _entity.tile.x;
					const sourceEntityY : int = _entity.tile.y;
					const tileOffsetX : int = int(parsedString[0]);
					const tileOffsetY : int = int(parsedString[1]);
					const tilePosX : int = sourceEntityX + tileOffsetX;
					const tilePosY : int = sourceEntityY + tileOffsetY;

					var tile : Tile = _entity.board.tiles.getTile(tilePosX, tilePosY);

					if (tile != null)
					{
						requestedAbility.targetSet.targets.splice(0, requestedAbility.targetSet.targets.length);
						requestedAbility.targetSet.addTarget(sourceBattleEntity);
						requestedAbility.targetSet.addTile(tile);
						return true;
					}

				}
				else
				{
					logger.error("handleAbilityRainOfArrows: invalid offset given[" + argv[2] + "]");
				}
			}
			else
			{
				logger.error("handleAbilityRainOfArrows : not enough arguments. argv.length = " + argv.length);
			}

			return false;
		}

		// ----------
		// End Rain of Arrows
		// ----------

		// ----------
		// Malice
		// ----------

		private function handleAbilityMalice(requestedAbility : BattleAbility, argv : Array) : Boolean
		{
			if (argv.length > 2)
			{
				var targetName : String = argv[2];
				var targetBattleEntity : BattleEntity = findBattleEntity(targetName);

				if (targetBattleEntity != null)
				{
					requestedAbility.targetSet.targets.splice(0, requestedAbility.targetSet.targets.length);
					requestedAbility.targetSet.targets.push(targetBattleEntity);
					return true;

				}
				else
				{
					logger.error("handleAbilityMalice: could not find target entity: " + targetName);
				}
			}
			else
			{
				logger.error("handleAbilityMalice : not enough arguments. argv.length = " + argv.length);
			}

			return false;
		}

		// ----------
		// End Malice
		// ----------

		// General ability utility
		private function findBattleEntity(targetName : String) : BattleEntity
		{
			if (_entity != null && _entity.board != null)
			{
				for each (var targetEntity : BattleEntity in _entity.board.entities)
				{
					if (targetEntity.def.id == targetName)
					{
						return targetEntity;
					}
				}
			}
			return null;
		}

		private function isBattleEntityAdjacent(sourceEntity : BattleEntity, adjacentEntity : BattleEntity) : Boolean
		{
			const x : int = sourceEntity.tile.x;
			const y : int = sourceEntity.tile.y;

			if (sourceEntity.rect.width == 1)
			{
				if ((adjacentEntity == getBattleEntityOnTile(x, y - 1))
					|| (adjacentEntity == getBattleEntityOnTile(x + 1, y))
					|| (adjacentEntity == getBattleEntityOnTile(x, y + 1))
					|| (adjacentEntity == getBattleEntityOnTile(x - 1, y)))
				{
					return true;
				}
			}
			else if (sourceEntity.rect.width == 2)
			{
				if ((adjacentEntity == getBattleEntityOnTile(x, y - 1))
					|| (adjacentEntity == getBattleEntityOnTile(x + 1, y - 1))
					|| (adjacentEntity == getBattleEntityOnTile(x + 2, y))
					|| (adjacentEntity == getBattleEntityOnTile(x + 2, y + 1))
					|| (adjacentEntity == getBattleEntityOnTile(x, y + 2))
					|| (adjacentEntity == getBattleEntityOnTile(x + 1, y + 2))
					|| (adjacentEntity == getBattleEntityOnTile(x - 1, y + 1))
					|| (adjacentEntity == getBattleEntityOnTile(x - 1, y)))
				{
					return true;
				}
			}

			return false;
		}

		private function getBattleEntityOnTile(x : int, y : int) : BattleEntity
		{
			var tile : Tile = _entity.board.tiles.getTile(x, y);
			if (tile != null)
			{
				var tileResident : ITileResident = tile.findResident(null);
				if (tileResident != null && tileResident is BattleEntity)
				{
					return tileResident as BattleEntity;
				}
			}

			return null;
		}

		// array ordered clockwise
		private function getAdjacentBattleEntitiesClockwise(sourceEntity : BattleEntity) : Array
		{
			const x : int = sourceEntity.tile.x;
			const y : int = sourceEntity.tile.y;
			var ret : Array = new Array();
			var adjacentEntity : BattleEntity;

			if (sourceEntity.rect.width == 1)
			{
				adjacentEntity = getBattleEntityOnTile(x, y - 1);
				if (adjacentEntity != null && ret.indexOf(adjacentEntity) == -1)
				{
					ret.push(adjacentEntity);
				}

				adjacentEntity = getBattleEntityOnTile(x + 1, y);
				if (adjacentEntity != null && ret.indexOf(adjacentEntity) == -1)
				{
					ret.push(adjacentEntity);
				}

				adjacentEntity = getBattleEntityOnTile(x, y + 1);
				if (adjacentEntity != null && ret.indexOf(adjacentEntity) == -1)
				{
					ret.push(adjacentEntity);
				}

				adjacentEntity = getBattleEntityOnTile(x - 1, y);
				if (adjacentEntity != null && ret.indexOf(adjacentEntity) == -1)
				{
					ret.push(adjacentEntity);
				}
			}
			else if (sourceEntity.rect.width == 2)
			{
				adjacentEntity = getBattleEntityOnTile(x, y - 1);
				if (adjacentEntity != null && ret.indexOf(adjacentEntity) == -1)
				{
					ret.push(adjacentEntity);
				}

				adjacentEntity = getBattleEntityOnTile(x + 1, y - 1);
				if (adjacentEntity != null && ret.indexOf(adjacentEntity) == -1)
				{
					ret.push(adjacentEntity);
				}

				adjacentEntity = getBattleEntityOnTile(x + 2, y);
				if (adjacentEntity != null && ret.indexOf(adjacentEntity) == -1)
				{
					ret.push(adjacentEntity);
				}

				adjacentEntity = getBattleEntityOnTile(x + 2, y + 1);
				if (adjacentEntity != null && ret.indexOf(adjacentEntity) == -1)
				{
					ret.push(adjacentEntity);
				}

				adjacentEntity = getBattleEntityOnTile(x, y + 2);
				if (adjacentEntity != null && ret.indexOf(adjacentEntity) == -1)
				{
					ret.push(adjacentEntity);
				}

				adjacentEntity = getBattleEntityOnTile(x + 1, y + 2);
				if (adjacentEntity != null && ret.indexOf(adjacentEntity) == -1)
				{
					ret.push(adjacentEntity);
				}

				adjacentEntity = getBattleEntityOnTile(x - 1, y + 1);
				if (adjacentEntity != null && ret.indexOf(adjacentEntity) == -1)
				{
					ret.push(adjacentEntity);
				}

				adjacentEntity = getBattleEntityOnTile(x - 1, y);
				if (adjacentEntity != null && ret.indexOf(adjacentEntity) == -1)
				{
					ret.push(adjacentEntity);
				}
			}

			return ret;
		}

		public function get move() : BattleMove
		{
			return _move;
		}

		public function set move(value : BattleMove) : void
		{
			if (_move == value)
			{
				return;
			}

			if (_move)
			{
				_move.cleanup();
				_move = null;
			}

			if (value && value.entity != _entity)
			{
				throw new ArgumentError("BattleTurn.move ENTITY MISMATCH " + this + " move " + value);
			}

			_move = value;
			_move.listenForWillpower();
		}

		public function get number() : int
		{
			return _number;
		}

		public function get entity() : IBattleEntity
		{
			return _entity;
		}

		public function get suspended() : Boolean
		{
			return _suspended;
		}

		public function set suspended(value : Boolean) : void
		{
			_suspended = value;
			if (_suspended)
			{
				committed = true;
			}
		}

	}
}
