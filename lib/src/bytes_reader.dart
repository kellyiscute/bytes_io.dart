import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

enum IntType { int8, int16, int32, int64 }

class BytesReader {
  final Uint8List data;
  int _currentPosition = 0;

  int get position => _currentPosition;

  /// Create a BytesReader from `Uint8List`
  BytesReader.fromUint8List(Uint8List data) : this.data = data;

  /// Create a BytesReader from `List<int>`
  BytesReader.fromIntList(List<int> data)
      : this.data = Uint8List.fromList(data);

  /// seek current pointer to an absolute position
  void seek(int position) {
    if (position > data.lengthInBytes || position < 0) {
      throw IndexError(position, data);
    }
    this._currentPosition = position;
  }

  /// seek current pointer to a position relative to the current position
  void seekRelative(int position) {
    if (_currentPosition + position > data.lengthInBytes ||
        _currentPosition + position < 0) {
      throw IndexError(position, data);
    }
    this._currentPosition += position;
  }

  /**
   * read bytes from data. 
   * 
   * Notice that this won't copy the bytes to save space
   * You can do that manually if you wish to
   */
  Uint8List readBytes(int length) {
    return Uint8List.sublistView(
        data, _currentPosition, _currentPosition + length);
  }

  /// read bytes until a specific byte being seen
  /// the specific byte is not included
  Uint8List readUntil(int byte) {
    int startPosition = _currentPosition;
    while (_currentPosition < data.lengthInBytes &&
        data[_currentPosition] != byte) {
      _currentPosition++;
    }
    return Uint8List.sublistView(data, startPosition, _currentPosition);
  }

  /// read int out of bytes
  /// defaults to int32 with the host's endian
  int readInt([IntType type = IntType.int32, Endian? endian]) {
    int shouldRead = [1, 2, 4, 8][type.index];
    int result = 0;
    if (endian == null) {
      endian = Endian.host;
    }
    for (var i = 0; i < shouldRead; i++) {
      if (endian == Endian.big) {
        // higher bits goes first, so move the read bytes 8 bits left
        // and use bit-wise OR operator to put the lower bytes into
        // the read bytes
        // eg.
        // read = 0xff, then shift 8 bits left, would be
        // read = 0xff00, then OR the other part to put together
        // read = 0xff00 | 0x0022 => 0xff22
        result <<= 8;
        result |= data[_currentPosition];
      } else {
        result |= data[_currentPosition] << 8;
      }
      _currentPosition++;
    }
    return result;
  }

  /// read one byte from data
  int readByte() {
    _currentPosition++;
    return data[_currentPosition - 1];
  }

  /// read bytes and decode as string
  /// Utf8Decoder as the default decoder
  String readAsString(int length, {Converter<List<int>, String>? encoder}) {
    if (encoder == null) {
      encoder = Utf8Decoder();
    }
    Uint8List bytes = readBytes(length);
    return encoder.convert(bytes);
  }

  /// read bytes_io formatted string
  ///
  /// implementation details:
  /// lead by "length" bytes, encoded with 7-bit int
  /// the highest bit to indicate wheather there are
  /// more bytes to read.
  ///
  /// the string is encoded in UTF8 codec
  ///
  /// A reference to this implementation:
  /// https://referencesource.microsoft.com/#mscorlib/system/io/binaryreader.cs,f30b8b6e8ca06e0f
  String readString() {
    int length = 0;
    int shift = 0;
    int b;
    do {
      b = readByte();
      length |= (b & 0x7f) << shift;
      shift += 7;
    } while ((b & 0x80) != 0);

    var data = readBytes(length);
    return Utf8Decoder().convert(data);
  }

  /// read bool, represented by a single byte
  /// if the byte is not 1, it would be false
  /// if in strict mode, any value other than 1 or 0 will throw
  bool readBool([bool strict = false]) {
    int b = readByte();
    if (strict && b != 0 && b != 1) {
      throw FormatException("[Strict Mode] Invalid bool encoding");
    }
    return b == 1;
  }
}
