library lemon_engine;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:lemon_engine/actions.dart';
import 'package:lemon_engine/callbacks.dart';
import 'package:lemon_engine/draw.dart';
import 'package:lemon_engine/events.dart';
import 'package:lemon_engine/state.dart';
import 'package:lemon_math/Vector2.dart';
import 'package:lemon_math/distance_between.dart';
import 'package:universal_html/html.dart';

final _Engine engine = _Engine();

class _Engine {
  final state = LemonEngineState();
  final actions = LemonEngineActions();
  final callbacks = LemonEngineCallbacks();
  final draw = LemonEngineDraw();
  final events = LemonEngineEvents();

  _Engine(){
    RawKeyboard.instance.addListener(events.onKeyboardEvent);
  }
}

// global utilities
bool keyPressed(LogicalKeyboardKey key) {
  return RawKeyboard.instance.keysPressed.contains(key);
}

double screenToWorldX(double value) {
  return engine.state.camera.x + value / engine.state.zoom;
}

double screenToWorldY(double value) {
  return engine.state.camera.y + value / engine.state.zoom;
}

bool onScreen(double x, double y) {
  return x > engine.state.screen.left &&
      x < engine.state.screen.right &&
      y > engine.state.screen.top &&
      y < engine.state.screen.bottom;
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

double distanceFromMouse(double x, double y) {
  return distanceBetween(mouseWorldX, mouseWorldY, x, y);
}

T closestToMouse<T extends Vector2>(List<T> values){
  return findClosest(values, mouseWorldX, mouseWorldY);
}

// global constants
const int millisecondsPerSecond = 1000;

// global properties
Offset get mousePosition => engine.state.mousePosition;
Offset get previousMousePosition => engine.state.previousMousePosition;
double get mouseX => engine.state.mousePosition.dx;
double get mouseY => engine.state.mousePosition.dy;
Offset get mouse => Offset(mouseX, mouseY);
Offset get mouseWorld => Offset(mouseWorldX, mouseWorldY);
double get screenCenterX => engine.state.screen.width * 0.5;
double get screenCenterY => engine.state.screen.height * 0.5;
double get screenCenterWorldX => screenToWorldX(screenCenterX);
double get screenCenterWorldY => screenToWorldY(screenCenterY);
Offset get screenCenterWorld => Offset(screenCenterWorldX, screenCenterWorldY);
double get mouseWorldX => screenToWorldX(mouseX);
double get mouseWorldY => screenToWorldY(mouseY);
bool get fullScreenActive => document.fullscreenElement != null;

// global typedefs
typedef DrawCanvas(Canvas canvass, Size size);

// classes
abstract class KeyboardEventHandler {
  void onPressed(PhysicalKeyboardKey key);
  void onReleased(PhysicalKeyboardKey key);
  void onHeld(PhysicalKeyboardKey key, int frames);
}