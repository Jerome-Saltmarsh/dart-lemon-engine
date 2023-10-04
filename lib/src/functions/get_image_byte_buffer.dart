
import 'dart:typed_data';
import 'dart:ui';

Future<ByteBuffer> getImageByteBuffer(Image image) async {
  final byteData = await image.toByteData();
  if (byteData == null)
    throw Exception();

  return byteData.buffer;
}