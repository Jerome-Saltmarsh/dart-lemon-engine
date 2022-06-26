library lemon_engine;

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_engine/callbacks.dart';
import 'package:lemon_engine/draw.dart';
import 'package:lemon_engine/enums.dart';
import 'package:lemon_engine/events.dart';
import 'package:lemon_math/library.dart';
import 'package:lemon_watch/watch.dart';
import 'package:universal_html/html.dart';

import 'canvas.dart';
import 'render.dart';

final _camera = engine.camera;
final engine = _Engine();

class _Engine {

  final callbacks = LemonEngineCallbacks();
  final draw = LemonEngineDraw();
  late final LemonEngineEvents events;
  var scrollSensitivity = 0.0005;
  late ui.Image atlas;
  var cameraSmoothFollow = true;
  var zoomSensitivity = 0.1;
  var targetZoom = 1.0;

  final Map<LogicalKeyboardKey, int> keyboardState = {};
  var mousePosition = Vector2(0, 0);
  var previousMousePosition = Vector2(0, 0);
  var previousUpdateTime = DateTime.now();
  final mouseLeftDown = Watch(false, onChanged: (bool value){
    if (value){
      if (onLeftClicked != null){
        onLeftClicked!();
      }
    }
  });
  final mouseRightDown = Watch(false);
  var mouseLeftDownFrames = 0;
  final Watch<int> fps = Watch(0);
  final Watch<Color> backgroundColor = Watch(Colors.white);
  final Watch<ThemeData?> themeData = Watch(null);
  final fullScreen = Watch(false);
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
  
  Future loadAtlas(String filename) async{
      atlas = await loadImage(filename);
  }

  void updateEngine(){
    const _padding = 48.0;
    _screen.left = _camera.x - _padding;
    _screen.right = _camera.x + (_screen.width / engine.zoom) + _padding;
    _screen.top = _camera.y - _padding;
    _screen.bottom = _camera.y + (_screen.height / engine.zoom) + _padding;

    if (engine.mouseLeftDown.value) {
      engine.mouseLeftDownFrames++;
    }

    

    // if (engine.frame % engine.framesPerAnimationFrame == 0){
    //   engine.animationFrame++;
    // }

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

  var keyPressedHandlers = <LogicalKeyboardKey, Function>{};
  var keyReleasedHandlers = <LogicalKeyboardKey, Function>{};

  int get frame => drawFrame.value;

  _Engine(){
    WidgetsFlutterBinding.ensureInitialized();
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
    events = LemonEngineEvents();
    RawKeyboard.instance.addListener(events.onKeyboardEvent);
    registerZoomCameraOnMouseScroll();

    mouseLeftDown.onChanged((bool leftDown) {
       if (!leftDown) mouseLeftDownFrames = 0;
    });
    
    mouseRightDown.onChanged((bool value) {
      if (value) {
        callbacks.onRightClicked?.call();
      }
    });

    document.onFullscreenChange.listen((event) {
       fullScreen.value = fullScreenActive;
    });

    loadAtlas('images/atlas.png');
  }

  void registerZoomCameraOnMouseScroll(){
    callbacks.onMouseScroll = events.onMouseScroll;
  }

  void mapColor(Color color){
    colors[bufferIndex] = color.value;
  }

  void renderText(String text, double x, double y, {Canvas? other, TextStyle? style}) {
    textPainter.text = TextSpan(style: style ?? const TextStyle(), text: text);
    textPainter.layout();
    textPainter.paint(other ?? canvas, Offset(x, y));
  }

  void renderAtlas(){
    canvas.drawRawAtlas(atlas, dst, src, colors, renderBlendMode, null, paint);
  }

  /// If there are draw jobs remaining in the buffer
  /// it draws them and clears the rest
  void flushRenderBuffer(){
    for (var i = 0; i < bufferIndex;) {
      colorsFlush[0] = colors[i ~/ 4];
      srcFlush[0] = src[i];
      dstFlush[0] = dst[i];
      i++;
      srcFlush[1] = src[i];
      dstFlush[1] = dst[i]; // scale
      i++;
      srcFlush[2] = src[i];
      dstFlush[2] = dst[i];
      i++;
      srcFlush[3] = src[i]; // scale
      dstFlush[3] = dst[i]; // scale
      i++;
      canvas.drawRawAtlas(atlas, dstFlush, srcFlush, colorsFlush, renderBlendMode, null, paint);
    }
    bufferIndex = 0;
    renderIndex = 0;
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
    // camera.x += diffX * zoom;
    // camera.y += diffY * zoom;
    camera.x += diffX;
    camera.y += diffY;
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

  bool containsV(Position value) {
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