import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:lemon_engine/actions.dart';
import 'package:lemon_engine/callbacks.dart';
import 'package:lemon_engine/draw.dart';
import 'package:lemon_engine/state.dart';
import 'package:universal_html/html.dart';

import 'game.dart';

final _Engine engine = _Engine();

class _Engine {
  final state = LemonEngineState();
  final actions = LemonEngineActions();
  final callbacks = LemonEngineCallbacks();
  final draw = LemonEngineDraw();
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

double get mouseWorldX => screenToWorldX(mouseX);
double get mouseWorldY => screenToWorldY(mouseY);
bool get fullScreenActive => document.fullscreenElement != null;

typedef DrawCanvas(Canvas canvass, Size size);

bool onScreen(double x, double y) {
  return x > engine.state.screen.left &&
      x < engine.state.screen.right &&
      y > engine.state.screen.top &&
      y < engine.state.screen.bottom;
}