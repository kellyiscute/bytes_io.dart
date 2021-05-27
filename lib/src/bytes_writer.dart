import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

class BytesWriter {
  final BytesBuilder data;

  BytesWriter() : data = BytesBuilder();

  int writeByte(int byte) {
    data.addByte(byte);
    return 1;
  }

  int writeBytes(List<int> bytes) {
    data.add(bytes);
    return bytes.length;
  }

  int writeBool(bool value) {
    data.addByte(value ? 1 : 0);
    return 1;
  }

  int writeString(String s) {
    int written = 0;
    int sLength = s.length;
    while (sLength >= 0x80) {
      // the extra & 0xff is to strip off all bits higher than 0xff
      data.addByte((sLength | 0x80) & 0xff);
      sLength >>= 7;
      written++;
    }
    data.addByte(sLength);
    written++;

    var b = Utf8Encoder().convert(s);
    written += b.lengthInBytes;
    data.add(b);

    return written;
  }

  Uint8List popAll() {
    return data.takeBytes();
  }

  void clear() {
    data.clear();
  }

  List<int> copy() {
    return data.toBytes();
  }
}
