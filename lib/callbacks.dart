import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class LemonEngineCallbacks {
  Function? onMouseDragging;
  Function? onLeftClicked;
  Function? onLongLeftClicked;
  Function? onPanStarted;
  Function(double value)? onMouseScroll;
  Function? onRightClicked;
  Function? onRightClickReleased;
  Function(Offset position, Offset previous)? onMouseMoved;
  Function(LogicalKeyboardKey key)? onKeyPressed;
  Function(LogicalKeyboardKey key, int frames)? onKeyHeld;
  Function(LogicalKeyboardKey key)? onKeyReleased;
}