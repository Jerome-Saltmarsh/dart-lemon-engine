library lemon_engine;
import 'dart:convert';

import 'package:universal_html/html.dart';


import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'keycode.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_math/src.dart';
import 'package:lemon_watch/src.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_strategy/url_strategy.dart' as us;

/// boilerplate code for game development
///
///
/// __event-hooks__
///
/// event hooks start with the word 'on'
///
/// event hooks are safe to override
///
/// event hooks can be overridden during runtime
///
/// ```dart
/// Engine.onLeftClicked = () => print("left mouse clicked');
/// ```
///
/// __getting started__
/// ```dart
///void main() {
///   Engine.run(
///     title: "My Game Name",
///     buildUI: (BuildContext context) => Text("Welcome"),
///     backgroundColor: Colors.red,
///   );
/// }
/// ```
class Engine {
  // HOOKS
  /// the following hooks are designed to be easily swapped in and out without inheritance
  /// override safe. run this snippet inside your initialization code.
  /// engine.onTapDown = (TapDownDetails details) => print('tap detected');
  static GestureTapDownCallback? onTapDown;
  /// override safe
  static GestureTapCallback? onTap;
  /// override safe
  static GestureLongPressCallback? onLongPress;
  /// override safe
  static GestureLongPressDownCallback? onLongPressDown;
  /// override safe
  static GestureTapDownCallback? onSecondaryTapDown;
  /// override safe
  static CallbackOnScreenSizeChanged? onScreenSizeChanged;
  /// override safe
  static Function? onDispose;
  /// override safe
  static DrawCanvas? onDrawCanvas;
  /// override safe
  static DrawCanvas? onDrawCanvasForeground;
  /// override safe
  static DrawCanvas? onDrawForeground;
  /// override safe
  static Function? onLeftClicked;
  /// override safe
  static Function(PointerScrollEvent value)? onPointerScrolled;
  /// override safe
  static Function(PointerSignalEvent value)? onPointerSignalEvent;
  /// override safe
  static Function? onRightClicked;
  /// override safe
  static Function? onRightClickReleased;
  /// override safe
  static Function(SharedPreferences sharedPreferences)? onInit;
  /// override safe
  static Function? onUpdate;
  /// override safe
  /// gets called when update timer is changed
  static Function? onUpdateTimerReset;
  /// override safe
  static BasicWidgetBuilder? onBuildLoadingScreen;
  /// override safe
  static Function(Object error, StackTrace stack)? onError;

