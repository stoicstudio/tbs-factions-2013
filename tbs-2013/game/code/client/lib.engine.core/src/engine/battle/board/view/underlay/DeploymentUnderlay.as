package engine.battle.board.view.underlay
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;

	import as3isolib.geom.IsoMath;
	import as3isolib.geom.Pt;

	import engine.battle.board.def.BattleDeploymentArea;
	import engine.battle.board.model.BattlePartyType;
	import engine.battle.board.model.IBattleEntity;
	import engine.battle.board.view.BattleBoardView;
	import engine.battle.board.view.EntityLinkedDirtyRenderSprite;
	import engine.battle.entity.model.BattleEntityEvent;
	import engine.battle.fsm.BattleFsmEvent;
	import engine.battle.fsm.state.BattleStateDeploy;
	import engine.battle.sim.BattlePartyEvent;
	import engine.battle.sim.IBattleParty;
	import engine.core.fsm.FsmEvent;
	import engine.resource.BitmapPool;
	import engine.tile.def.TileLocation;
	import engine.tile.def.TileLocationArea;

	public class DeploymentUnderlay extends EntityLinkedDirtyRenderSprite
	{
		private var pool : BitmapPool;

		public function DeploymentUnderlay(sceneView : BattleBoardView)
		{
			super(sceneView);

			pool = view.bitmapPool;

			fsm.addEventListener(FsmEvent.CURRENT, eventDirty);
			pool.addEventListener(Event.CHANGE, eventDirty);
			fsm.addEventListener(BattleFsmEvent.INTERACT, eventDirty);

			for each (var e : IBattleEntity in view.board.entities)
			{
				e.addEventListener(BattleEntityEvent.MOVED, eventDirty);
			}

			for each (var p : IBattleParty in view.board.parties)
			{
				p.addEventListener(BattlePartyEvent.DEPLOYED, eventDirty);
			}

			eventDirty(null);
		}

		override public function cleanup() : void
		{
			if (cleanedup)
			{
				return;
			}

			cleanedup = true;

			fsm.removeEventListener(FsmEvent.CURRENT, eventDirty);
			pool.removeEventListener(Event.CHANGE, eventDirty);
			fsm.removeEventListener(BattleFsmEvent.INTERACT, eventDirty);

			for each (var e : IBattleEntity in view.board.entities)
			{
				e.removeEventListener(BattleEntityEvent.MOVED, eventDirty);
			}

			for each (var p : IBattleParty in view.board.parties)
			{
				p.removeEventListener(BattlePartyEvent.DEPLOYED, eventDirty);
			}
		}

		private var rendered : Boolean;
		private var cleanedup : Boolean;

		protected function eventDirty(event : Event) : void
		{
			canRender = view.board.sim.fsm.currentClass == BattleStateDeploy;
			if (canRender)
			{
				rendered = true;
				setRenderDirty();
			}
			else if (view.underlay && view.underlay.tilesUnderlay)
			{
				if (rendered)
				{
					cleanup();
					view.underlay.tilesUnderlay.unhideAll(BIT);
				}
			}
		}

		public static const BIT : uint = TilesUnderlay.nextBit();

		override protected function onRender() : void
		{
			if (cleanedup)
			{
				throw new IllegalOperationError("Already cleaned up");
			}

			view.underlay.tilesUnderlay.unhideAll(BIT);
			var container : DisplayObjectContainer = this;

			while (container.numChildren > 0)
			{
				var d : DisplayObject = container.getChildAt(numChildren - 1);
				var b : Bitmap = d as Bitmap;
				if (b)
				{
					view.bitmapPool.reclaim(b);
				}
				container.removeChild(d);
			}

			var ch : IBattleEntity = fsm.interact;
			var deployment : BattleDeploymentArea;

			if (ch)
			{
				if (!ch.party.deployed)
				{
					// render only the location for the deployment character					
					deployment = view.board.def.getDeploymentAreaById(ch.party.deployment);
					if (deployment)
					{
						renderDeploymentArea(container, deployment.area, ch);
					}
				}
			}
			else
			{
				for (var i : int = 0; i < view.board.numParties; ++i)
				{
					var party : IBattleParty = view.board.getParty(i);

					if (party.type == BattlePartyType.LOCAL)
					{
						if (!party.deployed)
						{
							// render all local areas
							deployment = view.board.def.getDeploymentAreaById(party.deployment);
							if (deployment)
							{
								renderDeploymentArea(container, deployment.area, null);
							}
						}
					}
				}
			}
		}

		private function getMoveTile(loc : TileLocation) : String
		{
			var rs : int = int((loc.x + loc.y) / 2) * 2;
			var s : int = loc.x + loc.y;
			var even : Boolean = rs == s;
			if (even)
			{
				return view.board.assets.board_tile_move_a;
			}
			else
			{
				return view.board.assets.board_tile_move_b;
			}
		}

		private function renderDeploymentArea(container : DisplayObjectContainer, area : TileLocationArea, ch : IBattleEntity) : void
		{
			var pt : Pt = new Pt;
			for each (var loc : TileLocation in area.locations)
			{
				if (view.underlay.tilesUnderlay.isHiddenBit(loc.x, loc.y, BIT))
				{
					continue;
				}

				var bmp : Bitmap = null;

				pt.x = loc.x + 0.5;
				pt.y = loc.y + 0.5;

				var ct : IBattleEntity = view.board.findEntityOnTile(loc.x, loc.y, true, null);
				if (!ct)
				{
					var url : String = getMoveTile(loc);
					bmp = view.bitmapPool.pop(url) as Bitmap;
					view.underlay.tilesUnderlay.hide(loc.x, loc.y, BIT);
				}

				if (bmp)
				{
					container.addChild(bmp);
					var pt0 : Pt = IsoMath.isoToScreen(pt);
					var u : Number = view.units;

					bmp.x = pt0.x * u - bmp.width / 2;
					bmp.y = pt0.y * u - bmp.height / 2;
				}
			}
		}
	}
}
