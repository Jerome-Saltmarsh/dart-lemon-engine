import 'package:lemon_engine/state/screen.dart';

bool onScreen(double x, double y) {
  return x > screen.left &&
      x < screen.right &&
      y > screen.top &&
      y < screen.bottom;
}


