import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:lemon_engine/actions.dart';
import 'package:lemon_engine/callbacks.dart';
import 'package:lemon_engine/draw.dart';
import 'package:lemon_engine/queries.dart';
import 'package:lemon_engine/state.dart';
import 'package:lemon_math/Vector2.dart';
import 'package:universal_html/html.dart';


final _Engine engine = _Engine();


class _InternalState {
  final Vector2 mousePosition = Vector2(0, 0);
  final Vector2 previousMousePosition = Vector2(0, 0);
}

class _Engine {
  final state = LemonEngineState();
  final actions = LemonEngineActions();
  final callbacks = LemonEngineCallbacks();
  final draw = LemonEngineDraw();
  final queries = LemonEngineQueries();
  final _internalState = _InternalState();

  _Engine(){
    _registerMouseMoveListener();
  }

  void _registerMouseMoveListener() {
    document.addEventListener("mousemove", (value){
      if (value is MouseEvent){
       _onMouseEvent(value);
      }
    }, false);
  }

  _onMouseEvent(MouseEvent event){
     _internalState.previousMousePosition.x = _internalState.mousePosition.x;
     _internalState.previousMousePosition.y = _internalState.mousePosition.y;
     _internalState.mousePosition.x = event.page.x.toDouble();
     _internalState.mousePosition.y = event.page.y.toDouble();

     callbacks.onMouseMoved?.call(
         _internalState.mousePosition, _internalState.previousMousePosition
     );
  }
}

bool keyPressed(LogicalKeyboardKey key) {
  return RawKeyboard.instance.keysPressed.contains(key);
}

Future<Image> loadImage(String url) async {
  final ByteData data = await rootBundle.load(url);
  final Uint8List img = Uint8List.view(data.buffer);
  final Completer<Image> completer = new Completer();
  decodeImageFromList(img, (Image img) {
    return completer.complete(img);
  });
  return completer.future;
}

double screenToWorldX(double value) {
  return engine.state.camera.x + value / engine.state.zoom;
}

double screenToWorldY(double value) {
  return engine.state.camera.y + value / engine.state.zoom;
}

/// Screen Position
Vector2 get mousePosition => engine._internalState.mousePosition;
/// Screen Position
double get mouseX => mousePosition.x;
/// Screen Position
double get mouseY => mousePosition.y;
double get mouseWorldX => screenToWorldX(mouseX);
double get mouseWorldY => screenToWorldY(mouseY);
bool get fullScreenActive => document.fullscreenElement != null;

typedef DrawCanvas(Canvas canvass, Size size);