import 'package:flutter/cupertino.dart';

class LemonEngineCallbacks {
  Function? onMouseDragging;
  Function? onLeftClicked;
  Function? onLongLeftClicked;
  Function? onPanStarted;
  Function(double value)? onMouseScroll;
  Function? onRightClicked;
  Function? onRightClickReleased;
  Function(Offset position, Offset previous)? onMouseMoved;
}