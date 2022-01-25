import 'package:lemon_engine/engine.dart';

double screenToWorldX(double value) {
  return engine.state.camera.x + value / engine.state.zoom;
}

double screenToWorldY(double value) {
  return engine.state.camera.y + value / engine.state.zoom;
}
