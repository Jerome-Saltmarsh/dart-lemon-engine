
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart';

import 'engine.dart';

class LemonEngineActions {

  void fullscreenToggle(){
    fullScreenActive ? fullScreenExit() : fullScreenEnter();
  }

  void fullScreenExit() {
    document.exitFullscreen();
  }

  void fullScreenEnter() {
    document.documentElement!.requestFullscreen();
  }

  void disableRightClickContextMenu() {
    document.onContextMenu.listen((event) => event.preventDefault());
  }

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