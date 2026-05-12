package engine.battle.board.view.indicator
{
	import as3isolib.display.IsoSprite;

	import com.greensock.TweenMax;

	import engine.battle.entity.view.EntityView;
	import engine.tile.Tile;

	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;

	public class EntityFlyText extends IsoSprite
	{
		public static const DURATION : int = 2000;
		public static const MAX_ENTRIES : int = 4;
		private var entries : Vector.<FlyTextEntry> = new Vector.<FlyTextEntry>;
		private var popped : Vector.<FlyTextEntry> = new Vector.<FlyTextEntry>;
		private var timer : Timer = new Timer(1000, 1);
		private var slider : Sprite = new Sprite;
//		private var bottom : Number = 0;
		public var view : EntityView;
		public var tile : Tile;
		private var ids : int;

		public function EntityFlyText(view : EntityView, tile : Tile)
		{
			super("flytext");
			this.view = view;
			this.tile = tile;
			slider.mouseEnabled = false;
			slider.mouseChildren = false;
			container.mouseEnabled = false;
			container.mouseChildren = false;
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, timerCompleteHandler);
			sprites = [slider];
		}

		public function push(str : String, color : uint, fontName : String, fontSize : int) : void
		{
			var entry : FlyTextEntry = new FlyTextEntry(++ids, this, str, color, fontName, fontSize);

			slider.addChild(entry);

			entries.push(entry);
			entry.enter();

			popFirst();

			checkTimer();
		}

		public function toString() : String
		{
			return "EntityFlyText [view=" + view + ", tile=" + tile + ", entries=" + entries.length + "]";
		}

		public function flyTextEntryCompleteHandler(entry : FlyTextEntry) : void
		{
			const index : int = popped.indexOf(entry);
			if (index > 0)
			{
				popped.splice(index, 1);
			}
		}

		protected function timerCompleteHandler(event : TimerEvent) : void
		{
			popFirst();
			checkTimer();

			// if (entries.length == 0 && !timer.running)
			// we can potentially discard this fly text sprite
		}

		private function popFirst() : void
		{
			if (entries.length == 0)
			{
				return;
			}

			timer.stop();

			var entry : FlyTextEntry = entries[0];

			var blockleft : int = 0;
			var blockright : int = 0;

			for each (var pop : FlyTextEntry in popped)
			{
				if (pop.isOverlappingY(entry))
				{
					const margin : int = (pop.horizontalMargin + entry.horizontalMargin);
					blockleft = Math.min(blockleft, pop.x - margin);
					blockright = Math.max(blockright, pop.x + margin);
				}
			}

			if (Math.abs(blockleft) <= Math.abs(blockright))
			{
				entry.x = blockleft;
			}
			else
			{
				entry.x = blockright;
			}

			popped.push(entry);

			entry.depart();

			// pop next			
			entries.splice(0, 1);
		}

		private function checkTimer() : void
		{
			if (!timer.running)
			{
				if (entries.length > 0)
				{
					var entry : FlyTextEntry = entries[0];
					var now : int = getTimer();

					var remaining : int = Math.max(200, (entry.timestamp + DURATION) - now);
					timer.reset();
					timer.delay = remaining;
					timer.start();
				}
			}
		}
	}
}
import com.greensock.TweenMax;
import com.greensock.easing.Linear;
import com.greensock.easing.Strong;

import engine.battle.board.view.indicator.EntityFlyText;
import engine.gui.core.GuiLabel;
import engine.gui.core.GuiSprite;

import flash.filters.DropShadowFilter;
import flash.utils.getTimer;

class FlyTextEntry extends GuiSprite
{
	private var eft : EntityFlyText;
	public var timestamp : int;
	private var label : GuiLabel;
	private var entered : Boolean;
	private var shouldDepart : Boolean;
	public var horizontalMargin : int;
	public var verticalMargin : int;
	public var id : int

	public function FlyTextEntry(id : int, eft : EntityFlyText, str : String, color : uint, fontName : String, fontSize : int) : void
	{
		this.eft = eft;
		this.id = id;
		//label = new GuiLabel("Arial", 16, color);

		label = new GuiLabel(fontName, fontSize, color);
		addChild(label);

		mouseEnabled = false;
		mouseChildren = false;

		label.mouseEnabled = false;
		label.mouseChildren = false;

		timestamp = getTimer();
		label.text = str;
		label.sizeToContent();
		label.center();

		horizontalMargin = 16 + label.width / 2;
		verticalMargin = 8 + label.height / 2;

		//setSize(label.width, label.height);
		this.cacheAsBitmap = true;
		label.cacheAsBitmap = true;
		this.filters = [new DropShadowFilter(2, 122, 0x000000, 1, 1, 1, 1.5)];
	}

	override public function toString() : String
	{
		return "FlyTextEntry [id=" + id + ", label=" + label + ", timestamp=" + timestamp + ", pos=" + x + "," + y + ", margin=" + horizontalMargin + "," + verticalMargin + "]";
	}

	public function isOverlapping(rhs : FlyTextEntry) : Boolean
	{
		return Math.abs(this.x - rhs.x) < (this.horizontalMargin + rhs.horizontalMargin) &&
			Math.abs(this.y - rhs.y) < (this.verticalMargin + rhs.verticalMargin);
	}

	public function isOverlappingY(rhs : FlyTextEntry) : Boolean
	{
		return Math.abs(this.y - rhs.y) < (this.verticalMargin + rhs.verticalMargin);
	}

	public function set scale(value : Number) : void
	{
		scaleX = scaleY = value;
	}

	public function get scale() : Number
	{
		return scaleX;
	}

	public function enter() : void
	{
		alpha = 0;
		scale = 0;
		TweenMax.to(this,
			0.5,
			{scale: 1,
				alpha: 1,
				ease: Strong.easeOut
			});

		var ty : Number = label.y - 72;
		TweenMax.to(label,
			1,
			{y: ty,
				ease: Linear.easeOut,
				onComplete: enterCompleteHandler
			});
	}

	public function depart() : void
	{
		if (!entered)
		{
			shouldDepart = true;
			return;
		}
		TweenMax.to(this,
			2.0,
			{y: (y - 400),
				alpha: 0,
				ease: Linear.easeOut,
				onComplete: tweenCompleteHandler
			});
	}

	public function tweenCompleteHandler() : void
	{
		if (parent)
		{
			parent.removeChild(this);
				// all done
		}

		eft.flyTextEntryCompleteHandler(this);
	}

	public function enterCompleteHandler() : void
	{
		entered = true;
		if (shouldDepart)
		{
			depart();
		}
	}
}
