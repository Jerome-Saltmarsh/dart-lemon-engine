import 'package:flutter/material.dart';
import 'package:lemon_engine/state/cursor.dart';
import 'package:lemon_engine/typedefs/DrawCanvas.dart';
import 'package:lemon_math/Vector2.dart';
import 'package:lemon_watch/watch.dart';

class LemonEngineState {
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