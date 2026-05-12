package engine.battle.board.view.phantasm
{
	import as3isolib.display.IsoSprite;

	import engine.anim.view.AnimClipSprite;
	import engine.battle.ability.phantasm.model.VfxSequence;
	import engine.core.logging.ILogger;

	import flash.events.Event;

	public class VfxSequenceView extends IsoSprite
	{
		public var vfx : VfxSequence;
		public var sprite : AnimClipSprite;
		public var logger : ILogger;
		public var smoothing : Boolean;

		public static const EVENT_CLIP_FINISHED : String = "VfxSequenceView.EVENT_CLIP_FINISHED";

		public function VfxSequenceView(vfx : VfxSequence, logger : ILogger, smoothing : Boolean)
		{
			super("vfx");
			this.vfx = vfx;
			this.logger = logger;
			this.smoothing = smoothing;
			vfx.addEventListener(Event.CHANGE, vfxChangeHandler);
			vfx.addEventListener(VfxSequence.EVENT_CLIP_FINISHED, clipFinishedHandler);

			vfxChangeHandler(null);
		}

		private function clipFinishedHandler(event : Event) : void
		{
			dispatchEvent(new Event(EVENT_CLIP_FINISHED));
		}

		public function cleanup() : void
		{
			if (sprite)
			{
				sprite.cleanup();
			}

			vfx.removeEventListener(Event.CHANGE, vfxChangeHandler);
			vfx.removeEventListener(VfxSequence.EVENT_CLIP_FINISHED, clipFinishedHandler);
		}

		private function vfxChangeHandler(event : Event) : void
		{

			if (vfx.clip)
			{
				sprite = new AnimClipSprite(vfx.clip, vfx.resource.movieClipResource, logger, smoothing);
				sprite.scaleX = vfx.scaleX;
				sprites = [sprite];

					// sprite is being driven by the VfxSequence AnimClip
			}
			else
			{
				sprite = null;
				sprites = [];
			}
		}

		public function update(delta : int) : void
		{
			if (sprite)
			{
				sprite.update();
			}
		}
	}
}
