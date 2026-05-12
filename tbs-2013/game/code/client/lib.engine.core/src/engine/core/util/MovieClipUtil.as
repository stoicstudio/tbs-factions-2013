package engine.core.util
{
	import engine.core.logging.ILogger;

	import flash.display.DisplayObject;
	import flash.display.FrameLabel;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.utils.Dictionary;

	public class MovieClipUtil
	{
		private var _mc : MovieClip;
		private var start : int = -1;
		private var end : int = -1;
		private var _callback : Function;
		private var _looping : Boolean;
		public var logger : ILogger;
		public var prevFrame : int;
		private var labels : Dictionary;
		private var initFrame : *;

		public function MovieClipUtil(mc : MovieClip, logger : ILogger, initFrame : * = null)
		{
			mc.mouseEnabled = false;
			mc.mouseChildren = false;

			this._mc = mc;
			this.logger = logger;
			this.initFrame = initFrame;
			if (!logger)
			{
				throw new ArgumentError("no logger? shame.");
			}

			init();
		}

		public function get mc() : MovieClip
		{
			return _mc;
		}

		public function init() : void
		{
			//logger.info("MovieClipUtil.init " + mc.name);

			_mc.removeEventListener(Event.ENTER_FRAME, enterFrameHander);

			if (initFrame != null)
			{
				_mc.gotoAndStop(initFrame);
			}
			else
			{
				_mc.stop();
			}
		}

		public function cleanup() : void
		{
			//logger.info("MovieClipUtil.init " + mc.name);

			_mc.removeEventListener(Event.ENTER_FRAME, enterFrameHander);
			stop();
			_mc = null;
		}

		private function cacheLabels() : void
		{
			if (labels)
			{
				return;
			}

			labels = new Dictionary;

			for each (var fl : FrameLabel in _mc.currentLabels)
			{
				labels[fl.name] = fl.frame;
			}
		}

		public function getFrameAtLabel(label : String) : int
		{
			cacheLabels();

			var v : * = labels[label];
			if (v != undefined)
			{
				return int(v);
			}
			else
			{
				return -1;
			}
		}

		public function playLabelRange(start : String, end : String, callback : Function) : void
		{
			//logger.info("MovieClipUtil.playLabelRange " + mc.name + " " + start + " " + end);

			var s : int = getFrameAtLabel(start);
			var e : int = getFrameAtLabel(end);
			playRange(s, e, callback);
		}

		public function playRange(start : int, end : int, callback : Function) : void
		{
			//logger.info("MovieClipUtil.playRange " + mc.name + " " + start + " " + end);
			this._callback = callback;
			_mc.addEventListener(Event.ENTER_FRAME, enterFrameHander);
			this.start = start;
			if (end < 0)
			{
				end = _mc.framesLoaded;
			}
			this.end = end;
			prevFrame = start - 1;
			_mc.gotoAndPlay(start);
		}

		public function playOnce(callback : Function) : void
		{
			//logger.info("MovieClipUtil.playOnce");
			looping = false;
			playRange(1, _mc.framesLoaded, callback);
		}

		public function playLooping(callback : Function) : void
		{
			//logger.info("MovieClipUtil.playLooping");
			looping = true;
			playRange(1, _mc.framesLoaded, callback);
		}

		protected function enterFrameHander(event : Event) : void
		{
			//logger.info("MovieClipUtil.enterFrame " + mc.name + " " + mc.currentFrame);

//			if (!mc.isPlaying)
//			{
//				//mc.removeEventListener(Event.ENTER_FRAME, enterFrameHander);
//				logger.info("entered frame " + mc.name + " " + mc.currentFrame + " (" + mc.currentLabel + ") while not playing, end=" + end + " prev=" + prevFrame);
//			}

			if (_mc.currentFrame == end || prevFrame >= _mc.currentFrame)
			{
				if (looping)
				{
					_mc.gotoAndPlay(start);
				}
				else
				{
					stop();
				}

				if (_callback != null)
				{
					_callback(this);
				}
			}
		}

		public function get looping() : Boolean
		{
			return _looping;
		}

		public function set looping(value : Boolean) : void
		{
			//logger.info("MovieClipUtil.looping=" + value);

			_looping = value;
		}

		public function stop() : void
		{
			//logger.info("MovieClipUtil.stop");

			_mc.removeEventListener(Event.ENTER_FRAME, enterFrameHander);
			_mc.stop();
		}

		public function restart(callback : Function) : void
		{
			//logger.info("MovieClipUtil.restart");

			if (start < 0)
			{
				playRange(1, _mc.framesLoaded, callback);
			}
			else
			{
				playRange(start, end, callback);
			}
		}

		public function get complete() : Boolean
		{
			return !_mc.isPlaying || _mc.currentFrame == end;
		}

		public function get isPlaying() : Boolean
		{
			return _mc.isPlaying;
		}

		public function get visible() : Boolean
		{
			return _mc.visible;
		}

		public function set visible(value : Boolean) : void
		{
			//logger.info("MovieClipUtil.visible=" + value);

			_mc.visible = value;
		}

		public function getChildByName(name : String) : DisplayObject
		{
			return _mc.getChildByName(name);
		}

	}
}
