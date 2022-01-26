import 'package:flutter/material.dart';
import 'package:lemon_engine/engine.dart';
import 'package:lemon_math/Vector2.dart';
import 'package:lemon_watch/watch.dart';

import 'enums.dart';

class LemonEngineState {
  Offset mousePosition = Offset(0, 0);
  Offset previousMousePosition = Offset(0, 0);
  DateTime previousUpdateTime = DateTime.now();
  final Watch<int> fps = Watch(0);
  final Watch<Color> backgroundColor = Watch(Colors.white);
  final Watch<ThemeData?> themeData = Watch(null);
  int millisecondsSinceLastFrame = 50;
  bool drawCanvasAfterUpdate = true;
  final drawFrame = ValueNotifier<int>(0);
  final _Screen screen = _Screen();
  final initialized = Watch(false);
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

// classes
class _Screen {
  double width = 0;
  double height = 0;
  /// Refers to the world position of the top side of the screen
  double top = 0;
  /// Refers to the world position of the right side of the screen
  double right = 0;
  /// Refers to the world position of the bottom side of the screen
  double bottom = 0;
  /// Refers to the world position of the left side of the screen
  double left = 0;
}
