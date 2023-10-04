import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'get_image_byte_buffer.dart';


Future<Image> copyAreaFromImage({
  required Image image,
  required int x,
  required int y,
  required int width,
  required int height,
}) async {
  final imageBuffer = await getImageByteBuffer(image);
  final imageBytes = imageBuffer.asUint8List();
  final copyBytes = Uint8List(width * height * 4);

  for (int row = 0; row < height; row++) {
    final srcIndex = (y + row) * image.width + x;
    final destIndex = row * width;
    copyBytes.setRange(
        destIndex * 4,
        (destIndex + width) * 4,
        imageBytes.sublist(srcIndex * 4, (srcIndex + width) * 4),
    );
  }

  final codec = await instantiateImageCodec(copyBytes);
  final frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}

