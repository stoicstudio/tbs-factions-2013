package engine.battle.board.view.arrow
{
	import com.dncompute.graphics.ArrowStyle;

	import flash.display.Sprite;

	public class ArrowManager extends Sprite
	{
		public static const STYLE_DEFAULT : ArrowStyle = new ArrowStyle();

		private static var initialized : Boolean;

		public function ArrowManager()
		{
			if (!initialized)
			{
				STYLE_DEFAULT.shaftThickness = 5;
				STYLE_DEFAULT.headWidth = 40;
				STYLE_DEFAULT.headLength = 40;
				STYLE_DEFAULT.shaftPosition = .25;
				STYLE_DEFAULT.edgeControlPosition = .5;
			}
		}

		public function fetchArrow(style : ArrowStyle) : ArrowShape
		{
			var arrow : ArrowShape = new ArrowShape(style);
			addChild(arrow);
			return arrow;
		}

		public function releaseArrow(arrow : ArrowShape) : void
		{
			removeChild(arrow);
		}

	}
}
