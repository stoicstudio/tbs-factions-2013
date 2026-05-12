package engine.battle.ability.phantasm.model
{
	import engine.anim.def.IAnimFacing;
	import engine.anim.view.AnimClip;
	import engine.battle.ability.phantasm.def.VfxSequenceDef;
	import engine.core.logging.ILogger;
	import engine.resource.AnimClipResource;
	import engine.resource.Resource;
	import engine.resource.ResourceManager;
	import engine.resource.event.ResourceLoadedEvent;
	import engine.vfx.VfxDef;
	import engine.vfx.VfxLibrary;

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;

	public class VfxSequence extends EventDispatcher
	{
		public var def : VfxSequenceDef;
		public var _stage : String;
		private var _clip : AnimClip;
		public var resources : Dictionary = new Dictionary;
		public var resource : AnimClipResource;
		private var logger : ILogger;
		private var elapsed : int;
		public var complete : Boolean;
		private var waits : int;
		private var lib : VfxLibrary;
		public var scaleX : Number = 1;
		private var _doEnd : Boolean;
		private var _facing : IAnimFacing;
		public var flip : Boolean;
		private var parameter : Number;
		private var finishedCallback : Function;

		public static const EVENT_CLIP_FINISHED : String = "VfxSequence.EVENT_CLIP_FINISHED";

		public function VfxSequence(def : VfxSequenceDef, resman : ResourceManager, lib : VfxLibrary, logger : ILogger, parameter : Number, facing : IAnimFacing = null, finishedCallback : Function = null)
		{
			this.def = def;
			this.logger = logger;
			this.lib = lib;
			this._facing = facing;
			this.parameter = parameter;
			this.finishedCallback = finishedCallback;

			loadClip("start", resman);
			loadClip("loop", resman);
			loadClip("end", resman);
		}

		public function cleanup() : void
		{
			complete = true;
			stage = null;

			for each (var r : Resource in resources)
			{
				if (r)
				{
					r.release();
				}
			}
			resources = null;

			def = null;
			lib = null;
		}

		override public function toString() : String
		{
			return "VfxSequence: [def=" + def + ", stage=" + _stage + ", clip=" + _clip + "]";
		}

		public function update(delta : int) : void
		{
			if (complete)
			{
				return;
			}

			elapsed += delta;

			if (elapsed < def.delay)
			{
				return;
			}

			if (waits > 0)
			{
				return;
			}

			if (_doEnd && _stage != "end")
			{
				stage = "end";
			}

			if (!_stage || (_clip && !_clip.playing) || !_clip)
			{
				nextStage();
				checkStage();
			}

			if (_clip && _clip.playing)
			{
				_clip.advance(delta);
			}
		}

		public function doEnd() : void
		{
			_doEnd = true;
		}

		private function loadClip(which : String, resman : ResourceManager) : void
		{
			const name : String = def[which];

			if (!name)
			{
				return;
			}

			const vd : VfxDef = (def.oriented == true) ? lib.getVfxDefByFacing(name, _facing) : lib.getVfxDef(name);
			if (!vd)
			{
				logger.error("No such VfxDef " + name);
				return;

			}
			this.flip = vd.flip;
			const index : int = vd.getIndex(parameter);
			const url : String = vd.getClipUrl(index);

			if (url)
			{
				var r : Resource = resources[which] = resman.getResource(url, AnimClipResource);
				++waits;
				r.addResourceListener(resourceCompleteHandler);
			}
			else
			{
				logger.error("VfxSequence.loadClip " + this + " No VFX URL for which=" + which + ", name=" + name);
			}
		}

		private function resourceCompleteHandler(event : ResourceLoadedEvent) : void
		{
			--waits;
		}

		public function set stage(value : String) : void
		{
			if (_stage == value)
			{
				return;
			}

			_stage = value;

			if (_clip)
			{
				// just hold prior clip until the next one is ready
				_clip.stop();
			}

			if (_stage)
			{
				resource = resources[_stage];
			}
			else
			{
				resource = null;
			}
			checkStage();
		}

		private function checkStage() : void
		{
			if (_stage)
			{
				if (!_clip)
				{
					if (resource)
					{
						clip = resource.clip;
					}
				}
				else if (resource)
				{
					if (_clip.def != resource.clipDef)
					{
						clip = resource.clip;
					}
				}
				else
				{
					clip = null;
				}
			}
			else
			{
				if (_clip)
				{
					clip = null;
				}
			}

		}

		private function nextStage() : void
		{

			if (_stage == null)
			{
				stage = "start";
			}
			else if (_stage == "start")
			{
				stage = "loop";
			}
			else if (_stage == "loop")
			{
				stage = "end";
			}
			else if (_stage == "end")
			{
				complete = true;
				stage = null;
			}

		}

		public function get clip() : AnimClip
		{
			return _clip;
		}

		public function set clip(value : AnimClip) : void
		{
			if (_clip == value)
			{
				return;
			}

			if (_clip)
			{
				_clip.finishedCallback = null;
				_clip.stop();
				_clip.cleanup();
			}

			_clip = value;

			if (_clip)
			{
				_clip.finishedCallback = clipFinishedHandler;
				_clip.start(0);
			}

			dispatchEvent(new Event(Event.CHANGE));
		}

		public function clipFinishedHandler(clip : AnimClip) : void
		{
			if (finishedCallback != null)
			{
				finishedCallback(this);
			}
			dispatchEvent(new Event(EVENT_CLIP_FINISHED));
		}
	}
}
