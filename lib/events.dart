import 'package:flutter/services.dart';
import 'package:lemon_engine/engine.dart';

class LemonEngineEvents {
  void onKeyboardEvent(RawKeyEvent event) {
    final key = event.logicalKey;
    if (event is RawKeyUpEvent) {
      engine.state.keyboardState[key] = 0;
      engine.callbacks.onKeyReleased?.call(key);
      return;
    }
    if (event is RawKeyDownEvent) {
      int? frames = engine.state.keyboardState[key];
      if (frames != null){
        if (frames == 0){
          engine.callbacks.onKeyPressed?.call(key);
          return;
        }
        int nextFrame = frames + 1;
        engine.state.keyboardState[key] = nextFrame;
        engine.callbacks.onKeyHeld?.call(key, nextFrame);
        return;
      }
      engine.state.keyboardState[key] = 1;
      engine.callbacks.onKeyPressed?.call(key);
    }
  }
}