package engine.math
{

	/**
	 * Immutable
	 * @author john
	 *
	 */
	public class Box
	{
		private var _size : Point3d;
		private var _center : Point3d;

		/**
		 *
		 * @param width x
		 * @param length y
		 * @param height z
		 *
		 */
		public function Box(width : Number, length : Number, height : Number)
		{
			_size = new Point3d(width, length, height);
			_center = new Point3d(width / 2, length / 2, height / 2);
		}

		public function get size() : Point3d
		{
			return _size;
		}

		public function get center() : Point3d
		{
			return _center;
		}

		public function get height() : Number
		{
			return _size.z;
		}

		public function get length() : Number
		{
			return _size.y;
		}

		public function get width() : Number
		{
			return _size.x;
		}

	}
}
