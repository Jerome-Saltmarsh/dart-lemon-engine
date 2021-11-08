
import 'dart:ui';

import 'package:lemon_engine/state/canvas.dart';
import 'package:lemon_engine/state/paint.dart';


void drawImage(Image image, double x, double y){
  globalCanvas.drawImage(image, Offset(x, y), paint);
}