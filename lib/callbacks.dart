import 'package:lemon_math/Vector2.dart';

class LemonEngineCallbacks {
  Function? onMouseDragging;
  Function? onLeftClicked;
  Function? onLongLeftClicked;
  Function? onPanStarted;
  /// on right mouse button clicked
  Function? onRightClickDown;
  /// on right mouse button is released
  Function? onRightClickUp;
  Function(double value)? onMouseScroll;
  Function(Vector2 position, Vector2 previous)? onMouseMoved;
}