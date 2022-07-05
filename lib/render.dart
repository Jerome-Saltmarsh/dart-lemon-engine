import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:lemon_engine/engine.dart';

var bufferIndex = 0;
var renderIndex = 0;
const bufferSize = 100;
final buffers = bufferSize * 4;
final src = Float32List(buffers);
final dst = Float32List(buffers);
final colors = Int32List(bufferSize);
final srcFlush = Float32List(4);
final dstFlush = Float32List(4);
final colorsFlush = Int32List(1);
var renderBlendMode = BlendMode.dstATop;

void setRenderBlendMode(BlendMode value){
  renderBlendMode = value;
}

void renderR({
  required double dstX,
  required double dstY,
  required double srcX,
  required double srcY,
  required double srcWidth,
  required double srcHeight,
  required double rotation,
  double scale = 1.0,
  double anchorX = 0.5,
  double anchorY = 0.5,
}){

  final scos = cos(rotation) * scale;
  final ssin = sin(rotation) * scale;

  src[bufferIndex] = srcX;
  dst[bufferIndex] = scos;
  bufferIndex++;

  src[bufferIndex] = srcY;
  dst[bufferIndex] = ssin;
  bufferIndex++;

  src[bufferIndex] = srcX + srcWidth;
  dst[bufferIndex] = dstX - (srcWidth * anchorX * scale);

  bufferIndex++;
  src[bufferIndex] = srcY + srcHeight;
  dst[bufferIndex] = dstY - (srcHeight * anchorY * scale);

  bufferIndex++;
  renderIndex++;

  if (bufferIndex < buffers) return;
  bufferIndex = 0;
  renderIndex = 0;

  engine.renderAtlas();
}


final cos0 = cos(0);
final sin0 = sin(0);

void render({
  required double dstX,
  required double dstY,
  required double srcX,
  required double srcY,
  required double srcWidth,
  required double srcHeight,
  double scale = 1.0,
  double anchorX = 0.5,
  double anchorY = 0.5,
  int color = 0,
}){
  final scos = cos0 * scale;
  final ssin = sin0 * scale;

  src[bufferIndex] = srcX;
  dst[bufferIndex] = scos;
  colors[renderIndex] = color;
  bufferIndex++;

  src[bufferIndex] = srcY;
  dst[bufferIndex] = ssin;
  bufferIndex++;

  src[bufferIndex] = srcX + srcWidth;
  dst[bufferIndex] = dstX - (srcWidth * anchorX * scale);

  bufferIndex++;
  src[bufferIndex] = srcY + srcHeight;
  dst[bufferIndex] = dstY - (srcHeight * anchorY * scale);

  bufferIndex++;
  renderIndex++;

  if (bufferIndex < buffers) return;
  bufferIndex = 0;
  renderIndex = 0;

  engine.renderAtlas();
}