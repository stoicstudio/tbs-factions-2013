import java.util.Map;

import org.eclipse.jetty.util.ajax.JSON;
import org.eclipse.jetty.util.ajax.JSON.Convertible;
import org.eclipse.jetty.util.ajax.JSON.Output;

public class Dang {

	public static class A implements Convertible {
		String name;

		public A() {

		}

		public A(String name) {
			this.name = name;
		}

		@Override
		public void toJSON(Output out) {
			out.addClass(getClass());
			out.add("name", name);
		}

		@Override
		public void fromJSON(@SuppressWarnings("rawtypes") Map object) {
			name = (String) object.get("name");
		}
	}

	public static class B implements Convertible {
		Object[] ao = new Object[] { new A("o1"), new A("o2") };
		A[] aa = new A[] { new A("a1"), new A("2a") };
		String b = "b";

		public B() {

		}

		@Override
		public void toJSON(Output out) {
			out.addClass(getClass());
			out.add("ao", ao);
			out.add("aa", aa);
			out.add("b", b);

		}

		@Override
		public void fromJSON(@SuppressWarnings("rawtypes") Map object) {
			ao = (Object[]) object.get("ao");
			b = (String) object.get("b");

		}
	}

	public static void main(String[] argv) {
		B b = new B();
		String s = JSON.toString(b);
		Object o = JSON.parse(s);
		System.out.println(o);
	}
}
