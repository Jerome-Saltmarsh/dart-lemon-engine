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

final _camera = engine.camera;
final engine = _Engine();

class _Engine {

  static const _indexesPerBuffer = 4;

  int bufferIndex = 0;
  final int buffers = 400;
  late int bufferSize;
  late final Float32List src;
  late final Float32List dst;
  late final Int32List colors;

  late final srcFlush = Float32List(4);
  late final dstFlush = Float32List(4);

  final callbacks = LemonEngineCallbacks();
  final draw = LemonEngineDraw();
  late final LemonEngineEvents events;
  var scrollSensitivity = 0.0005;
  late ui.Image image;
  var cameraSmoothFollow = true;
  var zoomSensitivity = 0.1;
  var targetZoom = 1.0;
  final Map<LogicalKeyboardKey, int> keyboardState = {};
  var mousePosition = Vector2(0, 0);
  var previousMousePosition = Vector2(0, 0);
  var previousUpdateTime = DateTime.now();
  final mouseLeftDown = Watch(false);
  var mouseLeftDownFrames = 0;
  final Watch<int> fps = Watch(0);
  final Watch<Color> backgroundColor = Watch(Colors.white);
  final Watch<ThemeData?> themeData = Watch(null);
  var millisecondsSinceLastFrame = 50;
  var drawCanvasAfterUpdate = true;
  final drawFrame = ValueNotifier<int>(0);
  final _Screen screen = _Screen();
  final initialized = Watch(false);
  final Watch<CursorType> cursorType = Watch(CursorType.Precise);
  late BuildContext buildContext;
  var mouseDragging = false;
  final camera = Vector2(0, 0);
  var zoom = 1.0;
  final drawCanvas = Watch<DrawCanvas?>(null);
  final drawForeground = Watch<DrawCanvas?>(null);
  Function? update;
  late Canvas canvas;
  var animationFrame = 0;
  var framesPerAnimationFrame = 5;
  
