

import 'dart:ui';

import 'package:lemon_engine/state/canvas.dart';
import 'package:lemon_engine/state/paint.dart';

void drawImageRect(Image image, Rect src, Rect dst){
  globalCanvas.drawImageRect(image, src, dst, paint);
}