
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart';

import 'engine.dart';

class LemonEngineActions {

  void cameraCenter(double x, double y) {
    engine.state.camera.x = x - (screenCenterX / engine.state.zoom);
    engine.state.camera.y = y - (screenCenterY / engine.state.zoom);
  }

  void redrawCanvas() {
    engine.state.drawFrame.value++;
  }

  void fullscreenToggle(){
    fullScreenActive ? fullScreenExit() : fullScreenEnter();
  }

  void fullScreenExit() {
    document.exitFullscreen();
  }

  void panCamera(){
    final positionX = screenToWorldX(engine.state.mousePosition.dx);
    final positionY = screenToWorldY(engine.state.mousePosition.dy);
    final previousX = screenToWorldX(engine.state.previousMousePosition.dx);
    final previousY = screenToWorldY(engine.state.previousMousePosition.dy);
    final diffX = previousX - positionX;
    final diffY = previousY - positionY;
    engine.state.camera.x += diffX * engine.state.zoom;
    engine.state.camera.y += diffY * engine.state.zoom;
  }

  void fullScreenEnter() {
    document.documentElement!.requestFullscreen();
  }

  void disableRightClickContextMenu() {
    document.onContextMenu.listen((event) => event.preventDefault());
  }

  void clearCallbacks() {
    print("engine.actions.clearCallbacks()");
    engine.callbacks.onMouseMoved = null;
    engine.callbacks.onMouseScroll = null;
    engine.callbacks.onMouseDragging = null;
    engine.callbacks.onPanStarted = null;
    engine.callbacks.onLeftClicked = null;
    engine.callbacks.onLongLeftClicked = null;
    engine.callbacks.onKeyReleased = null;
    engine.callbacks.onKeyPressed = null;
    engine.callbacks.onKeyHeld = null;
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