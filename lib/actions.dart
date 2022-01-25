
import 'package:flutter/material.dart';

import 'engine.dart';

class LemonEngineActions {

  void clearCallbacks(){
    print("engine.actions.clearCallbacks()");
     engine.callbacks.onMouseMoved = null;
     engine.callbacks.onMouseScroll = null;
     engine.callbacks.onMouseDragging = null;
     engine.callbacks.onPanStarted = null;
     engine.callbacks.onLeftClicked = null;
     engine.callbacks.onLongLeftClicked = null;
  }

  void setPaintColorWhite(){
    setPaintColor(Colors.white);
  }

  void setPaintStrokeWidth(double value){
    engine.state.paint.strokeWidth = value;
  }

  void setPaintColor(Color value) {
    if (engine.state.paint.color == value) return;
    engine.state.paint.color = value;
  }
}