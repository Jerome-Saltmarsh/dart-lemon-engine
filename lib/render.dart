import 'dart:math';
import 'dart:typed_data';

import 'package:lemon_engine/engine.dart';

int bufferIndex = 0;
final int buffers = 400;
late int bufferSize = 100;
late final Float32List src = Float32List(bufferSize);
late final Float32List dst = Float32List(bufferSize);
late final srcFlush = Float32List(4);
late final dstFlush = Float32List(4);

void render({
  required double dstX,
  required double dstY,
  required double srcX,
  required double srcY,
  required double srcWidth,
  required double srcHeight,
  double scale = 0.5,
  double rotation = 0,
  double anchorX = 0,
  double anchorY = 0,

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
  dst[i + 2] = dstX + -scos * anchorX + ssin * anchorY;
  dst[i + 3] = dstY + -ssin * anchorX - scos * anchorY;

  engine.renderAtlas();
}