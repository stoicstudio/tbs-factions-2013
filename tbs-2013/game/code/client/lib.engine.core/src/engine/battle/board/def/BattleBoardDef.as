package engine.battle.board.def
{
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.utils.Dictionary;

	import engine.battle.ability.effect.model.BattleFacing;
	import engine.core.locale.Locale;
	import engine.sound.ISoundDriver;
	import engine.tile.def.TileLocation;
	import engine.tile.def.TileLocationArea;

	public class BattleBoardDef extends EventDispatcher
	{
		public static const EVENT_POS : String = "BattleBoardDef.EVENT_POS";
		public static const EVENT_DEPLOYMENTS : String = "BattleBoardDef.EVENT_DEPLOYMENTS";
		public static const EVENT_SPAWNERS : String = "BattleBoardDef.EVENT_SPAWNERS";

		public var id : String;
		private var _pos : Point;
		public var layer : String;

		public var deploymentAreas : Vector.<BattleDeploymentArea> = new Vector.<BattleDeploymentArea>;
		private var deploymentAreasById : Dictionary = new Dictionary;

		public var spawners : Vector.<BattleSpawnerDef> = new Vector.<BattleSpawnerDef>;
		public var triggers : Vector.<BattleBoardTriggerSpawner> = new Vector.<BattleBoardTriggerSpawner>;

		public var walkableTiles : TileLocationArea;
		public var unwalkableTiles : TileLocationArea;

		private var resolveCallback : Function;
		public var triggerDefManager : BattleBoardTriggerDefManager;

		public function BattleBoardDef()
		{
		}

		public function init(locale : Locale) : void
		{
			pos = new Point;
			layer = "3_walk_back";
			walkableTiles = new TileLocationArea;
			unwalkableTiles = new TileLocationArea;
		}

		public function resolve(resolveCallback : Function, soundDriver : ISoundDriver) : void
		{
			if (this.resolveCallback != null)
			{
				throw IllegalOperationError("already resolving");
			}

			this.resolveCallback = resolveCallback;
			finishResolve(soundDriver);
		}

		private function finishResolve(soundDriver : ISoundDriver) : void
		{
			var cb : Function = this.resolveCallback;
			if (cb != null)
			{
				cb(this, soundDriver);
			}
		}

		public function addDeploymentArea(da : BattleDeploymentArea) : void
		{
			if (da.id in deploymentAreasById)
			{
				throw new ArgumentError("Already have deployment area " + da.id);
			}

			deploymentAreasById[da.id] = da;
			deploymentAreas.push(da);
		}

		public function getDeploymentAreaById(id : String) : BattleDeploymentArea
		{
			return deploymentAreasById[id];
		}

		public function getDeploymentAreaIdByIndex(index : int) : String
		{
			index = index % deploymentAreas.length;
			return deploymentAreas[index].id;
		}

		public function getDeploymentFacing(id : String) : BattleFacing
		{
			var deployment : BattleDeploymentArea = getDeploymentAreaById(id);

			return deployment ? deployment.facing : null;
		}

		public function addSpawner(bsd : BattleSpawnerDef) : void
		{
			spawners.push(bsd);
		}

		public function addTrigger(bbts : BattleBoardTriggerSpawner) : void
		{
			triggers.push(bbts);
		}

		public function get pos() : Point
		{
			return _pos;
		}

		public function set pos(value : Point) : void
		{
			if (_pos == value)
			{
				return;
			}

			if (_pos && value)
			{
				if (_pos.x == value.x && _pos.y == value.y)
				{
					return;
				}
			}
			_pos = value;

			dispatchEvent(new Event(EVENT_POS));
		}

		public function createDeploymentArea() : BattleDeploymentArea
		{
			for (var i : int = 0; i < 100; ++i)
			{
				var s : String = "New Board " + i;
				if (!getDeploymentAreaById(s))
				{
					var bbd : BattleDeploymentArea = new BattleDeploymentArea;

					deploymentAreas.push(bbd);
					deploymentAreasById[id] = bbd;

					dispatchEvent(new Event(EVENT_DEPLOYMENTS));
					return bbd;
				}
			}

			return null;
		}

		public function promoteDeploymentArea(b : BattleDeploymentArea) : void
		{
			var index : int = deploymentAreas.indexOf(b);
			if (index > 0)
			{
				deploymentAreas.splice(index, 1);
				deploymentAreas.splice(index - 1, 0, b);
				dispatchEvent(new Event(EVENT_DEPLOYMENTS));
			}
		}

		public function demoteDeploymentArea(b : BattleDeploymentArea) : void
		{
			var index : int = deploymentAreas.indexOf(b);
			if (index >= 0 && index < (deploymentAreas.length - 1))
			{
				deploymentAreas.splice(index, 1);
				deploymentAreas.splice(index + 1, 0, b);
				dispatchEvent(new Event(EVENT_DEPLOYMENTS));
			}
		}

		public function removeDeploymentArea(b : BattleDeploymentArea) : void
		{
			var index : int = deploymentAreas.indexOf(b);
			if (index >= 0)
			{
				deploymentAreas.splice(index, 1);
				dispatchEvent(new Event(EVENT_DEPLOYMENTS));
			}
		}

		public function renameDeploymentArea(b : BattleDeploymentArea, name : String) : void
		{
			var index : int = deploymentAreas.indexOf(b);
			if (index >= 0)
			{
				delete deploymentAreasById[b.id];
				b.id = name;
				deploymentAreas[name] = b;
				dispatchEvent(new Event(EVENT_DEPLOYMENTS));
			}
		}

		////

		public function createSpawnerDef() : BattleSpawnerDef
		{

			var sp : BattleSpawnerDef = new BattleSpawnerDef;
			sp.team = "npc";

			spawners.push(sp);
			dispatchEvent(new Event(EVENT_SPAWNERS));
			return sp;

		}

		public function promoteSpawnerDef(b : BattleSpawnerDef) : void
		{
			var index : int = spawners.indexOf(b);
			if (index > 0)
			{
				spawners.splice(index, 1);
				spawners.splice(index - 1, 0, b);
				dispatchEvent(new Event(EVENT_SPAWNERS));
			}
		}

		public function demoteSpawnerDef(b : BattleSpawnerDef) : void
		{
			var index : int = spawners.indexOf(b);
			if (index >= 0 && index < (spawners.length - 1))
			{
				spawners.splice(index, 1);
				spawners.splice(index + 1, 0, b);
				dispatchEvent(new Event(EVENT_SPAWNERS));
			}
		}

		public function removeSpawnerDef(b : BattleSpawnerDef) : void
		{
			var index : int = spawners.indexOf(b);
			if (index >= 0)
			{
				spawners.splice(index, 1);
				dispatchEvent(new Event(EVENT_SPAWNERS));
			}
		}

		public function getFirstSpawnerAt(tl : TileLocation) : BattleSpawnerDef
		{
			for each (var s : BattleSpawnerDef in spawners)
			{
				if (s.location == tl)
				{
					return s;
				}
			}
			return null;
		}

		public function hasSpawnerAt(tl : TileLocation) : Boolean
		{
			return getFirstSpawnerAt(tl) != null;

		}
	}
}
