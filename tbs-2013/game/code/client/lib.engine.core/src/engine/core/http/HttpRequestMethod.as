package engine.core.http
{
	import engine.core.util.Enum;

	public class HttpRequestMethod extends Enum
	{
		public static const POST : HttpRequestMethod = new HttpRequestMethod("POST", enumCtorKey);
		public static const GET : HttpRequestMethod = new HttpRequestMethod("GET", enumCtorKey);

		public function HttpRequestMethod(name : String, key : Object)
		{
			super(name, key);
		}
	}
}
