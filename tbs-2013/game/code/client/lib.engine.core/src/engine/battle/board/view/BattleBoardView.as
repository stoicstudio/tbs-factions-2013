package engine.battle.board.view
{
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.utils.Dictionary;

	import as3isolib.data.INode;
	import as3isolib.display.IsoView;
	import as3isolib.display.scene.IsoGrid;
	import as3isolib.geom.IsoMath;
	import as3isolib.geom.Pt;

	import engine.battle.board.BattleBoardEvent;
	import engine.battle.board.def.BattleBoardDef;
	import engine.battle.board.model.BattleBoard;
	import engine.battle.board.model.BattleBoardTriggersEvent;
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.board.view.arrow.ArrowManager;
	import engine.battle.board.view.indicator.EntityFlyText;
	import engine.battle.board.view.overlay.AbilityDestinationOverlay;
	import engine.battle.board.view.overlay.DamageFlagOverlay;
	import engine.battle.board.view.overlay.MovePlanOverlay;
	import engine.battle.board.view.phantasm.CombatScenePhantasmsView;
	import engine.battle.board.view.underlay.UnderlayGroupSprite;
	import engine.battle.entity.model.BattleEntity;
	import engine.battle.entity.model.BattleEntityEvent;
	import engine.battle.entity.view.EntityView;
	import engine.battle.entity.view.EntityViewFactory;
	import engine.battle.sim.BattlePartyEvent;
	import engine.battle.sim.IBattleParty;
	import engine.core.cmd.CmdExec;
	import engine.core.cmd.ShellCmdManager;
	import engine.gui.core.GuiSprite;
	import engine.resource.AnimClipSpritePool;
	import engine.resource.BitmapPool;
	import engine.resource.MovieClipPool;
	import engine.saga.SpeakEvent;
	import engine.sound.ISoundDriver;
	import engine.tile.Tile;
	import engine.tile.TilesEvent;
	import engine.tile.def.TileLocation;

	public class BattleBoardView extends GuiSprite
	{
		private var isoView : IsoView;
		public var isoScenes : IsoSceneLayers;
		public var isoGrid : IsoGrid;
		public var isoOverlay : Sprite = new Sprite;
		public var underlay : UnderlayGroupSprite;
		public var board : BattleBoard;
		public var entityViews : Dictionary = new Dictionary;
		public var entityViewsByDefId : Dictionary = new Dictionary;
		// the world-to-iso scale
		public var units : Number = 64;
		public var arrowManager : ArrowManager;
		public var iconLayer : IconLayer;
		private var phantasmsView : CombatScenePhantasmsView;
		public var bitmapPool : BitmapPool;
		public var movieClipPool : MovieClipPool;
		public var animClipSpritePool : AnimClipSpritePool;
		public var soundDriver : ISoundDriver;
		private var moveOverlay : MovePlanOverlay;
		//public var markerOverlay : TileMarkerOverlay;
		private var abilityDestinationOverlay : AbilityDestinationOverlay;
		private var damageFlagOverlay : DamageFlagOverlay;
		private var placefinder : Shape = new Shape();
		private var triggerViews : Dictionary = new Dictionary;

		public var sceneOffset : Point = new Point;

		public var shell : ShellCmdManager;

		private static const SMOOTH_TRIGGER_VIEWS : Boolean = false;

		public function BattleBoardView(board : BattleBoard, soundDriver : ISoundDriver)
		{
			super();

			name = "battle_board_view";
			isoOverlay.name = "overlay";

			this.soundDriver = soundDriver;

			this.board = board;

			this.shell = new ShellCmdManager(board.logger);

			shell.add("overlay", shellCmdFuncOverlay);
			shell.add("underlay", shellCmdFuncUnderlay);
			shell.add("entities", shellCmdFuncEntities);

			movieClipPool = new MovieClipPool(board.resman, 1, 20);
			bitmapPool = new BitmapPool(board.resman, 2, 20);
			animClipSpritePool = new AnimClipSpritePool(board.resman, 2, 20);

			phantasmsView = new CombatScenePhantasmsView(this);

			isoView = new IsoView("iso");
			isoView.mainContainer.mouseEnabled = false;
			isoView.mainContainer.mouseChildren = false;

			isoScenes = new IsoSceneLayers(isoView);
//
//			isoGrid = new IsoGrid();
//			isoGrid.setGridSize(board.tiles.width, board.tiles.length, 0);
//			isoGrid.cellSize = units;
//			isoGrid.showOrigin = true;
//			isoGrid.gridlines = new Stroke(1, 0x888888, 1);
//			isoScenes.fg.addChild(isoGrid);

			isoScenes.render();

			arrowManager = new ArrowManager;
			isoOverlay.addChild(arrowManager);

			iconLayer = new IconLayer;
			isoOverlay.addChild(iconLayer);

			damageFlagOverlay = new DamageFlagOverlay(this);
			isoOverlay.addChild(damageFlagOverlay);

			moveOverlay = new MovePlanOverlay(this);
			abilityDestinationOverlay = new AbilityDestinationOverlay(this);
			//markerOverlay = new TileMarkerOverlay(this);
			//			isoOverlay.addChild(markerOverlay);
			isoOverlay.addChild(moveOverlay);
			isoOverlay.addChild(abilityDestinationOverlay);

			underlay = new UnderlayGroupSprite(this);

			mouseEnabled = false;
			mouseChildren = false;

			addChild(underlay);
			addChild(isoView);
			//isoView.backgroundContainer.addChild(underlay);
			//isoView.foregroundContainer.addChild(isoOverlay);
			addChild(isoOverlay);
			isoView.showBorder = false;

			isoView.setSize(0, 0);
			isoView.clipContent = false;

			board.def.addEventListener(BattleBoardDef.EVENT_POS, boardPosHandler);
			boardPosHandler(null);

			addEventListener(Event.ENTER_FRAME, enterFrameHandler);

			board.addEventListener(BattleEntityEvent.ADDED, entityAddedHandler);
			board.addEventListener(BattleEntityEvent.REMOVED, entityRemovedHandler);
			board.tiles.addEventListener(TilesEvent.TILE_FLYTEXT, tileFlytextHandler);

			board.addEventListener(BattleBoardEvent.PARTY, boardPartyHandler);

			board.addEventListener(BattleBoardEvent.BOARDSETUP, boardSetupHandler);

			createEntityViews();

			board.triggers.addEventListener(BattleBoardTriggersEvent.ADDED, battleBoardTriggersAddedHandler);
			board.triggers.addEventListener(BattleBoardTriggersEvent.REMOVED, battleBoardTriggersRemovedHandler);

			addParties();
			boardEnabledHandler(null);
		}

		private function boardPosHandler(event : Event) : void
		{
			setPosition(board.def.pos.x, board.def.pos.y);
		}

		public function update(delta : int) : void
		{
			phantasmsView.update(delta);

			for each (var ev : EntityView in this.entityViews)
			{
				ev.update(delta);
			}
		}

		private function boardSetupHandler(event : BattleBoardEvent) : void
		{
			if (board.scene.context.staticSoundController != null)
			{
				board.scene.context.staticSoundController.playSound("ui_match_start", null);
			}
			board.removeEventListener(BattleBoardEvent.BOARDSETUP, boardSetupHandler);
		}

		private var parties : Vector.<IBattleParty> = new Vector.<IBattleParty>;

		private function addParties() : void
		{
			for (var i : int = parties.length; i < board.numParties; ++i)
			{
				var party : IBattleParty = board.getParty(board.numParties - 1);
				parties.push(party);
				party.addEventListener(BattlePartyEvent.DEPLOYED, partyDeployedHandler);
			}
		}

		private function boardPartyHandler(event : BattleBoardEvent) : void
		{
			addParties();
		}

		private function partyDeployedHandler(event : BattlePartyEvent) : void
		{
			if (event.party.deployed)
			{
				board.scene.context.staticSoundController.playSound("ui_deploy", null);
				event.party.removeEventListener(BattlePartyEvent.DEPLOYED, partyDeployedHandler);
			}
		}

		public function cleanup() : void
		{
			// todo cleanup overlay/underlays?

			board.def.removeEventListener(BattleBoardDef.EVENT_POS, boardPosHandler);

			phantasmsView.cleanup();
			phantasmsView = null;

			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);

			board.triggers.removeEventListener(BattleBoardTriggersEvent.ADDED, battleBoardTriggersAddedHandler);
			board.triggers.removeEventListener(BattleBoardTriggersEvent.REMOVED, battleBoardTriggersRemovedHandler);

			board.removeEventListener(BattleBoardEvent.BOARDSETUP, boardSetupHandler);
			board.removeEventListener(BattleEntityEvent.ADDED, entityAddedHandler);
			board.removeEventListener(BattleEntityEvent.REMOVED, entityRemovedHandler);
			board.tiles.removeEventListener(TilesEvent.TILE_FLYTEXT, tileFlytextHandler);

			movieClipPool.cleanup();
			movieClipPool = null;

			bitmapPool.cleanup();
			bitmapPool = null;

			animClipSpritePool.cleanup();
			animClipSpritePool = null;

			for each (var party : IBattleParty in parties)
			{
				party.removeEventListener(BattlePartyEvent.DEPLOYED, partyDeployedHandler);
			}

			party = null;

		}

		override public function toString() : String
		{
			return board.toString();
		}

		protected function boardEnabledHandler(event : BattleBoardEvent) : void
		{
			board.logger.debug("BattleBoardView.boardEnabledHandler " + board.enabled);

			this.visible = board.enabled;
			// todo: spin through all the child views, entity views, etc. and (dis/en)able them
		}

		public function get isoDisplayObject() : IsoView
		{
			return isoView;
		}

		private var tileFlyText : Dictionary = new Dictionary;

		protected function tileFlytextHandler(event : TilesEvent) : void
		{
			var tile : Tile = board.tiles.flyTextTile;
			var flyText : EntityFlyText = tileFlyText[tile];
			if (!flyText)
			{
				// todo: these stay around, up to 1 per tile.  we might want to pool them and not leave the stales around 
				flyText = new EntityFlyText(null, tile);
				flyText.moveTo(tile.x * units, tile.y * units, 0);
				isoScenes.getIsoScene("fg0").addChild(flyText);
				tileFlyText[tile] = flyText;
			}

			flyText.push(board.tiles.flyText, board.tiles.flyTextColor, board.tiles.flyTextFontName, board.tiles.flyTextFontSize);
		}

		public function getIsoPointUnderMouse(sx : Number, sy : Number) : Pt
		{
			var pt_view : Point = isoView.globalToLocal(new Point(sx, sy));
			return isoView.localToIso(new Pt(pt_view.x, pt_view.y));
		}

		public function getTileLocationUnderMouse(sx : Number, sy : Number) : TileLocation
		{
			var pt : Pt = getIsoPointUnderMouse(sx, sy);

			if (!pt)
			{
				return null;
			}

			return TileLocation.fetch(Math.floor(pt.x / units), Math.floor(pt.y / units));
		}

		public function getScreenPoint(isoX : Number, isoY : Number) : Pt
		{
			var iso : Pt = new Pt(isoX, isoY);
			return IsoMath.isoToScreen(iso);
		}

		public function getScreenPointGlobal(isoX : Number, isoY : Number) : Point
		{
			var screen : Pt = getScreenPoint(isoX, isoY);
			var global : Point = isoDisplayObject.mainContainer.localToGlobal(screen);
			return global;
		}

		public function getCombatEntityViewOnTileAt(isoPoint : Pt, ignore : BattleEntity) : EntityView
		{
			for (var i : int = 0; i < isoScenes.getIsoScene("main0").numChildren; ++i)
			{
				var n : INode = isoScenes.getIsoScene("main0").getChildAt(isoScenes.getIsoScene("main0").numChildren - 1 - i);

				var ev : EntityView = n as EntityView;

				if (!ev)
				{
					continue;
				}

				if (ignore == ev.entity)
				{
					continue;
				}

				if (ev)
				{
					if (ev.isoBounds.containsPt(isoPoint))
					{
						return ev;
					}
				}
			}

			return null;
		}

		public function getCombatEntityViewUnderMouse(sx : Number, sy : Number, ignore : BattleEntity) : EntityView
		{
			// these children are already sorted in increasing distance from camera
			for (var i : int = 0; i < isoScenes.getIsoScene("main0").numChildren; ++i)
			{
				var n : INode = isoScenes.getIsoScene("main0").getChildAt(isoScenes.getIsoScene("main0").numChildren - 1 - i);

				var ev : EntityView = n as EntityView;

				if (!ev)
				{
					continue;
				}

				if (ignore == ev.entity)
				{
					continue;
				}

				if (ev && ev.entity.collidable)
				{
					if (ev.hitTestPoint(sx, sy))
					{
						return ev;
					}
				}
			}

			return null;
		}

		private function createEntityViews() : void
		{
			for each (var ent : BattleEntity in board.entities)
			{
				createEntityView(ent);
			}
		}

		private function createEntityView(ent : BattleEntity) : EntityView
		{
			var view : EntityView = EntityViewFactory.create(this, ent, board.resman);
			isoScenes.getIsoScene("main0").addChild(view);

			//view.showBoundingBox = true;

			entityViews[view.entity.id] = view;
			entityViewsByDefId[view.entity.def.id] = view;

			return view;
		}

		protected function entityAddedHandler(event : BattleEntityEvent) : void
		{
			createEntityView(event.entity);
		}

		protected function entityRemovedHandler(event : BattleEntityEvent) : void
		{
			var view : EntityView = getEntityView(event.entity);

			if (!view)
			{
				return;
			}

			isoScenes.getIsoScene("main0").removeChild(view);
			view.cleanup();
			delete entityViews[event.entity.id];
			delete entityViewsByDefId[event.entity.def.id];
		}

		private function enterFrameHandler(event : Event) : void
		{
			isoScenes.render();
			isoView.render();
			underlay.render();
			damageFlagOverlay.render();
			moveOverlay.render();
			abilityDestinationOverlay.render();
			//markerOverlay.render();
		}

		public function getEntityView(entity : IBattleEntity) : EntityView
		{
			if (entity)
			{
				return entityViews[entity.id];
			}
			else
			{
				return null;
			}
		}

		override protected function resizeHandler() : void
		{
			super.resizeHandler();

		}

		public function onEntityViewReady(ev : EntityView) : void
		{
			// nothing much to do with this at this point...
		}

		public function getEntityScenePoint(ent : IBattleEntity) : Point
		{
			if (ent)
			{
				var v : EntityView = getEntityView(ent);
				if (v)
				{
					return getScenePoint(v.x, v.y);
				}
			}

			return null;
		}

		public function getScenePoint(isoX : Number, isoY : Number) : Point
		{
			var sp : Point = getScreenPoint(isoX, isoY);
			sp.x += sceneOffset.x + x;
			sp.y += sceneOffset.y + y;
			return sp;
		}

		public function centerOnEntity(ent : IBattleEntity) : void
		{
			var ap : Point = getEntityScenePoint(ent);
			board.scene.camera.drift.anchor = ap;
		}

		public function centerOnPartyById(id : String) : void
		{
			var party : IBattleParty = board.getPartyById(id);
			if (party)
			{
				var c : Point;
				var count : int;
				for (var i : int = 0; i < party.numMembers; ++i)
				{
					var e : IBattleEntity = party.getMember(i);
					var ap : Point = getEntityScenePoint(e);
					if (ap)
					{
						if (!c)
						{
							c = new Point(ap.x, ap.y);
						}
						else
						{
							c.x += ap.x;
							c.y += ap.y;
						}
						++count;
					}
				}

				if (c && count)
				{
					c.x /= count;
					c.y /= count;

					if (c)
					{
						board.scene.camera.drift.anchor = c;
					}
				}
			}

		}

		public function setSceneOffset(sox : Number, soy : Number) : void
		{
			sceneOffset.setTo(sox, soy);
		}

		public function showInfoBanner(ent : IBattleEntity) : void
		{
			_showInfoEntity = ent;

			updateInfoBanners();
		}

		public function updateInfoBanners() : void
		{
			for each (var entityView : EntityView in this.entityViews)
			{
				var show : Boolean = entityView.entity.alive && entityView.entity.mobile && (_showHelp || _showInfoEntity == entityView.entity);
				entityView.showBattleInfoBanner(show);
			}
		}

		private var _showInfoEntity : IBattleEntity;
		private var _showHelp : Boolean;

		public function set showHelp(value : Boolean) : void
		{
			_showHelp = value;
			updateInfoBanners();
		}

		private function shellCmdFuncOverlay(c : CmdExec) : void
		{

		}

		private function shellCmdFuncUnderlay(c : CmdExec) : void
		{

		}

		private function shellCmdFuncEntities(c : CmdExec) : void
		{

		}

		private function battleBoardTriggersRemovedHandler(event : BattleBoardTriggersEvent) : void
		{
			var view : BattleBoardTriggerView = triggerViews[event.trigger];
			if (view)
			{
				delete triggerViews[event.trigger];
				view.cleanup();
			}
		}

		private function battleBoardTriggersAddedHandler(event : BattleBoardTriggersEvent) : void
		{
			var view : BattleBoardTriggerView = new BattleBoardTriggerView(this, event.trigger, this.board.logger, SMOOTH_TRIGGER_VIEWS);
			triggerViews[event.trigger] = view;
		}

		public function handleSpeak(event : SpeakEvent, anchor : String) : Boolean
		{
			var ev : EntityView;

			if (event.speaker)
			{
				ev = entityViewsByDefId[event.speaker.id];
			}
			else if (anchor)
			{
				const prefix : String = "battle.";
				if (anchor.indexOf(prefix) == 0)
				{
					var rest : String = anchor.substr(prefix.length);

					ev = entityViews[rest];
					if (!ev)
					{
						ev = entityViewsByDefId[rest];
					}
				}
			}

			if (ev)
			{
				var b : MovieClip = board.scene.context.createSpeechBubble(event);
				if (b)
				{
					var sp : Point = new Point(ev.screenX, ev.screenY);
					b.x = sp.x;
					b.y = sp.y - ev.height;
					addChild(b);
				}
				return true;
			}

			return false;

		}

	}
}

