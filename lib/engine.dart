library lemon_engine;

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_engine/callbacks.dart';
import 'package:lemon_engine/draw.dart';
import 'package:lemon_engine/enums.dart';
import 'package:lemon_engine/events.dart';
import 'package:lemon_math/Vector2.dart';
import 'package:lemon_math/distance_between.dart';
import 'package:lemon_watch/watch.dart';
import 'package:universal_html/html.dart';

final _Engine engine = _Engine();

class _Engine {

  static const _indexesPerBuffer = 4;

  int bufferIndex = 0;
  final int buffers = 100;
  late int bufferSize;
  late final Float32List src;
  late final Float32List dst;

  final callbacks = LemonEngineCallbacks();
  final draw = LemonEngineDraw();
  late final LemonEngineEvents events;
  double scrollSensitivity = 0.0005;
  late ui.Image image;
  bool cameraSmoothFollow = true;
  double cameraFollowSpeed = 0.04;
  double zoomSensitivity = 0.1;
  double targetZoom = 1;
  final Map<LogicalKeyboardKey, int> keyboardState = {};
  Vector2 mousePosition = Vector2(0, 0);
  Vector2 previousMousePosition = Vector2(0, 0);
  DateTime previousUpdateTime = DateTime.now();
  final Watch<int> fps = Watch(0);
  final Watch<Color> backgroundColor = Watch(Colors.white);
  final Watch<ThemeData?> themeData = Watch(null);
  int millisecondsSinceLastFrame = 50;
  bool drawCanvasAfterUpdate = true;
  final drawFrame = ValueNotifier<int>(0);
  final _Screen screen = _Screen();
  final initialized = Watch(false);
  final Watch<CursorType> cursorType = Watch(CursorType.Precise);
  late BuildContext buildContext;
  final Watch<bool> mouseLeftDown = Watch(false);
  bool mouseDragging = false;
  Vector2 camera = Vector2(0, 0);
  double zoom = 1.0;
  final Watch<DrawCanvas?> drawCanvas = Watch(null);
  Function? update;
  late Canvas canvas;
  Paint paint = Paint()
    ..color = Colors.white
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill
    ..isAntiAlias = false
    ..strokeWidth = 1;
  TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr
  );

  Map<LogicalKeyboardKey, Function> keyPressedHandlers = {};
  Map<LogicalKeyboardKey, Function> keyReleasedHandlers = {};

  _Engine(){
    bufferSize = buffers * _indexesPerBuffer;
    src = Float32List(bufferSize);
    dst = Float32List(bufferSize);

    events = LemonEngineEvents();
    RawKeyboard.instance.addListener(events.onKeyboardEvent);
    registerZoomCameraOnMouseScroll();
  }

  void registerZoomCameraOnMouseScroll(){
    callbacks.onMouseScroll = events.onMouseScroll;
  }

  void mapSrc({
    required double x,
    required double y,
    double width = 64,
    double height = 64
  }){
    final i = bufferIndex * _indexesPerBuffer;
    src[i] = x;
    src[i + 1] = y;
    src[i + 2] = x + width;
    src[i + 3] = y + height;
  }

  void mapDst({
    required double x,
    required double y,
    double scale = 1.0,
    double rotation = 0,
    double anchorX = 0,
    double anchorY = 0,
  }){
    final scos = cos(rotation) * scale;
    final ssin = sin(rotation) * scale;
    final i = bufferIndex * _indexesPerBuffer;
    dst[i] = scos;
    dst[i + 1] = ssin;
    dst[i + 2] = x + -scos * anchorX + ssin * anchorY;
    dst[i + 3] = y + -ssin * anchorX - scos * anchorY;
  }

  void mapDstCheap({
    required double x,
    required double y,
  }){
    final i = bufferIndex * _indexesPerBuffer;
    dst[i] = 1.0;
    dst[i + 1] = 0;
    dst[i + 2] = x;
    dst[i + 3] = y;
  }


  void renderAtlas(){
    bufferIndex++;
    if (bufferIndex < buffers) return;
    bufferIndex = 0;
    canvas.drawRawAtlas(image, dst, src, null, null, null, paint);
  }

  /// If there are draw jobs remaining in the buffer
  /// it draws them and clears the rest
  void flushRenderBuffer(){
    if (bufferIndex == 0) return;

    for(int i = bufferIndex + 1; i < buffers; i++){
      final j = i * 4;
      src[j] = 0;
      src[j + 1] = 0;
      src[j + 2] = 0;
      src[j + 3] = 0;
      dst[j] = 1; // scale
      dst[j + 1] = 0; // rotation
      dst[j + 2] = 0; // x
      dst[j + 3] = 0; // y
    }
    canvas.drawRawAtlas(image, dst, src, null, null, null, paint);
  }

  void cameraFollow(double x, double y, double speed){
    final xDiff = screenCenterWorldX - x;
    final yDiff = screenCenterWorldY - y;
    camera.x -= xDiff * speed;
    camera.y -= yDiff * speed;
  }

  void cameraCenter(double x, double y) {
    camera.x = x - (screenCenterX / zoom);
    camera.y = y - (screenCenterY / zoom);
  }

  void redrawCanvas() {
    drawFrame.value++;
  }

  void fullscreenToggle(){
    fullScreenActive ? fullScreenExit() : fullScreenEnter();
  }

  void fullScreenExit() {
    document.exitFullscreen();
  }

  void panCamera(){
    final positionX = screenToWorldX(mousePosition.x);
    final positionY = screenToWorldY(mousePosition.y);
    final previousX = screenToWorldX(previousMousePosition.x);
    final previousY = screenToWorldY(previousMousePosition.y);
    final diffX = previousX - positionX;
    final diffY = previousY - positionY;
    camera.x += diffX * zoom;
    camera.y += diffY * zoom;
  }

  void fullScreenEnter() {
    document.documentElement!.requestFullscreen();
  }

  void disableRightClickContextMenu() {
    document.onContextMenu.listen((event) => event.preventDefault());
  }

  void clearCallbacks() {
    print("engine.actions.clearCallbacks()");
    callbacks.onMouseMoved = null;
    callbacks.onMouseScroll = null;
    callbacks.onMouseDragging = null;
    callbacks.onPanStarted = null;
    callbacks.onLeftClicked = null;
    callbacks.onLongLeftClicked = null;
    callbacks.onKeyReleased = null;
    callbacks.onKeyPressed = null;
    callbacks.onKeyHeld = null;
  }

  void setPaintColorWhite(){
    setPaintColor(Colors.white);
  }

  void setPaintStrokeWidth(double value){
    paint.strokeWidth = value;
  }

  void setPaintColor(Color value) {
    if (paint.color == value) return;
    paint.color = value;
  }
}

