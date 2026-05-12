package tbs.srv.util;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.zip.Deflater;
import java.util.zip.Inflater;

public class Zip {

	public final static byte[] decompress(byte[] input) {
		Inflater inflator = new Inflater();
		inflator.setInput(input);
		ByteArrayOutputStream bos = new ByteArrayOutputStream(input.length);
		byte[] buf = new byte[1024];
		try {
			while (true) {
				int count = inflator.inflate(buf);
				if (count == 0 && inflator.finished()) {
					break;
				} else if (count == 0) {
					throw new RuntimeException("bad zip data, size:" + input.length);
				} else {
					bos.write(buf, 0, count);
				}
			}
		} catch (Throwable t) {
			throw new RuntimeException(t);
		} finally {
			inflator.end();
		}
		return bos.toByteArray();
	}

	public final static byte[] compress(byte[] input) {

		// Create the compressor with highest level of compression
		Deflater compressor = new Deflater();
		compressor.setLevel(Deflater.BEST_COMPRESSION);

		// Give the compressor the data to compress
		compressor.setInput(input);
		compressor.finish();

		// Create an expandable byte array to hold the compressed data.
		// You cannot use an array that's the same size as the orginal because
		// there is no guarantee that the compressed data will be smaller than
		// the uncompressed data.
		ByteArrayOutputStream bos = new ByteArrayOutputStream(input.length);

		// Compress the data
		byte[] buf = new byte[1024];
		while (!compressor.finished()) {
			int count = compressor.deflate(buf);
			bos.write(buf, 0, count);
		}
		try {
			bos.close();
		} catch (IOException e) {
			throw new RuntimeException(e);
		}

		// Get the compressed data
		return bos.toByteArray();
	}
}
