import 'package:flutter/services.dart';
import 'package:lemon_engine/engine.dart';

class LemonEngineEvents {
  
  void onMouseScroll(double amount) {
    engine.targetZoom -= amount * engine.scrollSensitivity;
  }

  void onKeyboardEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      engine.keyPressedHandlers[event.logicalKey]?.call();
      return;
    }
    if (event is RawKeyUpEvent) {
      engine.keyReleasedHandlers[event.logicalKey]?.call();
    }
  }
}