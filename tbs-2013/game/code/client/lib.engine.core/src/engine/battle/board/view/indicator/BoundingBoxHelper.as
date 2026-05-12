package engine.battle.board.view.indicator
{
	import as3isolib.core.IsoContainer;
	import as3isolib.display.IsoSprite;
	import as3isolib.display.primitive.IsoBox;
	import as3isolib.enum.RenderStyleType;
	import as3isolib.graphics.SolidColorFill;

	public class BoundingBoxHelper
	{
		private var _show : Boolean;
		private var _boundingBox : IsoBox;
		private var _contains : IsoSprite;
		private var _container : IsoContainer;

		public function BoundingBoxHelper(_contains : IsoSprite, _container : IsoContainer)
		{
			this._contains = _contains;
			this._container = _container;
		}

		public function get show() : Boolean
		{
			return _show;
		}

		public function set show(value : Boolean) : void
		{
			if (_show == value)
			{
				return;
			}

			_show = value;

			if (_show)
			{
				_boundingBox = new IsoBox();
				_boundingBox.styleType = RenderStyleType.SHADED;
				_boundingBox.fills = [
					new SolidColorFill(0xff0000, .1),
					new SolidColorFill(0x00ff00, .1),
					new SolidColorFill(0x0000ff, .1),
					new SolidColorFill(0xff0000, .1),
					new SolidColorFill(0x00ff00, .1),
					new SolidColorFill(0x0000ff, .1)
					];

				_container.addChild(_boundingBox);
				updateBoundingBox();
			}
			else
			{
				if (_boundingBox)
				{
					_boundingBox.parent.removeChild(_boundingBox);
					_boundingBox = null;
				}
			}
		}

		private function updateBoundingBox() : void
		{
			if (_boundingBox)
			{
				_boundingBox.setSize(_contains.width, _contains.length, _contains.height);
			}
		}
	}
}