  // VARIABLES
  static List<Offset> touchPoints = [];
  static var touches = 0;
  static var touchDownId = 0;
  static var touchHeldId = 0;
  static late ui.Image _bufferImage;
  static var _bufferBlendMode = BlendMode.dstATop;
  static final keyState = <int, bool>{ };
  static final keyStateDuration = <int, int>{ };
  static final random = Random();
  static var textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr
  );
  static final Map<String, TextSpan> textSpans = {
  };
  static late Canvas canvas;

  static final paint = Paint()
    ..color = Colors.white
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill
    ..isAntiAlias = false
    ..strokeWidth = 1;

  static final spritePaint = Paint()
    ..color = Colors.white
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill
    ..isAntiAlias = false
    ..strokeWidth = 1;
  static Timer? updateTimer;
  static var scrollSensitivity = 0.0005;
  static var cameraSmoothFollow = true;
  static var zoomSensitivity = 0.175;
  static var targetZoom = 1.0;
  static var zoomOnScroll = true;
  static var mousePosition = Vector2(0, 0);
  static var previousMousePosition = Vector2(0, 0);
  static var mouseLeftDownFrames = 0;
  static var zoom = 1.0;
  static var drawCanvasAfterUpdate = true;
  static late BuildContext buildContext;
  static late final sharedPreferences;
  static final keyboardState = <LogicalKeyboardKey, int>{};
  static final themeData = Watch<ThemeData?>(null);
  static final fullScreen = Watch(false);
  static final deviceType = Watch(DeviceType.Computer);
  static final cursorType = Watch(CursorType.Precise);
  static final notifierPaintFrame = ValueNotifier<int>(0);
  static final notifierPaintForeground = ValueNotifier<int>(0);
  static final screen = _Screen();
  static final camera = Vector2(0, 0);
  /// triggered if the state of the key is down
  static void Function(int keyCode)? onKeyDown;
  /// triggered the first moment the key is pressed down
  static void Function(int keyCode)? onKeyPressed;
  /// triggered upon key release
  static void Function(int keyCode)? onKeyUp;

  // SETTERS
  static set bufferImage(ui.Image image){
    if (_bufferImage == image) return;
    flushBuffer();
    _bufferImage = image;
  }
  
  static set bufferBlendMode(BlendMode value){
    if (_bufferBlendMode == value) return;
    flushBuffer();
    _bufferBlendMode = value;
  }

  static set buildUI(WidgetBuilder? value) => watchBuildUI.value = value;
  static set title(String value) => watchTitle.value = value;
  static set backgroundColor(Color value) => watchBackgroundColor.value = value;

  // GETTERS
  static BlendMode get bufferBlendMode => _bufferBlendMode;
  static double get screenCenterRenderX => (Screen_Left + Screen_Right) * 0.5;
  static double get screenCenterRenderY => (Screen_Top + Screen_Bottom) * 0.5;
  static double get screenDiagonalLength => calculateHypotenuse(screen.width, screen.height);
  static double get screenArea => screen.width * screen.height;
  static WidgetBuilder? get buildUI => watchBuildUI.value;
  static String get title => watchTitle.value;
  static Color get backgroundColor => watchBackgroundColor.value;
  static bool get isLocalHost => Uri.base.host == 'localhost';
  static bool get deviceIsComputer => deviceType.value == DeviceType.Computer;
  static bool get deviceIsPhone => deviceType.value == DeviceType.Phone;
  static int get paintFrame => notifierPaintFrame.value;
  static bool get initialized => watchInitialized.value;

  // WATCHES
  static final watchBackgroundColor = Watch(Default_Background_Color);
  static final watchBuildUI = Watch<WidgetBuilder?>(null);
  static final watchTitle = Watch(Default_Title);
  static final watchInitialized = Watch(false);
  static final watchDurationPerFrame = Watch(Duration(milliseconds: Default_Milliseconds_Per_Frame));
  static final watchMouseLeftDown = Watch(false, onChanged: _internalOnChangedMouseLeftDown);
  static final mouseRightDown = Watch(false);

  // DEFAULTS
  static const Default_Milliseconds_Per_Frame = 30;
  static const Default_Background_Color = Colors.black;
  static const Default_Title = "DEMO";
  // CONSTANTS
  static const Milliseconds_Per_Second = 1000;
  static const PI = pi;
  static const PI_2 = pi + pi;
  static const PI_Half = pi * 0.5;
  static const PI_Quarter = pi * 0.25;
  static const PI_Eight = pi * 0.125;
  static const PI_SIXTEENTH = pi / 16;
  static const Ratio_Radians_To_Degrees = 57.2958;
  static const Ratio_Degrees_To_Radians = 0.0174533;
  static const GoldenRatio_1_618 = 1.61803398875;
  static const GoldenRatio_1_381 = 1.38196601125;
  static const GoldenRatio_0_618 = 0.61803398875;
  static const GoldenRatio_0_381 = 0.38196601125;

  static var Screen_Top = 0.0;
  static var Screen_Right = 0.0;
  static var Screen_Bottom = 0.0;
  static var Screen_Left = 0.0;

  static bool get keyPressedShiftLeft =>
      keyPressed(KeyCode.Shift_Left);

  static bool get keyPressedSpace =>
      keyPressed(KeyCode.Space);

  static bool keyPressed(int key) =>
      keyState[key] ?? false;

  static int getKeyDownDuration(int key) =>
    keyStateDuration[key] ?? 0;

  // static void _internalOnKeyboardEvent(RawKeyEvent event) {
  //   if (event is RawKeyDownEvent) {
  //     if (keyState[event.logicalKey] ?? false) {
  //       keyStateDuration[event.logicalKey] = getKeyDownDuration(event.logicalKey) + 1;
  //       onKeyHeld?.call(event, getKeyDownDuration(event.logicalKey));
  //     } else {
  //       keyState[event.logicalKey] = true;
  //       onKeyPressed?.call(event);
  //     }
  //     onKeyDown?.call(event);
  //     return;
  //   }
  //   if (event is RawKeyUpEvent) {
  //     keyState[event.logicalKey] = false;
  //     onKeyUp?.call(event);
  //     return;
  //   }
  // }

  static void _internalOnChangedMouseLeftDown(bool value){
    if (value) {
      onLeftClicked?.call();
    } else {
      mouseLeftDownFrames = 0;
    }
  }

  static void _internalSetScreenSize(double width, double height){
    if (screen.width == width && screen.height == height) return;
    if (!screen.initialized) {
      screen.width = width;
      screen.height = height;
      return;
    }
    final previousScreenWidth = screen.width;
    final previousScreenHeight = screen.height;
    screen.width = width;
    screen.height = height;
    onScreenSizeChanged!.call(
      previousScreenWidth,
      previousScreenHeight,
      screen.width,
      screen.height,
    );
  }

  // ACTIONS

  static void toggleDeviceType() =>
      deviceType.value =
      deviceIsComputer ? DeviceType.Phone : DeviceType.Computer;

  // static Future loadBufferImage(String filename) async {
  //   _bufferImage = await loadImageAsset(filename);
  // }

  static Future<ui.Image> loadImageAsset(String url) async {
    final byteData = await rootBundle.load(url);
    final bytes = Uint8List.view(byteData.buffer);
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  static TextSpan getTextSpan(String text) {
    var value = textSpans[text];
    if (value != null) return value;
    value = TextSpan(style: TextStyle(color: Colors.white), text: text);
    textSpans[text] = value;
    return value;
  }

  static void writeText(String text, double x, double y) {
    textPainter.text = getTextSpan(text);
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }

  static void run({
    required Function update,
    required DrawCanvas render,
    WidgetBuilder? buildUI,
    String title = Default_Title,
    Function(SharedPreferences sharedPreferences)? init,
    BasicWidgetBuilder? buildLoadingScreen,
    ThemeData? themeData,
    GestureTapDownCallback? onTapDown,
    GestureLongPressCallback? onLongPress,
    GestureDragStartCallback? onPanStart,
    GestureDragUpdateCallback? onPanUpdate,
    GestureDragEndCallback? onPanEnd,
    CallbackOnScreenSizeChanged? onScreenSizeChanged,
    Function? onDispose,
    DrawCanvas? onDrawForeground,
    Function? onKeyPressedSpace,
    Function? onLeftClicked,
    Function? onLongLeftClicked,
    Function(double value)? onMouseScroll,
    Function? onRightClicked,
    Function? onRightClickReleased,
    Function(SharedPreferences sharedPreferences)? onInit,
    Function(Object error, StackTrace stack)? onError,
    bool setPathUrlStrategy = true,
    Color backgroundColor = Default_Background_Color,
  }){
    print("engine.run()");
    Engine.watchTitle.value = title;
    Engine.onInit = init;
    Engine.onUpdate = update;
    Engine.watchBuildUI.value = buildUI;
    Engine.onBuildLoadingScreen = buildLoadingScreen;
    Engine.onDrawCanvas = render;
    Engine.onTapDown = onTapDown;
    Engine.onLongPress = onLongPress;
    Engine.onScreenSizeChanged = onScreenSizeChanged;
    Engine.onDispose = onDispose;
    Engine.onDrawCanvas = render;
    Engine.onDrawForeground = onDrawForeground;
    Engine.onLeftClicked = onLeftClicked;
    Engine.onPointerScrolled = onPointerScrolled;
    Engine.onRightClicked = onRightClicked;
    Engine.onRightClickReleased = onRightClickReleased;
    Engine.themeData.value = themeData;
    Engine.backgroundColor = backgroundColor;
    Engine.onError = onError;

    if (setPathUrlStrategy){
      us.setPathUrlStrategy();
    }
    WidgetsFlutterBinding.ensureInitialized();
    runZonedGuarded(_internalInit, _internalOnError);
  }

  static void _internalOnError(Object error, StackTrace stack) {
      if (onError != null){
        onError?.call(error, stack);
        return;
      }
      print("Warning no Engine.onError handler set");
      print(error);
      print(stack);
  }

  static void _internalOnPointerScrollEvent(PointerScrollEvent event) {
    if (zoomOnScroll) {
      targetZoom -=  event.scrollDelta.dy * scrollSensitivity;
      targetZoom = targetZoom.clamp(0.2, 6);
    }
    onPointerScrolled?.call(event);
  }

  static void renderText(String text, double x, double y,
      {Canvas? other, TextStyle? style}) =>
    renderTextSpan(
        TextSpan(style: style ?? const TextStyle(), text: text), x, y, other
    );

  static void renderTextSpan(TextSpan textSpan, double x, double y, Canvas? other) {
    textPainter.text = textSpan;
    textPainter.layout();
    textPainter.paint(other ?? canvas, Offset(x, y));
  }

  static void cameraFollow(double x, double y, double speed) {
    final diffX = screenCenterWorldX - x;
    final diffY = screenCenterWorldY - y;
    camera.x -= (diffX * 75) * speed;
    camera.y -= (diffY * 75) * speed;
  }

  static void cameraCenter(double x, double y) {
    camera.x = x - (screenCenterX / zoom);
    camera.y = y - (screenCenterY / zoom);
  }

  static void redrawCanvas() {
    notifierPaintFrame.value++;
  }

  static void refreshPage(){
    final window = document.window;
    if (window == null) return;
    final domain = document.domain;
    if (domain == null) return;
    window.location.href = domain;
  }

  static void fullscreenToggle()  =>
    fullScreenActive ? fullScreenExit() : fullScreenEnter();

  static void fullScreenExit() => document.exitFullscreen();

  static void fullScreenEnter() {
    final element = document.documentElement;
    if (element == null) {
      return;
    }
    try {
      element.requestFullscreen().catchError((error) {});
    } catch(error) {
      // ignore
    }
  }

  static void panCamera() {
    final positionX = screenToWorldX(mousePosition.x);
    final positionY = screenToWorldY(mousePosition.y);
    final previousX = screenToWorldX(previousMousePosition.x);
    final previousY = screenToWorldY(previousMousePosition.y);
    final diffX = previousX - positionX;
    final diffY = previousY - positionY;
    camera.x += diffX;
    camera.y += diffY;
  }

  static void disableRightClickContextMenu() {
    document.onContextMenu.listen((event) => event.preventDefault());
  }

  static void setPaintColorWhite() {
    paint.color = Colors.white;
  }

  static void setPaintStrokeWidth(double value) {
    paint.strokeWidth = value;
  }

  static void setPaintColor(Color value) {
    if (paint.color == value) return;
    paint.color = value;
  }

  static void _internalOnPointerMove(PointerMoveEvent event) {
    previousMousePosition.x = mousePosition.x;
    previousMousePosition.y = mousePosition.y;
    mousePosition.x = event.position.dx;
    mousePosition.y = event.position.dy;
  }

  static void _internalOnPointerHover(PointerHoverEvent event) {
    previousMousePosition.x = mousePosition.x;
    previousMousePosition.y = mousePosition.y;
    mousePosition.x = event.position.dx;
    mousePosition.y = event.position.dy;
    touchHeldId = event.pointer;
  }

  /// event.buttons is always 0 and does not seem to correspond to the left or right mouse
  /// click like in internalOnPointerDown
  static void _internalOnPointerUp(PointerUpEvent event) {
    watchMouseLeftDown.value = false;
    mouseRightDown.value = false;
  }

  static void _internalOnPointerDown(PointerDownEvent event) {
    // event.
    touchDownId = event.pointer;

    if (event.buttons == 1) {
      watchMouseLeftDown.value = true;
    }
    if (event.buttons == 2) {
      mouseRightDown.value = true;
    }
  }

  static void _internalOnPointerSignal(PointerSignalEvent pointerSignalEvent) {
    if (pointerSignalEvent is PointerScrollEvent) {
      _internalOnPointerScrollEvent(pointerSignalEvent);
    } else {
      onPointerSignalEvent?.call(pointerSignalEvent);
    }
  }

  static void _internalOnTapDown(TapDownDetails details){
     onTapDown?.call(details);
  }

  static void _internalOnScaleStart(ScaleStartDetails details){
    touches = details.pointerCount;
    touchPoints = [];
  }

  static void _internalOnScaleUpdate(ScaleUpdateDetails details) {
    // final _points = details.focalPoint - details.focalPointDelta;
    touchPoints = List.from(touchPoints)..add(details.focalPoint - details.focalPointDelta);
    touches = details.pointerCount;
  }

  static void _internalOnScaleEnd(ScaleEndDetails details){
    touches = details.pointerCount;
    touchPoints = [];
  }

  static void _internalOnTap(){
    onTap?.call();
  }

  static void _internalOnLongPress(){
    onLongPress?.call();
  }

  static void _internalOnLongPressDown(LongPressDownDetails details){
    onLongPressDown?.call(details);
  }

  static void _internalOnSecondaryTapDown(TapDownDetails details){
    onSecondaryTapDown?.call(details);
  }

  static void _internalPaint(Canvas canvas, Size size) {
    Engine.canvas = canvas;
    canvas.scale(zoom, zoom);
    canvas.translate(-camera.x, -camera.y);
    if (!initialized) return;
    if (onDrawCanvas == null) return;
    batchesRendered = 0;
    batches1Rendered = 0;
    batches2Rendered = 0;
    batches4Rendered = 0;
    batches8Rendered = 0;
    batches16Rendered = 0;
    batches32Rendered = 0;
    batches64Rendered = 0;
    batches128Rendered = 0;
    onDrawCanvas!.call(canvas, size);
    flushBuffer();
    assert(bufferIndex == 0);
  }

  static Duration buildDurationFramesPerSecond(int framesPerSecond) =>
    Duration(milliseconds: convertFramesPerSecondsToMilliseconds(framesPerSecond));

  static int convertFramesPerSecondsToMilliseconds(int framesPerSecond) =>
    Milliseconds_Per_Second ~/ framesPerSecond;

  static Future _internalInit() async {

    SystemChannels.keyEvent.setMessageHandler(_handleRawKeyMessage);
    runApp(_internalBuildApp());
    _bufferImage = await _generateEmptyImage();
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;

    mouseRightDown.onChanged((bool value) {
      if (value) {
        onRightClicked?.call();
      }
    });

    document.addEventListener('fullscreenchange', _internalOnFullScreenChanged);

    disableRightClickContextMenu();
    paint.isAntiAlias = false;
    Engine.sharedPreferences = await SharedPreferences.getInstance();
    if (onInit != null) {
      await onInit!(sharedPreferences);
    }
    updateTimer = Timer.periodic(
        watchDurationPerFrame.value,
        _internalOnUpdate,
    );
    watchInitialized.value = true;
  }

  static void _internalOnFullScreenChanged(event){
    fullScreen.value = fullScreenActive;
  }

  static void resetUpdateTimer(){
    updateTimer?.cancel();
    updateTimer = Timer.periodic(
      watchDurationPerFrame.value,
      _internalOnUpdate,
    );
    onUpdateTimerReset?.call();
  }

  static void _internalOnUpdate(Timer timer){
    Screen_Left = camera.x;
    Screen_Right = camera.x + (screen.width / zoom);
    Screen_Top = camera.y;
    Screen_Bottom = camera.y + (screen.height / zoom);
    if (watchMouseLeftDown.value) {
      mouseLeftDownFrames++;
    }
    deviceType.value =
      screenArea < 400000
        ? DeviceType.Phone
        : DeviceType.Computer;
    onUpdate?.call();
    final sX = screenCenterWorldX;
    final sY = screenCenterWorldY;
    final zoomDiff = targetZoom - zoom;
    zoom += zoomDiff * zoomSensitivity;
    cameraCenter(sX, sY);
    if (drawCanvasAfterUpdate) {
      redrawCanvas();
    }
  }

  void setFramesPerSecond(int framesPerSecond) =>
     watchDurationPerFrame.value = buildDurationFramesPerSecond(framesPerSecond);

  static ui.Image get bufferImage => _bufferImage;

  static var bufferIndex = 0;
  static var batchesRendered = 0;
  static var batches1Rendered = 0;
  static var batches2Rendered = 0;
  static var batches4Rendered = 0;
  static var batches8Rendered = 0;
  static var batches16Rendered = 0;
  static var batches32Rendered = 0;
  static var batches64Rendered = 0;
  static var batches128Rendered = 0;

  static final _bufferSrc1 = Float32List(1 * 4);
  static final _bufferDst1 = Float32List(1 * 4);
  static final _bufferClr1 = Int32List(1);

  static final _bufferSrc2 = Float32List(2 * 4);
  static final _bufferDst2 = Float32List(2 * 4);
  static final _bufferClr2 = Int32List(2);

  static final _bufferSrc4 = Float32List(4 * 4);
  static final _bufferDst4 = Float32List(4 * 4);
  static final _bufferClr4 = Int32List(4);

  static final _bufferSrc8 = Float32List(8 * 4);
  static final _bufferDst8 = Float32List(8 * 4);
  static final _bufferClr8 = Int32List(8);

  static final _bufferSrc16 = Float32List(16 * 4);
  static final _bufferDst16 = Float32List(16 * 4);
  static final _bufferClr16 = Int32List(16);

  static final _bufferSrc32 = Float32List(32 * 4);
  static final _bufferDst32 = Float32List(32 * 4);
  static final _bufferClr32 = Int32List(32);

  static final _bufferSrc64 = Float32List(64 * 4);
  static final _bufferDst64 = Float32List(64 * 4);
  static final _bufferClr64 = Int32List(64);

  static final _bufferSrc128 = Float32List(128 * 4);
  static final _bufferDst128 = Float32List(128 * 4);
  static final _bufferClr128 = Int32List(128);

  static final bufferSrc = _bufferSrc128;
  static final bufferDst = _bufferDst128;
  static final bufferClr = _bufferClr128;

  static void flushBuffer() {
    batchesRendered++;
    if (bufferIndex == 0) return;
    var flushIndex = 0;
    while (flushIndex < bufferIndex) {
      final remaining = bufferIndex - flushIndex;

      if (remaining == 0) {
        throw Exception();
      }

      if (remaining == 1) {
        final f = flushIndex << 2;
        _bufferClr1[0] = bufferClr[flushIndex];
        _bufferDst1[0] = bufferDst[f];
        _bufferDst1[1] = bufferDst[f + 1];
        _bufferDst1[2] = bufferDst[f + 2];
        _bufferDst1[3] = bufferDst[f + 3];
        _bufferSrc1[0] = bufferSrc[f];
        _bufferSrc1[1] = bufferSrc[f + 1];
        _bufferSrc1[2] = bufferSrc[f + 2];
        _bufferSrc1[3] = bufferSrc[f + 3];
        canvas.drawRawAtlas(_bufferImage, _bufferDst1, _bufferSrc1, _bufferClr1, _bufferBlendMode, null, spritePaint);
        bufferIndex = 0;
        batches1Rendered++;
        return;
      }

      if (remaining < 4) {
        for (var i = 0; i < 2; i++) {
          final j = i << 2;
          final f = flushIndex << 2;
          _bufferClr2[i] = bufferClr[flushIndex];
          _bufferDst2[j] = bufferDst[f];
          _bufferDst2[j + 1] = bufferDst[f + 1];
          _bufferDst2[j + 2] = bufferDst[f + 2];
          _bufferDst2[j + 3] = bufferDst[f + 3];
          _bufferSrc2[j] = bufferSrc[f];
          _bufferSrc2[j + 1] = bufferSrc[f + 1];
          _bufferSrc2[j + 2] = bufferSrc[f + 2];
          _bufferSrc2[j + 3] = bufferSrc[f + 3];
          flushIndex++;
        }
        canvas.drawRawAtlas(_bufferImage, _bufferDst2, _bufferSrc2, _bufferClr2, _bufferBlendMode, null, spritePaint);
        batches2Rendered++;
        continue;
      }

      if (remaining < 8) {
        for (var i = 0; i < 4; i++) {
          final j = i << 2;
          final f = flushIndex << 2;
          _bufferClr4[i] = bufferClr[flushIndex];
          _bufferDst4[j] = bufferDst[f];
          _bufferDst4[j + 1] = bufferDst[f + 1];
          _bufferDst4[j + 2] = bufferDst[f + 2];
          _bufferDst4[j + 3] = bufferDst[f + 3];
          _bufferSrc4[j] = bufferSrc[f];
          _bufferSrc4[j + 1] = bufferSrc[f + 1];
          _bufferSrc4[j + 2] = bufferSrc[f + 2];
          _bufferSrc4[j + 3] = bufferSrc[f + 3];
          flushIndex++;
        }
        canvas.drawRawAtlas(_bufferImage, _bufferDst4, _bufferSrc4, _bufferClr4, _bufferBlendMode, null, spritePaint);
        batches4Rendered++;
        continue;
      }

      if (remaining < 16) {
        for (var i = 0; i < 8; i++) {
          final j = i << 2;
          final f = flushIndex << 2;
          _bufferClr8[i] = bufferClr[flushIndex];
          _bufferDst8[j] = bufferDst[f];
          _bufferDst8[j + 1] = bufferDst[f + 1];
          _bufferDst8[j + 2] = bufferDst[f + 2];
          _bufferDst8[j + 3] = bufferDst[f + 3];
          _bufferSrc8[j] = bufferSrc[f];
          _bufferSrc8[j + 1] = bufferSrc[f + 1];
          _bufferSrc8[j + 2] = bufferSrc[f + 2];
          _bufferSrc8[j + 3] = bufferSrc[f + 3];
          flushIndex++;
        }
        canvas.drawRawAtlas(_bufferImage, _bufferDst8, _bufferSrc8, _bufferClr8, _bufferBlendMode, null, spritePaint);
        batches8Rendered++;
        continue;
      }

      if (remaining < 32) {
        for (var i = 0; i < 16; i++) {
          final j = i << 2;
          final f = flushIndex << 2;
          _bufferClr16[i] = bufferClr[flushIndex];
          _bufferDst16[j] = bufferDst[f];
          _bufferDst16[j + 1] = bufferDst[f + 1];
          _bufferDst16[j + 2] = bufferDst[f + 2];
          _bufferDst16[j + 3] = bufferDst[f + 3];
          _bufferSrc16[j] = bufferSrc[f];
          _bufferSrc16[j + 1] = bufferSrc[f + 1];
          _bufferSrc16[j + 2] = bufferSrc[f + 2];
          _bufferSrc16[j + 3] = bufferSrc[f + 3];
          flushIndex++;
        }
        canvas.drawRawAtlas(_bufferImage, _bufferDst16, _bufferSrc16, _bufferClr16, _bufferBlendMode, null, spritePaint);
        batches16Rendered++;
        continue;
      }

      if (remaining < 64) {
        for (var i = 0; i < 32; i++) {
          final j = i << 2;
          final f = flushIndex << 2;
          _bufferClr32[i] = bufferClr[flushIndex];
          _bufferDst32[j] = bufferDst[f];
          _bufferDst32[j + 1] = bufferDst[f + 1];
          _bufferDst32[j + 2] = bufferDst[f + 2];
          _bufferDst32[j + 3] = bufferDst[f + 3];
          _bufferSrc32[j] = bufferSrc[f];
          _bufferSrc32[j + 1] = bufferSrc[f + 1];
          _bufferSrc32[j + 2] = bufferSrc[f + 2];
          _bufferSrc32[j + 3] = bufferSrc[f + 3];
          flushIndex++;
        }
        canvas.drawRawAtlas(_bufferImage, _bufferDst32, _bufferSrc32, _bufferClr32, _bufferBlendMode, null, spritePaint);
        batches32Rendered++;
        continue;
      }

      if (remaining < 128) {
        for (var i = 0; i < 64; i++) {
          final j = i << 2;
          final f = flushIndex << 2;
          _bufferClr64[i] = bufferClr[flushIndex];
          _bufferDst64[j] = bufferDst[f];
          _bufferDst64[j + 1] = bufferDst[f + 1];
          _bufferDst64[j + 2] = bufferDst[f + 2];
          _bufferDst64[j + 3] = bufferDst[f + 3];
          _bufferSrc64[j] = bufferSrc[f];
          _bufferSrc64[j + 1] = bufferSrc[f + 1];
          _bufferSrc64[j + 2] = bufferSrc[f + 2];
          _bufferSrc64[j + 3] = bufferSrc[f + 3];
          flushIndex++;
        }
        canvas.drawRawAtlas(_bufferImage, _bufferDst64, _bufferSrc64, _bufferClr64, _bufferBlendMode, null, spritePaint);
        batches64Rendered++;
        continue;
      }

      throw Exception();
    }
    bufferIndex = 0;
  }

  static void flushAll(){
    batchesRendered++;
    canvas.drawRawAtlas(_bufferImage, bufferDst, bufferSrc, bufferClr, _bufferBlendMode, null, spritePaint);
    bufferIndex = 0;
    batches128Rendered++;
  }

  static void renderSprite({
    required ui.Image image,
    required double srcX,
    required double srcY,
    required double srcWidth,
    required double srcHeight,
    required double dstX,
    required double dstY,
    double anchorX = 0.5,
    double anchorY = 0.5,
    double scale = 1.0,
    int color = 1,
  }){
    bufferImage = image;
    final f = bufferIndex << 2;
    bufferClr[bufferIndex] = color;
    bufferSrc[f] = srcX;
    bufferSrc[f + 1] = srcY;
    bufferSrc[f + 2] = srcX + srcWidth;
    bufferSrc[f + 3] = srcY + srcHeight;
    bufferDst[f] = scale;
    bufferDst[f + 1] = 0;
    bufferDst[f + 2] = dstX - (srcWidth * anchorX * scale);
    bufferDst[f + 3] = dstY - (srcHeight * anchorY * scale);
    incrementBufferIndex();
  }

  /// The anchor determines the point around which the sprite is rotated
  static void renderSpriteRotated({
    required ui.Image image,
    required double srcX,
    required double srcY,
    required double srcWidth,
    required double srcHeight,
    required double dstX,
    required double dstY,
    required double rotation,
    double anchorX = 0.5,
    double anchorY = 0.5,
    double scale = 1.0,
    int color = 1,
  }){
    final scos = cos(rotation) * scale;
    final ssin = sin(rotation) * scale;

    final width = -scos * anchorX + ssin * anchorY;
    final height = -ssin * anchorX - scos * anchorY;

    final tx = dstX + width;
    final ty = dstY + height;

    final scaledHeight = srcHeight * scale * anchorY;
    final scaledWidth = srcWidth * scale * anchorX;

    final adjX = getAdjacent(rotation - piHalf, scaledHeight);
    final adjY = getOpposite(rotation - piHalf, scaledHeight);

    final adjY2 = getAdjacent(rotation - piHalf, scaledWidth);
    final adjX2 = getOpposite(rotation - piHalf, scaledWidth);

    bufferImage = image;
    final f = bufferIndex << 2;
    bufferClr[bufferIndex] = color;
    bufferSrc[f + 0] = srcX;
    bufferSrc[f + 1] = srcY;
    bufferSrc[f + 2] = srcX + srcWidth;
    bufferSrc[f + 3] = srcY + srcHeight;
    bufferDst[f + 0] = cos(rotation) * scale;
    bufferDst[f + 1] = sin(rotation) * scale;
    bufferDst[f + 2] = tx + adjX2 + adjX;
    bufferDst[f + 3] = ty - adjY2 + adjY;
    incrementBufferIndex();
  }

  static void renderExternalCanvas({
    required Canvas canvas,
    required ui.Image image,
    required double srcX,
    required double srcY,
    required double srcWidth,
    required double srcHeight,
    required double dstX,
    required double dstY,
    double anchorX = 0.5,
    double anchorY = 0.5,
    double scale = 1.0,
    int color = 1,
  }){
    _bufferClr1[0] = color;
    _bufferSrc1[0] = srcX;
    _bufferSrc1[1] = srcY;
    _bufferSrc1[2] = srcX + srcWidth;
    _bufferSrc1[3] = srcY + srcHeight;
    _bufferDst1[0] = scale;
    _bufferDst1[1] = 0;
    _bufferDst1[2] = dstX - (srcWidth * anchorX * scale);
    _bufferDst1[3] = dstY - (srcHeight * anchorY * scale); // scale
    canvas.drawRawAtlas(image, _bufferDst1, _bufferSrc1, _bufferClr1, _bufferBlendMode, null, paint);
  }

  static void renderCircle(double x, double y, double radius, Color color) {
    renderCircleOffset(Offset(x, y), radius, color);
  }

  static void renderCircleOffset(Offset offset, double radius, Color color) {
    setPaintColor(color);
    canvas.drawCircle(offset, radius, paint);
  }

  static void renderLine(double x1, double y1, double x2, double y2){
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
  }

  static void renderCircleOutline({
    required double radius,
    required double x,
    required double y,
    required Color color,
    int sides = 6,
    double width = 3,
  }) {
    double r = (pi * 2) / sides;
    List<Offset> points = [];
    Offset z = Offset(x, y);
    setPaintColor(color);
    paint.strokeWidth = width;

    for (int i = 0; i <= sides; i++) {
      double a1 = i * r;
      points.add(Offset(cos(a1) * radius, sin(a1) * radius));
    }
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i] + z, points[i + 1] + z, Engine.paint);
    }
  }

  static Future<Map<String, dynamic>> _handleRawKeyMessage(dynamic message) async {
    // print('handleRawKeyMessage($message)');
    final type = message['type'];
    final int keyCode = message['keyCode'];
    if (type == 'keydown') {
      if (keyState[keyCode] == true){
        onKeyDown?.call(keyCode);
      } else {
        keyState[keyCode] = true;
        onKeyPressed?.call(keyCode);
      }
    } else
    if (type == 'keyup') {
      keyState[keyCode] = false;
      onKeyUp?.call(keyCode);
    }
    return const {'handled': true};
  }


  static Widget _internalBuildApp(){
    return WatchBuilder(themeData, (ThemeData? themeData){
      return MaterialApp(
        title: title,
        // routes: Engine.routes ?? {},
        theme: themeData,
        home: Scaffold(
          body: WatchBuilder(watchInitialized, (bool value) {
            if (!value) {
              return onBuildLoadingScreen != null ? onBuildLoadingScreen!() : Center(child: Text("Loading"));
            }
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                _internalSetScreenSize(constraints.maxWidth, constraints.maxHeight);
                buildContext = context;
                return Stack(
                  children: [
                    _internalBuildCanvas(context),
                    WatchBuilder(watchBuildUI, (WidgetBuilder? buildUI)
                    => buildUI != null ? buildUI(context) : const SizedBox()
                    )
                  ],
                );
              },
            );
          }),
        ),
        debugShowCheckedModeBanner: false,
      );
    });
  }

  static Widget _internalBuildCanvas(BuildContext context) {
    final child = Listener(
      onPointerDown: _internalOnPointerDown,
      onPointerMove: _internalOnPointerMove,
      onPointerUp: _internalOnPointerUp,
      onPointerHover: _internalOnPointerHover,
      onPointerSignal: _internalOnPointerSignal,
      child: GestureDetector(
          onScaleStart: _internalOnScaleStart,
          onScaleUpdate: _internalOnScaleUpdate,
          onScaleEnd: _internalOnScaleEnd,
          onTapDown: _internalOnTapDown,
          onTap: _internalOnTap,
          onLongPress: _internalOnLongPress,
          onLongPressDown: _internalOnLongPressDown,
          // onPanStart: _internalOnPanStart,
          // onPanUpdate: _internalOnPanUpdate,
          // onPanEnd: _internalOnPanEnd,
          onSecondaryTapDown: _internalOnSecondaryTapDown,
          child: WatchBuilder(watchBackgroundColor, (Color backgroundColor){
            return Container(
                color: backgroundColor,
                width: screen.width,
                height: screen.height,
                child: CustomPaint(
                  isComplex: true,
                  willChange: true,
                  painter: _EnginePainter(repaint: notifierPaintFrame),
                  foregroundPainter: _EngineForegroundPainter(
                      repaint: notifierPaintForeground
                  ),
                )
            );
          })),
    );

    return WatchBuilder(Engine.cursorType, (CursorType cursorType) =>
        MouseRegion(
          cursor: _internalMapCursorTypeToSystemMouseCursor(cursorType),
          child: child,
        )
    );
  }

  static double calculateDistance(double x1, double y1, double x2, double y2) =>
      calculateHypotenuse(x1 - x2, y1 - y2);

  static double calculateHypotenuse(num adjacent, num opposite) =>
     sqrt((adjacent * adjacent) + (opposite * opposite));

  static double calculateAngle(double adjacent, double opposite) {
    final angle = atan2(opposite, adjacent);
    return angle < 0 ? PI_2 + angle : angle;
  }

  static double calculateAngleBetween(double x1, double y1, double x2, double y2) {
    return calculateAngle(x1 - x2, y1 - y2);
  }

  static double calculateAdjacent(double radians, double magnitude) =>
    cos(radians) * magnitude;

  static double calculateOpposite(double radians, double magnitude) =>
    sin(radians) * magnitude;

  static T clamp<T extends num>(T value, T min, T max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static void insertionSort<E>(List<E> list, {
    required bool Function(E, E) compare,
    int start = 0,
    int? end,
  }) {
    end ??= list.length;
    for (var pos = start + 1; pos < end; pos++) {
      var min = start;
      var max = pos;
      var element = list[pos];
      while (min < max) {
        var mid = min + ((max - min) >> 1);
        // var comparison = ;
        if (compare(element, list[mid])) {
          max = mid;
        } else {
          min = mid + 1;
        }
      }
      list.setRange(min + 1, pos + 1, list, min);
      list[min] = element;
    }
  }


  static double calculateRadianDifference(double a, double b){
    final diff = b - a;
    if (diff > pi) {
      return -(PI_2 - diff);
    }
    if (diff < -pi){
      return PI_2 + diff;
    }
    return diff;
  }

  static bool isNullOrEmpty(String? value) =>
     value == null || value.isEmpty;

  static int randomInt(int min, int max) => random.nextInt(max - min) + min;

  /// Returns a random radian between 0 and pi2
  static double randomAngle() => random.nextDouble() * pi2;

  static T randomItem<T>(List<T> list) => list[random.nextInt(list.length)];

  static double randomGiveOrTake(num value) =>
    randomBetween(-value, value);

  static double randomBetween(num a, num b) =>
    (random.nextDouble() * (b - a)) + a;

  static bool randomBool() =>
    random.nextDouble() > 0.5;

  static SystemMouseCursor _internalMapCursorTypeToSystemMouseCursor(CursorType value){
    switch (value) {
      case CursorType.Forbidden:
        return SystemMouseCursors.forbidden;
      case CursorType.Precise:
        return SystemMouseCursors.precise;
      case CursorType.None:
        return SystemMouseCursors.none;
      case CursorType.Click:
        return SystemMouseCursors.click;
      default:
        return SystemMouseCursors.basic;
    }
  }

  static void drawLine(double x1, double y1, double x2, double y2) =>
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);

  static bool get fullScreenActive => document.fullscreenElement != null;

  static double screenToWorldX(double value)  =>
    camera.x + value / zoom;

  static double screenToWorldY(double value) =>
    camera.y + value / zoom;

  static double worldToScreenX(double x) =>
    zoom * (x - camera.x);

  static double worldToScreenY(double y) =>
    zoom * (y - camera.y);

  static double get screenCenterX => screen.width * 0.5;
  static double get screenCenterY => screen.height * 0.5;
  static double get screenCenterWorldX => screenToWorldX(screenCenterX);
  static double get screenCenterWorldY => screenToWorldY(screenCenterY);
  static double get mouseWorldX => screenToWorldX(mousePosition.x);
  static double get mouseWorldY => screenToWorldY(mousePosition.y);

  static double distanceFromMouse(double x, double y) =>
     calculateDistance(mouseWorldX, mouseWorldY, x, y);

  static void requestPointerLock() {
    var canvas = document.getElementById('canvas');
    if (canvas != null) {
      canvas.requestPointerLock();
    }
  }

  static  void setDocumentTitle(String value){
    document.title = value;
  }


  static void setFavicon(String filename){
    final link = document.querySelector("link[rel*='icon']");
    if (link == null) return;
    print("setFavicon($filename)");
    link.setAttribute("type", 'image/x-icon');
    link.setAttribute("rel", 'shortcut icon');
    link.setAttribute("href", filename);
    document.getElementsByTagName('head')[0].append(link);
  }

  static void setCursorWait(){
    setCursorByName('wait');
  }

  static void setCursorPointer(){
    setCursorByName('default');
  }

  static void setCursorByName(String name){
    final body = document.body;
    if (body == null) return;
    body.style.cursor = name;
  }

  static int linerInterpolationInt(int a, int b, double t) =>
      (a * (1.0 - t) + b * t).toInt();

  static void downloadString({
    required String contents,
    required String filename,
  }) =>
      downloadBytes(utf8.encode(contents), name: filename);

  static void downloadBytes(
      List<int> bytes, {
        required String name,
      }) {
    final _base64 = base64Encode(bytes);
    final anchor =
    AnchorElement(href: 'data:application/octet-stream;base64,$_base64')
      ..target = 'blank';
    anchor.download = name;
    document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    return;
  }

  static String enumString(dynamic value){
    final text = value.toString();
    final index = text.indexOf(".");
    if (index == -1) return text;
    return text.substring(index + 1, text.length).replaceAll("_", " ");
  }

  static void incrementBufferIndex(){
    Engine.bufferIndex++;
    if (Engine.bufferIndex == 128) {
      Engine.flushAll();
    }
  }

  static Future<ui.Image> _generateEmptyImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, 1, 1), Paint());
    final picture = recorder.endRecording();
    return await picture.toImage(1, 1);
  }

  static Widget buildAtlasImageButton({
    required ui.Image image,
    required double srcX,
    required double srcY,
    required double srcWidth,
    required double srcHeight,
    required Function? action,
    int color = 1,
    double scale = 1.0,
    String hint = "",
  }) =>
      buildOnPressed(
        action: action,
        hint: hint,
        child: buildAtlasImage(
          image: image,
          srcX: srcX,
          srcY: srcY,
          srcWidth: srcWidth,
          srcHeight: srcHeight,
          scale: scale,
          color: color,
        ),
      );

  static Widget buildAtlasImage({
    required ui.Image image,
    required double srcX,
    required double srcY,
    required double srcWidth,
    required double srcHeight,
    double scale = 1.0,
    int color = 1,
  }) =>
      Container(
        alignment: Alignment.center,
        width: srcWidth * scale,
        height: srcHeight * scale,
        child: buildCanvas(
            paint: (Canvas canvas, Size size) =>
                Engine.renderExternalCanvas(
                  canvas: canvas,
                  image: image,
                  srcX: srcX,
                  srcY: srcY,
                  srcWidth: srcWidth,
                  srcHeight: srcHeight,
                  dstX: 0,
                  dstY: 0,
                  scale: scale,
                  color: color,
                )
        ),
      );

  static Widget buildOnPressed({
    required Widget child,
    Function? action,
    Function? onRightClick,
    dynamic hint,
  }) {
    final widget = MouseRegion(
        cursor: action != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: child,
            onSecondaryTap: onRightClick != null ? (){
              onRightClick.call();
            } : null,
            onTap: (){
              if (action == null) return;
              action();
            }
        ));

    if (hint == null) return widget;

    return Tooltip(
      message: hint.toString(),
      child: widget,
    );
  }

  static Widget buildCanvas({
    required PaintCanvas paint,
    ValueNotifier<int>? frame,
    ShouldRepaint? shouldRepaint,
  }){
    return CustomPaint(
      painter: CustomPainterPainter(
          paint,
          shouldRepaint ?? _doNotRepaint,
          frame
      ),
    );
  }

  static bool _doNotRepaint(CustomPainter oldDelegate) {
    return false;
  }
}



