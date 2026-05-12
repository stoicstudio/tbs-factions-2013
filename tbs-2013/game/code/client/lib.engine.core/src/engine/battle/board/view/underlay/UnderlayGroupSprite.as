package engine.battle.board.view.underlay
{

	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.utils.Dictionary;

	import engine.ability.def.AbilityDefLevel;
	import engine.battle.ability.def.BattleAbilityDef;
	import engine.battle.ability.def.BattleAbilityDefLevels;
	import engine.battle.ability.def.BattleAbilityTag;
	import engine.battle.ability.model.BattleAbilityValidation;
	import engine.battle.board.IsoBattleRectangleUtils;
	import engine.battle.board.view.BattleBoardView;
	import engine.battle.board.view.overlay.TileMarkerOverlay;
	import engine.battle.entity.model.BattleEntity;
	import engine.battle.fsm.BattleFsm;
	import engine.battle.fsm.BattleFsmEvent;
	import engine.battle.fsm.BattleMoveEvent;
	import engine.battle.fsm.BattleTurn;
	import engine.battle.fsm.BattleTurnEvent;
	import engine.core.fsm.FsmEvent;
	import engine.resource.BitmapResource;
	import engine.resource.ResourceGroup;
	import engine.tile.Tile;
	import engine.tile.def.TileLocation;

	public class UnderlayGroupSprite extends Sprite
	{
		private var movePlanUnderlay : MovePlanUnderlay;
		public var tilesUnderlay : TilesUnderlay;
		private var deploymentUnderlay : DeploymentUnderlay;
		private var tileTargetUnderlay : TileTargetUnderlay;
		private var corpseTilesUnderlay : CorpseTilesUnderlay;
		private var tileTriggerTilesUnderlay : TileTriggerTilesUnderlay;
		public var marker : TileMarkerOverlay;

		private var dirty : Boolean = true;
		private var view : BattleBoardView;
		private var _turn : BattleTurn;
		private var tileBmps : Dictionary = new Dictionary;

		private var moveTilesSprite : Sprite = new Sprite;

		private var resourceGroup : ResourceGroup = new ResourceGroup;

		private var fsm : BattleFsm;

		public function UnderlayGroupSprite(view : BattleBoardView)
		{
			this.view = view;
			name = "underlay";

			marker = new TileMarkerOverlay(view);
			movePlanUnderlay = new MovePlanUnderlay(view);
			tilesUnderlay = new TilesUnderlay(view);
			deploymentUnderlay = new DeploymentUnderlay(view);
			tileTargetUnderlay = new TileTargetUnderlay(view);
			corpseTilesUnderlay = new CorpseTilesUnderlay(view);
			tileTriggerTilesUnderlay = new TileTriggerTilesUnderlay(view);

			fsm = view.board.sim.fsm;
			fsm.addEventListener(FsmEvent.CURRENT, eventDirtyHandler);
			fsm.addEventListener(BattleFsmEvent.TURN, eventDirtyHandler);
			fsm.addEventListener(BattleFsmEvent.INTERACT, eventDirtyHandler);

			addChild(tilesUnderlay);
			addChild(deploymentUnderlay);
			addChild(marker);
			addChild(movePlanUnderlay);
			addChild(tileTargetUnderlay);
			addChild(corpseTilesUnderlay);
			addChild(tileTriggerTilesUnderlay);
		}

		public function cleanup() : void
		{
			tilesUnderlay.cleanup();
			deploymentUnderlay.cleanup();
			movePlanUnderlay.cleanup();
			tileTargetUnderlay.cleanup();
			corpseTilesUnderlay.cleanup();
			tileTriggerTilesUnderlay.cleanup();

			fsm.removeEventListener(FsmEvent.CURRENT, eventDirtyHandler);
			fsm.removeEventListener(BattleFsmEvent.TURN, eventDirtyHandler);
			fsm.removeEventListener(BattleFsmEvent.INTERACT, eventDirtyHandler);
			fsm.removeEventListener(BattleFsmEvent.TURN_ABILITY, eventDirtyHandler);

			tilesUnderlay.cleanup();
			movePlanUnderlay.cleanup();

			while (numChildren > 0)
			{
				var c : Bitmap = removeChildAt(numChildren - 1) as Bitmap;
				if (c)
				{
					view.bitmapPool.reclaim(c);
				}
			}
		}

		private function eventDirtyHandler(event : Event) : void
		{
			dirty = true;
			turn = fsm.turn;
		}

		private function setBmpr(cont : DisplayObjectContainer, loc : TileLocation, res : BitmapResource, size : int) : Bitmap
		{
			var bmp : Bitmap = res.bmp;
			if (bmp)
			{
				positionBmp(loc, bmp, size);
				cont.addChild(bmp);
			}
			return bmp;
		}

		public function positionBmp(loc : TileLocation, bmp : Bitmap, size : int) : void
		{
			// center bitmap on tile
			var dp : Point = IsoBattleRectangleUtils.getIsoPointScreenPoint(view.units, loc.x + 0.5 * size, loc.y + 0.5 * size);
			bmp.x = dp.x - bmp.width / 2;
			bmp.y = dp.y - bmp.height / 2;
		}

		private function checkValidity(caster : BattleEntity, target : BattleEntity, adef : BattleAbilityDef) : BattleAbilityValidation
		{
			var isEnemy : Boolean = caster.team != target.team;
			var valid : BattleAbilityValidation;

			if (adef)
			{
				valid = BattleAbilityValidation.validate(adef, caster, turn.move, target, null, false, false);
			}
			else if (isEnemy)
			{
				var batks : BattleAbilityDefLevels = caster.def.attacks as BattleAbilityDefLevels;
				var atkstr : AbilityDefLevel = batks.getFirstAbilityByTag(BattleAbilityTag.ATTACK_STR);
				var atkarm : AbilityDefLevel = batks.getFirstAbilityByTag(BattleAbilityTag.ATTACK_ARM);

				if (atkstr)
				{
					valid = BattleAbilityValidation.validate(atkstr.def as BattleAbilityDef, caster, turn.move, target, null, false, false);
				}

				if (valid != BattleAbilityValidation.OK && atkarm)
				{
					valid = BattleAbilityValidation.validate(atkarm.def as BattleAbilityDef, caster, turn.move, target, null, false, false);
				}
			}
			return valid;
		}

		private function setTile(x : int, y : int, url : String) : void
		{
			var tile : Tile = view.board.tiles.getTile(x, y);
			if (tile)
			{
				if (!(tile in tileBmps))
				{
					if (url)
					{
						var bmp : Bitmap = view.bitmapPool.pop(url);
						tileBmps[tile] = bmp;
					}
				}
			}
		}

		private function setTileForEntity(e : BattleEntity, url : String) : void
		{
			setTile(e.x, e.y, url);

			for (var x : int = 0; x < e.width; ++x)
			{
				for (var y : int = 0; y < e.length; ++y)
				{
					if (x != 0 || y != 0)
					{
						// block rendering here
						setTile(e.x + x, e.y + y, "");
					}
				}
			}
		}

		private function setActiveVisible(what : DisplayObject, why : DisplayObject) : void
		{
			if (what)
			{
				what.visible = what == why;
			}
		}

		public static const BIT : uint = TilesUnderlay.nextBit();

		private function setupTiles() : void
		{
			tilesUnderlay.unhideAll(BIT);

			if (!_turn)
			{
				return;
			}

		}

		private function get active() : BattleEntity
		{
			return _turn ? _turn.entity as BattleEntity : null;
		}

		public function render() : void
		{
			tilesUnderlay.render();
			movePlanUnderlay.render();
			deploymentUnderlay.render();
			tileTargetUnderlay.render();
			corpseTilesUnderlay.render();
			tileTriggerTilesUnderlay.render();
			marker.render();

			if (!dirty)
			{
				return;
			}

			dirty = false;

			setupTiles();
		}

		public function get turn() : BattleTurn
		{
			return _turn;
		}

		public function set turn(value : BattleTurn) : void
		{
			if (_turn == value)
			{
				return;
			}

			if (_turn)
			{
				_turn.addEventListener(BattleTurnEvent.COMPLETE, eventDirtyHandler);
				_turn.removeEventListener(BattleTurnEvent.ABILITY, eventDirtyHandler);
				_turn.move.removeEventListener(BattleMoveEvent.COMMITTED, eventDirtyHandler);
				_turn.move.removeEventListener(BattleMoveEvent.EXECUTING, eventDirtyHandler);
				_turn.move.removeEventListener(BattleMoveEvent.EXECUTED, eventDirtyHandler);
			}

			_turn = value;

			if (_turn)
			{
				_turn.addEventListener(BattleTurnEvent.COMPLETE, eventDirtyHandler);
				_turn.addEventListener(BattleTurnEvent.ABILITY, eventDirtyHandler);
				_turn.move.addEventListener(BattleMoveEvent.COMMITTED, eventDirtyHandler);
				_turn.move.addEventListener(BattleMoveEvent.EXECUTING, eventDirtyHandler);
				_turn.move.addEventListener(BattleMoveEvent.EXECUTED, eventDirtyHandler);
			}
		}
	}
}
