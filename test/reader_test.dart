import 'dart:convert';
import 'dart:math';

import 'package:bytes_io/bytes_io.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void readUntilTest() {
  var data = Utf8Encoder().convert("a test\na new line\n");
  BytesReader reader = BytesReader.fromUint8List(data);
  var read = reader.readUntil(Utf8Encoder().convert("\n").first);
  test("test read until the first time", () {
    expect(() {
      var converted = Utf8Decoder().convert(read);
      print(converted);
      return converted;
    }(), endsWith("t"));
  });
  test("test read until the second time", () {
    expect(() {
      var read = AsciiDecoder().convert(reader.readUntil("\n".codeUnitAt(0)));
      return read;
    }(), equals(""));
  });

  test("test read until the second time", () {
    expect(() {
      var read = AsciiDecoder().convert([reader.readByte()]);
      return read;
    }(), equals("\n"));
  });
}

void main() {
  readUntilTest();
}
