import 'package:lemon_math/functions/vector2.dart';
import 'package:flutter/services.dart';

class LemonEngineCallbacks {
  Function? onMouseDragging;
  Function? onLeftClicked;
  Function? onLongLeftClicked;
  Function? onPanStarted;
  Function(double value)? onMouseScroll;
  Function? onRightClicked;
  Function? onRightClickReleased;
  Function(Vector2 position, Vector2 previous)? onMouseMoved;
  Function(LogicalKeyboardKey key)? onKeyPressed;
  Function(LogicalKeyboardKey key, int frames)? onKeyHeld;
  Function(LogicalKeyboardKey key)? onKeyReleased;
}