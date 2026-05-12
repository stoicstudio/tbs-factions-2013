package engine.battle.ability.effect.model
{
	import engine.anim.def.IAnimFacing;
	import engine.core.util.Enum;
	import engine.math.MathUtil;

	public class BattleFacing extends Enum implements IAnimFacing
	{
		public static const NE : BattleFacing = new BattleFacing("NE", +0, -1, enumCtorKey);
		public static const SE : BattleFacing = new BattleFacing("SE", +1, +0, enumCtorKey);
		public static const SW : BattleFacing = new BattleFacing("SW", +0, +1, enumCtorKey);
		public static const NW : BattleFacing = new BattleFacing("NW", -1, +0, enumCtorKey);

		public var x : int;
		public var y : int;
		public var angle : Number;

		public function BattleFacing(name : String, x : int, y : int, key : Object)
		{
			super(name, key);
			this.x = x;
			this.y = y;
			angle = Math.atan2(y, x);
		}

		public static function findFacing(fx : Number, fy : Number) : BattleFacing
		{
			if (Math.abs(fx) > Math.abs(fy))
			{
				if (fx > 0)
				{
					return SE;
				}
				else
				{
					return NW;
				}
			}
			else
			{
				if (fy > 0)
				{
					return SW;
				}
				else
				{
					return NE;
				}
			}
		}

		public function angleToPoint(px : Number, py : Number) : Number
		{
			var a : Number = Math.atan2(py, px);
			a -= angle;
			return MathUtil.mungeRadians(a);
		}
	}
}
