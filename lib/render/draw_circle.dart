import 'dart:ui';

import 'package:lemon_engine/state/canvas.dart';
import 'package:lemon_engine/state/paint.dart';

void drawCircle(double x, double y, double radius, Color color) {
  drawCircleOffset(Offset(x, y), radius, color);
}

void drawCircleOffset(Offset offset, double radius, Color color) {
  paint.color = color;
  globalCanvas.drawCircle(offset, radius, paint);
}