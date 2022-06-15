import 'dart:math';
import 'dart:typed_data';

import 'package:lemon_engine/engine.dart';

var bufferIndex = 0;
const bufferSize = 100;
final buffers = bufferSize * 4;
final src = Float32List(buffers);
final dst = Float32List(buffers);
final srcFlush = Float32List(4);
final dstFlush = Float32List(4);

void render({
  required double dstX,
  required double dstY,
  required double srcX,
  required double srcY,
  required double srcWidth,
  required double srcHeight,
  double scale = 1.0,
  double rotation = 0,
  double anchorX = 0.5,
  double anchorY = 0.5,

}){
  final i = bufferIndex * 4;
  final scos = cos(rotation) * scale;
  final ssin = sin(rotation) * scale;

  src[i] = srcX;
  src[i + 1] = srcY;
  src[i + 2] = srcX + srcWidth;
  src[i + 3] = srcY + srcHeight;

  dst[i] = scos;
  dst[i + 1] = ssin;
  dst[i + 2] = dstX + -scos * anchorX + ssin * (srcWidth * anchorY);
  dst[i + 3] = dstY + -ssin * anchorX - scos * (srcHeight * anchorY);

  engine.renderAtlas();
}