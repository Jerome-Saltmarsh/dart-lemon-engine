import 'package:flutter/material.dart';
import 'package:lemon_engine/classes.dart';
import 'package:lemon_engine/engine.dart';
import 'package:lemon_math/Vector2.dart';
import 'package:lemon_watch/watch.dart';

import 'enums.dart';

class LemonEngineState {
  final Watch<Color> backgroundColor = Watch(Colors.black);
  final Watch<ThemeData?> themeData = Watch(null);
  final canvasFrame = ValueNotifier<int>(0);
  final foregroundCanvasFrame = ValueNotifier<int>(0);
  bool drawCanvasAfterUpdate = true;
  Function? update;
  final Watch<int> fps = Watch(0);
  final Screen screen = Screen();
  final Watch<CursorType> cursorType = Watch(CursorType.Precise);
  late BuildContext buildContext;
  final Watch<bool> mouseLeftDown = Watch(false);
  bool mouseDragging = false;
  Vector2 camera = Vector2(0, 0);
  double zoom = 1.0;
  DrawCanvas? drawCanvas;
  late Canvas canvas;
  Paint paint = Paint()
    ..color = Colors.white
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill
    ..isAntiAlias = false
    ..strokeWidth = 1;
  TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr
  );
}