// global utilities
bool keyPressed(LogicalKeyboardKey key) {
  return RawKeyboard.instance.keysPressed.contains(key);
}

final _camera = engine.camera;

double screenToWorldX(double value) {
  return _camera.x + value / engine.zoom;
}

double screenToWorldY(double value) {
  return _camera.y + value / engine.zoom;
}

bool onScreen(double x, double y) {
  return x > _screen.left &&
      x < _screen.right &&
      y > _screen.top &&
      y < _screen.bottom;
}

Future<ui.Image> loadImage(String url) async {
  final ByteData data = await rootBundle.load(url);
  final Uint8List img = Uint8List.view(data.buffer);
  final Completer<ui.Image> completer = new Completer();
  ui.decodeImageFromList(img, (ui.Image img) {
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
// Offset get mouseWorld => Offset(mouseWorldX, mouseWorldY);
final _mousePosition = engine.mousePosition;
final _screen = engine.screen;

double get screenCenterX => _screen.width * 0.5;
double get screenCenterY => _screen.height * 0.5;
double get screenCenterWorldX => screenToWorldX(screenCenterX);
double get screenCenterWorldY => screenToWorldY(screenCenterY);
double get mouseWorldX => screenToWorldX(_mousePosition.x);
double get mouseWorldY => screenToWorldY(_mousePosition.y);
bool get fullScreenActive => document.fullscreenElement != null;

// global typedefs
typedef DrawCanvas(Canvas canvass, Size size);

// classes
abstract class KeyboardEventHandler {
  void onPressed(PhysicalKeyboardKey key);
  void onReleased(PhysicalKeyboardKey key);
  void onHeld(PhysicalKeyboardKey key, int frames);
}

class _Screen {
  double width = 0;
  double height = 0;
  double top = 0;
  double right = 0;
  double bottom = 0;
  double left = 0;
}