  var paint = Paint()
    ..color = Colors.white
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill
    ..isAntiAlias = false
    ..strokeWidth = 1;
  var textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr
  );

  final Map<String, TextSpan> textSpans = {

  };

  void updateEngine(){
    const _padding = 48.0;
    _screen.left = _camera.x - _padding;
    _screen.right = _camera.x + (_screen.width / engine.zoom) + _padding;
    _screen.top = _camera.y - _padding;
    _screen.bottom = _camera.y + (_screen.height / engine.zoom) + _padding;

    if (engine.mouseLeftDown.value) {
      engine.mouseLeftDownFrames++;
    }

    if (engine.frame % engine.framesPerAnimationFrame == 0){
      engine.animationFrame++;
    }

    engine.update?.call();
    final sX = screenCenterWorldX;
    final sY = screenCenterWorldY;
    final zoomDiff = engine.targetZoom - engine.zoom;
    engine.zoom += zoomDiff * engine.zoomSensitivity;
    engine.cameraCenter(sX, sY);

    if (engine.drawCanvasAfterUpdate) {
      engine.redrawCanvas();
    }

  }

  TextSpan getTextSpan(String text){
    var value = textSpans[text];
    if (value != null) return value;
    value = TextSpan(style: TextStyle(color: Colors.white), text: text);
    textSpans[text] = value;
    return value;
  }
  
  void writeText(String text, double x, double y){
    textPainter.text = getTextSpan(text);
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }

  Map<LogicalKeyboardKey, Function> keyPressedHandlers = {};
  Map<LogicalKeyboardKey, Function> keyReleasedHandlers = {};

  int get frame => drawFrame.value;
  
  
  _Engine(){
    WidgetsFlutterBinding.ensureInitialized();
    bufferSize = buffers * _indexesPerBuffer;
    src = Float32List(bufferSize);
    dst = Float32List(bufferSize);
    colors = Int32List(buffers);
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
    events = LemonEngineEvents();
    RawKeyboard.instance.addListener(events.onKeyboardEvent);
    registerZoomCameraOnMouseScroll();
  }

  void registerZoomCameraOnMouseScroll(){
    callbacks.onMouseScroll = events.onMouseScroll;
  }

  void mapSrc8({
    required double x,
    required double y,
  }){
    final i = bufferIndex * _indexesPerBuffer;
    src[i] = x;
    src[i + 1] = y;
    src[i + 2] = x + 8;
    src[i + 3] = y + 8;
  }

  void mapSrcSquare({
    required double x,
    required double y,
    required double size,
  }){
    final i = bufferIndex * _indexesPerBuffer;
    src[i] = x;
    src[i + 1] = y;
    src[i + 2] = x + size;
    src[i + 3] = y + size;
  }

  void mapSrc({
    required double x,
    required double y,
    required double width,
    required double height
  }){
    final i = bufferIndex * _indexesPerBuffer;
    src[i] = x;
    src[i + 1] = y;
    src[i + 2] = x + width;
    src[i + 3] = y + height;
  }

  void mapSrc48({
    required double x,
    required double y,
  }){
    final i = bufferIndex * _indexesPerBuffer;
    src[i] = x;
    src[i + 1] = y;
    src[i + 2] = x + 48.0;
    src[i + 3] = y + 48.0;
  }

  /// Prevents the stack from adding two variables each mapping
  void mapSrc64({
    required double x,
    required double y,
  }){
    final i = bufferIndex * _indexesPerBuffer;
    src[i] = x;
    src[i + 1] = y;
    src[i + 2] = x + 64.0;
    src[i + 3] = y + 64.0;
  }

  void mapSrc32({
    required double x,
    required double y,
  }){
    final i = bufferIndex * _indexesPerBuffer;
    src[i] = x;
    src[i + 1] = y;
    src[i + 2] = x + 32.0;
    src[i + 3] = y + 32.0;
  }

  void mapSrc96({
    required double x,
    required double y,
  }){
    final i = bufferIndex * _indexesPerBuffer;
    src[i] = x;
    src[i + 1] = y;
    src[i + 2] = x + 96.0;
    src[i + 3] = y + 96.0;
  }
  
  void mapColor(Color color){
    colors[bufferIndex] = color.value;
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

  void render({
    required double dstX, 
    required double dstY, 
    required double srcX, 
    required double srcY,
    double srcSize = 64.0,
    double scale = 1.0,
    double rotation = 0.0,
    double anchorX = 0.5,
    double anchorY = 0.5,
  }){
    mapDst(
        x: dstX, 
        y: dstY, 
        scale: scale, 
        rotation: rotation, 
        anchorX: srcSize * anchorX, 
        anchorY: srcSize * anchorY
    );
    mapSrc(
        x: srcX, 
        y: srcY, 
        width: srcSize, 
        height: srcSize
    );
    renderAtlas();
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
    final end = bufferIndex;
    for (var i = 0; i < end; i++) {
      final j = i * 4;
      srcFlush[0] = src[j];
      srcFlush[1] = src[j + 1];
      srcFlush[2] = src[j + 2];
      srcFlush[3] = src[j + 3];
      dstFlush[0] = dst[j]; // scale
      dstFlush[1] = dst[j + 1]; // scale
      dstFlush[2] = dst[j + 2]; // scale
      dstFlush[3] = dst[j + 3]; // scale
      canvas.drawRawAtlas(image, dstFlush, srcFlush, null, null, null, paint);
    }
    bufferIndex = 0;
  }

  void cameraFollow(double x, double y, double speed){
    final diffX = screenCenterWorldX - x;
    final diffY = screenCenterWorldY - y;
    camera.x -= (diffX * 75) * speed;
    camera.y -= (diffY * 75) * speed;
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

final keyboardInstance = RawKeyboard.instance;

// global utilities
bool keyPressed(LogicalKeyboardKey key) {
  return keyboardInstance.keysPressed.contains(key);
}

double screenToWorldX(double value) {
  return _camera.x + value / engine.zoom;
}

double screenToWorldY(double value) {
  return _camera.y + value / engine.zoom;
}

double worldToScreenX(double x) {
  return engine.zoom * (x - _camera.x);
}

double worldToScreenY(double y) {
  return engine.zoom * (y - _camera.y);
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
typedef DrawCanvas(Canvas canvas, Size size);

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

  bool contains(double x, double y) {
    return
      x > left
          &&
      x < right
          &&
      y > top
          &&
      y < bottom
    ;
  }

  bool containsV(Vector2 value) {
    return
      value.x > left
          &&
      value.x < right
          &&
      value.y > top
          &&
      value.y < bottom
    ;
  }
}