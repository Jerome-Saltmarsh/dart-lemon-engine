
import 'dart:typed_data';
import 'dart:ui';

final _src = Float32List(1 * 4);
final _dst = Float32List(1 * 4);
final _clr = Int32List(1);
final _paint = Paint();

void renderCanvas({
  required Canvas canvas,
  required Image image,
  required double srcX,
  required double srcY,
  required double srcWidth,
  required double srcHeight,
  required double dstX,
  required double dstY,
  double anchorX = 0.5,
  double anchorY = 0.5,
  double scale = 1.0,
  int color = 1,
  BlendMode blendMode = BlendMode.dstATop,
}){
  _clr[0] = color;
  _src[0] = srcX;
  _src[1] = srcY;
  _src[2] = srcX + srcWidth;
  _src[3] = srcY + srcHeight;
  _dst[0] = scale;
  _dst[1] = 0;
  _dst[2] = dstX - (srcWidth * anchorX * scale);
  _dst[3] = dstY - (srcHeight * anchorY * scale); // scale
  canvas.drawRawAtlas(image, _dst, _src, _clr, blendMode, null, _paint);
}

void renderCanvasAbs({
  required Canvas canvas,
  required Image image,
  required double srcLeft,
  required double srcTop,
  required double srcRight,
  required double srcBottom,
  required double dstX,
  required double dstY,
  double anchorX = 0.5,
  double anchorY = 0.5,
  double scale = 1.0,
  double rotation = 0,
  int color = 1,
  BlendMode blendMode = BlendMode.dstATop,
}){
  _clr[0] = color;
  _src[0] = srcLeft;
  _src[1] = srcTop;
  _src[2] = srcRight;
  _src[3] = srcBottom;
  _dst[0] = scale;
  _dst[1] = rotation;
  _dst[2] = dstX;
  _dst[3] = dstY;
  canvas.drawRawAtlas(image, _dst, _src, _clr, blendMode, null, _paint);
}