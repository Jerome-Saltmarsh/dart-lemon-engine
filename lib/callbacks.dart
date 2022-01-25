import 'package:lemon_math/Vector2.dart';

class LemonEngineCallbacks {
  Function? onMouseDragging;
  Function? onLeftClicked;
  Function? onLongLeftClicked;
  Function? onPanStarted;
  Function(double value)? onMouseScroll;
  Function(Vector2 position, Vector2 previous)? onMouseMoved;
}