typedef CallbackOnScreenSizeChanged = void Function(
    double previousWidth,
    double previousHeight,
    double newWidth,
    double newHeight,
);

// global typedefs
typedef DrawCanvas(Canvas canvas, Size size);

class _Screen {
  var initialized = false;
  var width = 0.0;
  var height = 0.0;
}

class DeviceType {
  static final Phone = 0;
  static final Computer = 1;

  static String getName(int value){
    if (value == Phone){
      return "Phone";
    }
    if (value == Computer){
      return "Computer";
    }
    return "unknown-device-type($value)";
  }
}

enum CursorType {
  None,
  Basic,
  Forbidden,
  Precise,
  Click,
}

class _EnginePainter extends CustomPainter {

  const _EnginePainter({required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas _canvas, Size size) {
    Engine._internalPaint(_canvas, size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _EngineForegroundPainter extends CustomPainter {

  const _EngineForegroundPainter({required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas _canvas, Size _size) {
    Engine.onDrawForeground?.call(Engine.canvas, _size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// TYPEDEFS
typedef BasicWidgetBuilder = Widget Function();
typedef CallbackOnJoystickEngaged = void Function(double angle, double distance);



typedef PaintCanvas = void Function(Canvas canvas, Size size);
typedef ShouldRepaint = bool Function(CustomPainter oldDelegate);

class CustomPainterPainter extends CustomPainter {

  final PaintCanvas paintCanvas;
  final ShouldRepaint doRepaint;

  CustomPainterPainter(this.paintCanvas, this.doRepaint, ValueNotifier<int>? frame) : super(repaint: frame);

  @override
  void paint(Canvas canvas, Size size) {
    return paintCanvas(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return doRepaint(oldDelegate);
  }
}

