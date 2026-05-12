import java.nio.charset.Charset;

import javax.xml.bind.DatatypeConverter;

import tbs.srv.util.Zip;

public class MsgPeek {

	public static void main(String[] argv) {

		for (String s : argv) {

			// final byte[] data = Base64.decode(s);
			final byte[] data = DatatypeConverter.parseBase64Binary(s);
			final byte[] decompressed = Zip.decompress(data);
			final String jstr = new String(decompressed, Charset.forName("UTF-8"));

			System.out.println(jstr);
		}
	}
}
