
import 'package:lemon_engine/engine.dart';

class LemonEngineQueries {
  bool onScreen(double x, double y) {
    return x > engine.state.screen.left &&
        x < engine.state.screen.right &&
        y > engine.state.screen.top &&
        y < engine.state.screen.bottom;
  }
}