package engine.battle.entity.view
{
	import com.dncompute.graphics.ArrowStyle;

	import flash.display.Bitmap;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;

	import as3isolib.data.INode;
	import as3isolib.display.IsoGroup;
	import as3isolib.display.IsoSprite;
	import as3isolib.display.scene.IsoScene;
	import as3isolib.geom.IsoMath;
	import as3isolib.geom.Pt;

	import engine.ability.IAbilityDef;
	import engine.anim.AnimDispatcherEvent;
	import engine.anim.def.AnimClipDef;
	import engine.anim.event.AnimControllerEvent;
	import engine.anim.view.AnimClip;
	import engine.anim.view.AnimClipSprite;
	import engine.anim.view.AnimControllerSprite;
	import engine.battle.CombatColors;
	import engine.battle.ability.event.TargetAnimEvent;
	import engine.battle.ability.phantasm.def.VfxSequenceDef;
	import engine.battle.ability.phantasm.model.VfxSequence;
	import engine.battle.board.view.BattleBoardView;
	import engine.battle.board.view.indicator.BoundingBoxHelper;
	import engine.battle.board.view.indicator.EntityBattleInfoFlag;
	import engine.battle.board.view.indicator.EntityFlyText;
	import engine.battle.board.view.phantasm.VfxSequenceView;
	import engine.battle.def.IsoAnimLibraryResource;
	import engine.battle.def.IsoVfxLibraryResource;
	import engine.battle.entity.model.BattleEntity;
	import engine.battle.entity.model.BattleEntityEvent;
	import engine.core.util.MovieClipUtil;
	import engine.entity.def.EntityIconType;
	import engine.entity.def.IEntityAppearanceDef;
	import engine.resource.AnimClipResource;
	import engine.resource.BitmapResource;
	import engine.resource.MovieClipResource;
	import engine.resource.ResourceGroup;
	import engine.resource.ResourceManager;
	import engine.resource.event.ResourceLoadedEvent;
	import engine.sound.def.SoundLibraryResource;
	import engine.sound.view.ISound;
	import engine.stat.def.StatType;
	import engine.stat.model.StatEvent;
	import engine.vfx.VfxDef;
	import engine.vfx.VfxLibrary;

	public class EntityView extends IsoGroup
	{
		public static const CAMERA_DIR : Point = new Point(Math.SQRT1_2, Math.SQRT1_2);
		protected static const ISO_W_PCT : Number = 0.4;

		public var entity : BattleEntity;
		public var sceneView : BattleBoardView;
		private var _boundingBoxHelper : BoundingBoxHelper;
		private var _ready : Boolean;

		public var alr : IsoAnimLibraryResource;
		public var slr : SoundLibraryResource;
		public var vlr : IsoVfxLibraryResource;

		public var playedDeathAnim : Boolean;

		// iso support
		public var isoSprite : IsoSprite;

		// tutorial support
		public var iso : DisplayObjectContainer;

		// render support
		public var shadowBitmapResource : BitmapResource;

		// renderables
		public var battleInfoFlag : EntityBattleInfoFlag;
		private var flyText : EntityFlyText;
		public var shadowBitmap : Bitmap;
		public var animSprite : AnimControllerSprite;
		public var indicator : TargetIndicatorSprite;
		private var goAnimationRes : MovieClipResource;
		private var goAnimation : MovieClipUtil;
		private var goAnimationIso : IsoSprite;
		private var propAnimClipResource : AnimClipResource = null;
		private var propAnimClipSprite : AnimClipSprite = null;

		private var resourceGroup : ResourceGroup = new ResourceGroup;

		private var enoughKillsVfxAcr : AnimClipResource;
		private var enoughKillsVfxIsoSprite : IsoSprite;

		private static const SMOOTH_ENTITY_VIEWS : Boolean = false;

		public function EntityView(sceneView : BattleBoardView, entity : BattleEntity, resman : ResourceManager)
		{
			super("view_" + entity.id);

			this.sceneView = sceneView;
			this.entity = entity;

			this.animSprite = new AnimControllerSprite(entity.def.id, entity.animController, sceneView.board.logger, sceneView.board.resman, SMOOTH_ENTITY_VIEWS);

			configureSprites();

			loadAssets(resman);

			updatePosition();

			this.battleInfoFlag = new EntityBattleInfoFlag(this);
			battleInfoFlag.moveTo(width / 2, length / 2, battleInfoFlag.z);
			addChild(battleInfoFlag);

			entity.addEventListener(BattleEntityEvent.ALIVE, entityAliveHandler);
			entity.addEventListener(BattleEntityEvent.FLY_TEXT, entityFlyTextHandler);
			entity.addEventListener(BattleEntityEvent.GO_ANIMATION, entityGoAnimationHandler);
			entity.addEventListener(BattleEntityEvent.ENOUGH_KILLS_TO_PROMOTE_VFX, playEnoughKillsToPromoteVfx);
			animSprite.controller.addEventListener(AnimControllerEvent.EVENT, onAnimEvent);
			entity.addEventListener(BattleEntityEvent.ENABLED, enabledHandler);

			// setup helpers
			_boundingBoxHelper = new BoundingBoxHelper(isoSprite, this);

			//shadow

			if (entity.mobile == true)
			{
				entity.stats.getStat(StatType.STRENGTH).addEventListener(StatEvent.BASE_CHANGE, strengthBaseChangeHandler);
				entity.stats.getStat(StatType.ARMOR).addEventListener(StatEvent.BASE_CHANGE, armorBaseChangeHandler);

				entity.addEventListener(BattleEntityEvent.MISSED, entityMissedHandler);
				entity.addEventListener(BattleEntityEvent.RESISTED, entityResistedHandler);
			}

			enabledHandler(null);

			entity.animEventDispatcher.addEventListener(TargetAnimEvent.EVENT, animEvent);

//			showBoundingBox = true;
		}

		private function loadAssets(resman : ResourceManager) : void
		{
			var entityClassAppearanceDef : IEntityAppearanceDef = entity.def.appearance;

			if (entityClassAppearanceDef.animsUrl)
			{
				alr = resman.getResource(entityClassAppearanceDef.animsUrl, IsoAnimLibraryResource, resourceGroup) as IsoAnimLibraryResource;
				alr.addResourceListener(animSetDefResourceComplete);
			}

			if (entityClassAppearanceDef.vfxUrl)
			{
				vlr = resman.getResource(entityClassAppearanceDef.vfxUrl, IsoVfxLibraryResource, resourceGroup) as IsoVfxLibraryResource;
			}

			if (entityClassAppearanceDef.soundsUrl)
			{
				slr = resman.getResource(entityClassAppearanceDef.soundsUrl, SoundLibraryResource, resourceGroup) as SoundLibraryResource;
				if (!slr.loaded)
				{
					slr.addEventListener(Event.COMPLETE, soundLibraryResourceCompleteHandler);
				}
				else
				{
					soundLibraryResourceCompleteHandler(null);
				}
			}

			if (entity.def.entityClass.propAnimUrl)
			{
				propAnimClipResource = resman.getResource(entity.def.entityClass.propAnimUrl, AnimClipResource, resourceGroup) as AnimClipResource;
				propAnimClipResource.addResourceListener(propAnimClipResourceCompleteHandler);
			}

			var initOrderUrl : String = entityClassAppearanceDef.getIconUrl(EntityIconType.INIT_ORDER);
			if (initOrderUrl.length > 0)
			{
				resman.getResource(initOrderUrl, BitmapResource, resourceGroup);
			}

			var initActiveUrl : String = entityClassAppearanceDef.getIconUrl(EntityIconType.INIT_ACTIVE);
			if (initActiveUrl.length > 0)
			{
				resman.getResource(initActiveUrl, BitmapResource, resourceGroup);
			}

			for (var i : int = 0; i < entity.def.actives.numAbilities; ++i)
			{
				var active : IAbilityDef = entity.def.actives.getAbilityDef(i);
				if (active.iconUrl)
				{
					resman.getResource(active.iconUrl, BitmapResource, resourceGroup);
				}
				if (active.iconBuffUrl)
				{
					resman.getResource(active.iconBuffUrl, BitmapResource, resourceGroup);
				}
			}

			if (entity.width == 2)
			{
				shadowBitmapResource = resman.getResource("common/battle/tile/four_tile_shadow.png", BitmapResource, resourceGroup) as BitmapResource;
			}
			else
			{
				shadowBitmapResource = resman.getResource("common/battle/tile/one_tile_shadow.png", BitmapResource, resourceGroup) as BitmapResource;
			}
			shadowBitmapResource.addResourceListener(onShadowLoaded);

			goAnimationRes = resman.getResource("common/battle/vfx/go_spear.swf/go_spear", MovieClipResource, resourceGroup) as MovieClipResource;
			goAnimationRes.addResourceListener(onGoAnimationLoad);
		}

		public function animEvent(event : TargetAnimEvent) : void
		{
			var battleEntity : BattleEntity = entity as BattleEntity;
			var soundName : String;

			if (event.eventId == "footstep_left" || event.eventId == "footstep_right")
			{
				soundName = "footstep";
			}
			else if (event.eventId.indexOf("foley_") == 0)
			{
				soundName = event.eventId;
			}
			else if (event.eventId.indexOf("^") == 0)
			{
				soundName = event.eventId.substr(1);
			}

			if (soundName && sceneView.soundDriver.system.sfxEnabled)
			{
				const sound : ISound = battleEntity.soundController.playSound(soundName, null);
				if (!sound)
				{
					sceneView.board.scene.context.animDispatcher.dispatchEvent(new AnimDispatcherEvent(AnimDispatcherEvent.SOUND_ERROR, battleEntity, soundName, null, null));
				}
			}

		}

		private function entityResistedHandler(event : BattleEntityEvent) : void
		{
			showFlyText("RESIST", CombatColors.MISS, "Vinque", 20);
		}

		private function entityMissedHandler(event : BattleEntityEvent) : void
		{
			//showFlyText("MISS", CombatColors.MISS, "Minion Pro", 20);
			showFlyText("MISS", CombatColors.MISS, "Vinque", 20);
		}

		private function armorBaseChangeHandler(event : StatEvent) : void
		{
			if (event.delta < 0)
			{
				showFlyText((-event.delta).toString(), CombatColors.DAMAGE_ARMOR, "Vinque", 39);
			}
		}

		private function strengthBaseChangeHandler(event : StatEvent) : void
		{
			if (event.delta < 0)
			{
				showFlyText((-event.delta).toString(), CombatColors.DAMAGE_STRENGTH, "Vinque", 39);
			}
		}

		public function showBattleInfoBanner(show : Boolean) : void
		{
			if (!battleInfoFlag || !battleInfoFlag.guiInfoFlag)
			{
				return;
			}

			if (show)
			{
				battleInfoFlag.guiInfoFlag.setEntityAndStats(this.entity.stats, this.entity.isPlayer);
			}
			else
			{
				battleInfoFlag.guiInfoFlag.setEntityAndStats(null, true);

			}
		}

		private function entityAliveHandler(event : BattleEntityEvent) : void
		{
			if (!entity.alive)
			{
				playDeathAnim("die");

				if (!entity.playerControlled || entity.team == "npc")
				{
					playRenownVfx(entity.def.killRenown);
				}
			}
		}

		public function playDeathAnim(animName : String) : void
		{
			//entity.logger.debug("playDeathAnim: " + entity.id + " " + animName + " played=" + playedDeathAnim);
			if (!playedDeathAnim)
			{
				playedDeathAnim = true;
				animSprite.controller.ambientMix = null;
				animSprite.controller.playAnim(animName, 1, true);
				
				//entity.logger.debug("playDeathAnim: PLAYED " + entity.id + " " + animName);
			}
		}

		private var vfxs : Vector.<VfxSequenceView> = new Vector.<VfxSequenceView>;

		protected function playRenownVfx(num : int) : void
		{

			if (sceneView.board.sim.fsm.battleCreateData && sceneView.board.sim.fsm.battleCreateData.friendly)
			{
				return;
			}

			var vfxLibrary : VfxLibrary = getVfxLibrary();

			if (vfxLibrary != null)
			{

				const vfxName : String = "earn_" + num + "_renown";

				var vfxDef : VfxDef = vfxLibrary.getVfxDef(vfxName);
				if (vfxDef != null)
				{
					const vsd : VfxSequenceDef = new VfxSequenceDef();
					vsd.start = vfxName;
					vsd.id = "tmp_renown";

					const vfx : VfxSequence = new VfxSequence(vsd, sceneView.board.resman, vfxLibrary, sceneView.board.logger, 0, null);

					playVfx(vfx, 0, 0, false, null, 0, false);
				}
			}
		}

		private function transientVfxCompleteHandler(event : Event) : void
		{
			const vfx : VfxSequenceView = event.target as VfxSequenceView;
			if (vfx)
			{
				if (vfx.parent)
				{
					vfx.parent.removeChild(vfx);
				}

				const i : int = vfxs.indexOf(vfx);
				vfxs.splice(i, 1);
			}
		}

		protected function playEnoughKillsToPromoteVfx(event : BattleEntityEvent) : void
		{
			if (!entity.playerControlled)
			{
				return;
			}

			var vfxLibrary : VfxLibrary = getVfxLibrary();

			if (vfxLibrary != null)
			{

				const vfxName : String = "earn_promote";

				var vfxDef : VfxDef = vfxLibrary.getVfxDef(vfxName);
				if (vfxDef != null)
				{
					const url : String = vfxDef.getClipUrl(0);
					enoughKillsVfxAcr = vfxLibrary.getAnimClipResource(url);

					enoughKillsVfxIsoSprite = new IsoSprite("roa");

					sceneView.isoScenes.getIsoScene("main0").addChild(enoughKillsVfxIsoSprite);

					var tg : Pt;
					tg = new Pt(this.x + this.width / 2, this.y + this.length / 2, this.z);

					playSpriteTowards(this, tg, this.z + this.height / 2, enoughKillsVfxIsoSprite, enoughKillsVfxAcr, enoughKillsVfxCompleteHandler);

					checkEnoughKillsVfxWaits();
				}
			}
		}

		private function enoughKillsVfxCompleteHandler(mcu : MovieClipUtil) : void
		{
			if (enoughKillsVfxIsoSprite)
			{
				var index : int = enoughKillsVfxIsoSprite.sprites.indexOf(mcu.mc);

				if (index >= 0)
				{
					enoughKillsVfxIsoSprite.sprites.splice(index, 1);
					enoughKillsVfxIsoSprite.invalidateSprites();
					checkEnoughKillsVfxWaits();
				}
			}
		}

		private function checkEnoughKillsVfxWaits() : void
		{
			if (enoughKillsVfxIsoSprite)
			{
				if (enoughKillsVfxIsoSprite.sprites.length == 0)
				{
					if (enoughKillsVfxIsoSprite.parent)
					{
						enoughKillsVfxIsoSprite.parent.removeChild(enoughKillsVfxIsoSprite);
					}
					enoughKillsVfxIsoSprite = null;
				}
			}
		}

		private function playVfx(vfx : VfxSequence, x : Number, y : Number, asChild : Boolean, toward : BattleEntity, height : Number, reverse : Boolean = false) : void
		{

			var u : Number = sceneView.units;
			var hw : Number = 0.5;
			var hl : Number = 0.5;

			if (reverse)
			{
				vfx.scaleX *= -1;
			}

			const vsv : VfxSequenceView = new VfxSequenceView(vfx, sceneView.board.logger, false);

			//isoSprite.moveTo((x + hw) * u, (y + hl) * u, height);

			if (asChild)
			{
				isoSprite.addChildAt(vsv, isoSprite.numChildren);
				vsv.x = vsv.y = isoSprite.width;
			}
			else
			{
				const sc : IsoScene = sceneView.isoScenes.getIsoScene("main0");
				sc.addChild(vsv);
				vsv.x = (entity.x + entity.width) * u;
				vsv.y = (entity.y + entity.length) * u;
			}

			vsv.addEventListener(VfxSequenceView.EVENT_CLIP_FINISHED, transientVfxCompleteHandler);

			vfxs.push(vsv);
		}

		protected function playSpriteTowards(a : EntityView, target : Pt, height : Number, isoSprite : IsoSprite, animClipResource : AnimClipResource, vfxCompleteHandler : Function) : void
		{
			if (!animClipResource)
			{
				sceneView.board.logger.error("EntityView.playSpriteTowards " + a + " requires an AnimClipResource");
				return;
			}
			var dir : Point;

			var hs : Point = new Point(a.width / 2, a.length / 2);
			var ap : Point = new Point(a.x + hs.x, a.y + hs.y);

			if (target != null)
			{
				dir = new Point(target.x - ap.x, target.y - ap.y);
				dir.normalize(1.0);
			}
			else
			{
				dir = CAMERA_DIR;
			}

			var d : DisplayObject = (animClipResource && animClipResource.movieClipResource) ? animClipResource.movieClipResource.movieClip : null;
			d.name = "sprite_" + (animClipResource ? animClipResource.url : "?");

			if (d == null)
			{
				sceneView.board.logger.error("EntityView.playSpriteTowards: No movieClipResource found on " + animClipResource.url);
				return;
			}

			if (d is MovieClip)
			{
				var mcu : MovieClipUtil = new MovieClipUtil(d as MovieClip, sceneView.board.logger);

				mcu.playOnce(vfxCompleteHandler);
			}

			var s : Number = sceneView.units / 100;
			var o : Number = Math.sqrt(hs.x * hs.x + hs.y * hs.y) + s * 2;

			var o_vis : Number = Math.sqrt(hs.x * hs.x + hs.y * hs.y) / 16;

			isoSprite.setSize(s, s, s);

			var isoPt : Pt = new Pt(ap.x + dir.x * o, ap.y + dir.y * o, height);
			isoSprite.moveTo(isoPt.x, isoPt.y, isoPt.z);

			var visPt : Pt = new Pt(ap.x + dir.x * o_vis, ap.y + dir.y * o_vis, height);

			var screen_o : Pt = IsoMath.isoToScreen(isoPt);
			var screen_v : Pt = IsoMath.isoToScreen(visPt);

			d.x = screen_v.x - screen_o.x;
			d.y = screen_v.y - screen_o.y;

			isoSprite.sprites = [d];
		}

		private function enabledHandler(event : BattleEntityEvent) : void
		{
			this.isoSprite.container.visible = entity.enabled;
		}

		private function onGoAnimationLoad(event : ResourceLoadedEvent) : void
		{
			if (goAnimationRes.ok)
			{
				var mc : MovieClip = goAnimationRes.movieClip;
				goAnimation = new MovieClipUtil(mc, entity.logger);
				goAnimation.visible = false;
				goAnimation.stop();
				goAnimationIso = new IsoSprite("go");
				goAnimationIso.container.mouseEnabled = false;
				goAnimationIso.container.mouseChildren = false;
				goAnimationIso.sprites = [mc];
			}
		}

		private function onShadowLoaded(event : ResourceLoadedEvent) : void
		{
			shadowBitmapResource.removeResourceListener(onShadowLoaded);

			if (!event.resource.ok)
			{
				return;
			}

			shadowBitmap = shadowBitmapResource.bmp;
			shadowBitmap.name = "shadow";
			shadowBitmap.blendMode = BlendMode.MULTIPLY;
			shadowBitmap.x = -1 * (shadowBitmap.width / 2);
//			var tileHeight : Number = entity.width * sceneView.units;
			shadowBitmap.y = (-shadowBitmap.height) / 2;

			shadowBitmap.y += isoSprite.width / 2;

			if (propAnimClipSprite == null)
			{
				isoSprite.sprites = [shadowBitmap, indicator, animSprite];
			}
			else
			{
				isoSprite.sprites = [shadowBitmap, indicator, animSprite, propAnimClipSprite];
			}

		}

		protected function animSetDefResourceComplete(event : Event) : void
		{
			this.animSprite.library = alr ? alr.library.variation(entity.def.appearanceIndex) : null;

			// move the whole frikkin group
			updatePosition();
		}

		protected function propAnimClipResourceCompleteHandler(event : ResourceLoadedEvent) : void
		{
			propAnimClipResource.removeEventListener(Event.COMPLETE, propAnimClipResourceCompleteHandler);
			if (propAnimClipResource.ok)
			{
				var acd : AnimClipDef = propAnimClipResource.clipDef;
				var ac : AnimClip = new AnimClip(acd, null, null, sceneView.board.logger);
				ac.start();
				propAnimClipSprite = new AnimClipSprite(ac, propAnimClipResource.movieClipResource, sceneView.board.logger, SMOOTH_ENTITY_VIEWS);

				propAnimClipSprite.x = 0;
				propAnimClipSprite.y = (entity.width * isoSprite.height / 2);

				isoSprite.sprites = [shadowBitmap, indicator, animSprite, propAnimClipSprite];
			}
		}

		public function getVfxLibrary() : VfxLibrary
		{
			if (vlr != null)
			{
				return vlr.library;
			}

			return null;
		}

		public function cleanup() : void
		{
			if (resourceGroup)
			{
				resourceGroup.release();
				resourceGroup = null;
			}

			entity.stats.getStat(StatType.STRENGTH).removeEventListener(StatEvent.BASE_CHANGE, strengthBaseChangeHandler);
			entity.stats.getStat(StatType.ARMOR).removeEventListener(StatEvent.BASE_CHANGE, armorBaseChangeHandler);
			entity.removeEventListener(BattleEntityEvent.MISSED, entityMissedHandler);
			entity.removeEventListener(BattleEntityEvent.RESISTED, entityResistedHandler);

			entity.animEventDispatcher.removeEventListener(TargetAnimEvent.EVENT, animEvent);
			entity.removeEventListener(BattleEntityEvent.ALIVE, entityAliveHandler);
			entity.removeEventListener(BattleEntityEvent.FLY_TEXT, entityFlyTextHandler);
			entity.removeEventListener(BattleEntityEvent.GO_ANIMATION, entityGoAnimationHandler);
			entity.addEventListener(BattleEntityEvent.ENOUGH_KILLS_TO_PROMOTE_VFX, playEnoughKillsToPromoteVfx);
			animSprite.controller.removeEventListener(AnimControllerEvent.EVENT, onAnimEvent);
			entity.removeEventListener(BattleEntityEvent.ENABLED, enabledHandler);
			shadowBitmapResource.removeResourceListener(onShadowLoaded);
			shadowBitmapResource.release();

			removeChild(isoSprite);
			isoSprite.sprites = [];
			animSprite.cleanup();
			animSprite = null;

			indicator.cleanup();
			indicator = null;

			if (alr)
			{
				alr.removeEventListener(Event.COMPLETE, animSetDefResourceComplete);
				alr.refcount.releaseReference();
			}

			updatePosition();

		}

		protected function soundLibraryResourceCompleteHandler(event : Event) : void
		{
			entity.soundController.library = slr ? slr.library : null;
		}

		private function configureSprites() : void
		{
			isoSprite = new IsoSprite(entity.id);
			iso = isoSprite.container;
			isoSprite.container.mouseEnabled = false;
			isoSprite.container.mouseChildren = false;

			addChild(isoSprite);

			if (!entity.def.id)
			{
				entity.logger.error("Cannot configure sprites for entity with null def id");
				return;
			}

			const u : Number = sceneView.units;
			const s : Number = ISO_W_PCT * entity.width;
			isoSprite.setSize(s * u, s * u, entity.height * u);

			// the anim sprite origin should be at the bottom of the visible tile!

			// now adjust it downwards to align with the center of the isoSprite
			animSprite.y += s * u / 2;

			// finally adjust it downwards to align with the bottom of his model's bounds           

			animSprite.y += entity.width * u / 2;

			indicator = new TargetIndicatorSprite(this, sceneView.board.sim.fsm, sceneView.units, sceneView.bitmapPool, sceneView.animClipSpritePool, sceneView.board.assets);

			// the indicator origin should be at the center of the tile!
			indicator.y = isoSprite.width / 2;

			isoSprite.sprites = [indicator, animSprite];

			setSize(isoSprite.width, isoSprite.length, isoSprite.height);

			ready = true;
		}

		private static const arrowStyle : ArrowStyle = new ArrowStyle(
			{
				headWidth: -1,
				headLength: 10,
				shaftThickness: 3,
				shaftPosition: 0,
				edgeControlPosition: .5,
				edgeControlSize: .5
			}
			);

		protected function showFlyText(str : String, color : uint, fontName : String, fontSize : int) : void
		{
			if (!flyText)
			{
				flyText = new EntityFlyText(this, null);

				const zOffset : Number = animSprite.height * 0.75;
				flyText.moveTo(x, y, z + zOffset);

				sceneView.isoScenes.getIsoScene("fg0").addChild(flyText);

			}

			flyText.push(str, color, fontName, fontSize);
		}

		private function entityGoAnimationHandler(event : BattleEntityEvent) : void
		{
			if (goAnimationIso.parent == null)
			{
				addChild(goAnimationIso);
			}
			goAnimation.visible = true;

			sceneView.board.scene.context.staticSoundController.playSound("ui_players_turn", null);
			goAnimation.playOnce(goAnimationCallback);
		}

		private function goAnimationCallback(mcu : MovieClipUtil) : void
		{
			if (goAnimation == mcu)
			{
				goAnimation.visible = false;
				removeChild(goAnimationIso);
			}
		}

		private function entityFlyTextHandler(event : BattleEntityEvent) : void
		{
			showFlyText(entity.flyText, entity.flyTextColor, entity.flyTextFontName, entity.flyTextFontSize);
		}

		public function hitTestPoint(sx : Number, sy : Number) : Boolean
		{

			for each (var sprite : DisplayObject in isoSprite.actualSprites)
			{
				if (sprite.hitTestPoint(sx, sy, true))
				{
					return true;
				}
			}

			return false;
		}

		public function onAnimEvent(event : AnimControllerEvent) : void
		{
			if (playedDeathAnim)
			{
				if (event.eventId == "*hold")
				{
					// dead, flat as a pancake

					height = 0;

					// adjust their z so that they stack in order killed
					this.z = this.z + entity.board.deathOffset;

					// visually counterbalance the z offset
					for (var i : int = 0; i < numChildren; ++i)
					{
						const node : INode = getChildAt(i);
						if (node)
						{
							var sprite : IsoSprite = node as IsoSprite;
							if (sprite)
							{
								sprite.container.y += entity.board.deathOffset;
							}
						}
					}

					const zDeathOffset : Number = 0.55;
					if (entity.board.deathOffset + zDeathOffset < 0)
					{
						entity.board.deathOffset = entity.board.deathOffset + zDeathOffset;
					}
				}
			}

			sceneView.board.scene.context.animDispatcher.dispatchEvent(new AnimDispatcherEvent(AnimDispatcherEvent.ANIM_EVENT, entity, event.controller.id, event.animId, event.eventId));

			//	entity.board.logger.debug("EntityView saw event: " + event);
			entity.animEventDispatcher.dispatchEvent(new TargetAnimEvent(TargetAnimEvent.EVENT, event.animId, event.eventId));
		}

		private var _showBoundingBox : Boolean;

		public function set showBoundingBox(value : Boolean) : void
		{
			if (_showBoundingBox == value)
			{
				return;
			}

			_showBoundingBox = value;
			_boundingBoxHelper.show = true;
		}

		public function toString() : String
		{
			return "[EntityView entity=" + entity + "]";
		}

		protected function updatePosition() : void
		{
			var u : Number = sceneView.units;
			var hw : Number = entity.width / 2;
			var hl : Number = entity.length / 2;
//			moveTo(u * (entity.x + entity.width / 2) - ISO_W / 2, u * (entity.y + entity.length / 2) - ISO_W / 2, z);

			var tx : Number = u * (entity.x + hw) - width / 2;
			var ty : Number = u * (entity.y + hl) - length / 2;
			moveTo(tx, ty, z);
			if (flyText)
			{
				const zOffset : Number = animSprite.height * 0.75;
				flyText.moveTo(x, y, z + zOffset);
			}
		}

		public function get ready() : Boolean
		{
			return _ready;
		}

		public function set ready(value : Boolean) : void
		{
			_ready = value;
			sceneView.onEntityViewReady(this);
		}

		public function get centerScreenPointGlobal() : Point
		{
			return sceneView.getScreenPointGlobal(x + width / 2, y + length / 2);
		}

		public function update(delta : int) : void
		{
			for each (var vsv : VfxSequenceView in vfxs)
			{
				vsv.vfx.update(delta);
				vsv.update(delta);
			}
		}
	}
}

