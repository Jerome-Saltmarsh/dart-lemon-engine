
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:lemon_engine/state/canvas.dart';
import 'package:lemon_engine/state/paint.dart';


void drawAtlas(ui.Image image, List<RSTransform> transforms, List<Rect> rects){
  globalCanvas.drawAtlas(image, transforms, rects, null, null, null, paint);
}

