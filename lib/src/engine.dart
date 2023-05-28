library lemon_engine;
import 'dart:convert';

import 'package:lemon_engine/src/math.dart';
import 'package:universal_html/html.dart';

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'keycode.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_watch/src.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_strategy/url_strategy.dart' as us;

class Engine {

  // HOOKS
  /// the following hooks are designed to be easily swapped in and out without inheritance
  /// override safe. run this snippet inside your initialization code.
  /// this.onTapDown = (TapDownDetails details) => print('tap detected');
  GestureTapDownCallback? onTapDown;
  /// override safe
  GestureTapCallback? onTap;
  /// override safe
  GestureLongPressCallback? onLongPress;
  /// override safe
  GestureLongPressDownCallback? onLongPressDown;
  /// override safe
  GestureTapDownCallback? onSecondaryTapDown;
  /// override safe
  CallbackOnScreenSizeChanged? onScreenSizeChanged;
  /// override safe
  Function? onDispose;
  /// override safe
  DrawCanvas? onDrawCanvas;
  /// override safe
  DrawCanvas? onDrawForeground;
  /// override safe
  Function? onLeftClicked;
  /// override safe
  Function(double x, double y)? onMouseMoved;
  /// override safe
  Function(PointerScrollEvent value)? onPointerScrolled;
  /// override safe
  Function(PointerSignalEvent value)? onPointerSignalEvent;
  /// override safe
  Function? onRightClicked;
  /// override safe
  Function? onRightClickReleased;
  /// override safe
  Function(SharedPreferences sharedPreferences)? onInit;
  /// override safe
  Function? onUpdate;
  /// override safe
  /// gets called when update timer is changed
  Function? onUpdateTimerReset;
  /// override safe
  BasicWidgetBuilder? onBuildLoadingScreen;
  /// override safe
  Function(Object error, StackTrace stack)? onError;

  // VARIABLES
  List<Offset> touchPoints = [];
  var touches = 0;
  var touchDownId = 0;
  var touchHeldId = 0;
  late ui.Image _bufferImage;
  var _bufferBlendMode = BlendMode.dstATop;
  final keyState = <int, bool>{ };
  final keyStateDuration = <int, int>{ };
  static final random = Random();
  var textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr
  );
  final Map<String, TextSpan> textSpans = {
  };
  late Canvas canvas;

  final paint = Paint()
    ..color = Colors.white
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill
    ..isAntiAlias = false
    ..strokeWidth = 1;

  final spritePaint = Paint()
    ..color = Colors.white
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill
    ..isAntiAlias = false
    ..strokeWidth = 1;
  Timer? updateTimer;
  var scrollSensitivity = 0.0005;
  var cameraSmoothFollow = true;
  var zoomSensitivity = 0.175;
  var targetZoom = 1.0;
  var zoomOnScroll = true;
  var mousePositionX = 0.0;
  var mousePositionY = 0.0;
  var previousMousePositionX = 0.0;
  var previousMousePositionY = 0.0;
  var mouseLeftDownFrames = 0;
  var zoom = 1.0;
  var drawCanvasAfterUpdate = true;
  late BuildContext buildContext;
  late final sharedPreferences;
  final keyboardState = <LogicalKeyboardKey, int>{};
  final themeData = Watch<ThemeData?>(null);
  final fullScreen = Watch(false);
  final deviceType = Watch(DeviceType.Computer);
  final cursorType = Watch(CursorType.Precise);
  final notifierPaintFrame = ValueNotifier<int>(0);
  final notifierPaintForeground = ValueNotifier<int>(0);
  final screen = _Screen();
  var cameraX = 0.0;
  var cameraY = 0.0;

  /// triggered if the state of the key is down
  void Function(int keyCode)? onKeyDown;
  /// triggered the first moment the key is pressed down
  void Function(int keyCode)? onKeyPressed;
  /// triggered upon key release
  void Function(int keyCode)? onKeyUp;

  // SETTERS
  set bufferImage(ui.Image image){
    if (_bufferImage == image) return;
    flushBuffer();
    _bufferImage = image;
  }
  
  set bufferBlendMode(BlendMode value){
    if (_bufferBlendMode == value) return;
    flushBuffer();
    _bufferBlendMode = value;
  }

  set buildUI(WidgetBuilder? value) => watchBuildUI.value = value;
  set title(String value) => watchTitle.value = value;
  set backgroundColor(Color value) => watchBackgroundColor.value = value;

  // GETTERS
  BlendMode get bufferBlendMode => _bufferBlendMode;
  double get screenCenterRenderX => (Screen_Left + Screen_Right) * 0.5;
  double get screenCenterRenderY => (Screen_Top + Screen_Bottom) * 0.5;
  double get screenDiagonalLength => hyp(screen.width, screen.height);
  double get screenArea => screen.width * screen.height;
  WidgetBuilder? get buildUI => watchBuildUI.value;
  String get title => watchTitle.value;
  Color get backgroundColor => watchBackgroundColor.value;
  bool get isLocalHost => Uri.base.host == 'localhost';
  bool get deviceIsComputer => deviceType.value == DeviceType.Computer;
  bool get deviceIsPhone => deviceType.value == DeviceType.Phone;
  int get paintFrame => notifierPaintFrame.value;
  bool get initialized => watchInitialized.value;

  // WATCHES
  final watchBackgroundColor = Watch(Default_Background_Color);
  final watchBuildUI = Watch<WidgetBuilder?>(null);
  final watchTitle = Watch(Default_Title);
  final watchInitialized = Watch(false);
  final watchDurationPerFrame = Watch(Duration(milliseconds: Default_Milliseconds_Per_Frame));
  late final watchMouseLeftDown = Watch(false, onChanged: _internalOnChangedMouseLeftDown);
  final mouseRightDown = Watch(false);

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

  var Screen_Top = 0.0;
  var Screen_Right = 0.0;
  var Screen_Bottom = 0.0;
  var Screen_Left = 0.0;

  bool get keyPressedShiftLeft =>
      keyPressed(KeyCode.Shift_Left);

  bool get keyPressedSpace =>
      keyPressed(KeyCode.Space);

  bool keyPressed(int key) =>
      keyState[key] ?? false;

  int getKeyDownDuration(int key) =>
    keyStateDuration[key] ?? 0;

  void _internalOnChangedMouseLeftDown(bool value){
    if (value) {
      onLeftClicked?.call();
    } else {
      mouseLeftDownFrames = 0;
    }
  }

  void _internalSetScreenSize(double width, double height){
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

  void toggleDeviceType() =>
      deviceType.value =
      deviceIsComputer ? DeviceType.Phone : DeviceType.Computer;

  static Future<ui.Image> loadImageAsset(String url) async {
    final byteData = await rootBundle.load(url);
    final bytes = Uint8List.view(byteData.buffer);
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  TextSpan getTextSpan(String text) {
    var value = textSpans[text];
    if (value != null) return value;
    value = TextSpan(style: TextStyle(color: Colors.white), text: text);
    textSpans[text] = value;
    return value;
  }

  void writeText(String text, double x, double y) {
    textPainter.text = getTextSpan(text);
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }

  void run({
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
    Function? onLeftClicked,
    Function? onRightClicked,
    Function? onRightClickReleased,
    Function(int keyCode)? onKeyPressed,
    Function(int keyCode)? onKeyDown,
    Function(int keyCode)? onKeyUp,
    Function(double x, double y)? onMouseMoved,
    Function(PointerScrollEvent value)? onMouseScroll,
    Function(SharedPreferences sharedPreferences)? onInit,
    Function(Object error, StackTrace stack)? onError,
    bool setPathUrlStrategy = true,
    Color backgroundColor = Default_Background_Color,
  }){
    print("this.run()");
    this.watchTitle.value = title;
    this.onInit = init;
    this.onUpdate = update;
    this.watchBuildUI.value = buildUI;
    this.onBuildLoadingScreen = buildLoadingScreen;
    this.onDrawCanvas = render;
    this.onTapDown = onTapDown;
    this.onLongPress = onLongPress;
    this.onScreenSizeChanged = onScreenSizeChanged;
    this.onDispose = onDispose;
    this.onDrawCanvas = render;
    this.onDrawForeground = onDrawForeground;
    this.onLeftClicked = onLeftClicked;
    this.onKeyPressed = onKeyPressed;
    this.onKeyDown = onKeyDown;
    this.onKeyUp = onKeyUp;
    this.onPointerScrolled = onMouseScroll;
    this.onMouseMoved = onMouseMoved;
    this.onRightClicked = onRightClicked;
    this.onRightClickReleased = onRightClickReleased;
    this.themeData.value = themeData;
    this.backgroundColor = backgroundColor;
    this.onError = onError;

    if (setPathUrlStrategy){
      us.setPathUrlStrategy();
    }
    WidgetsFlutterBinding.ensureInitialized();
    runZonedGuarded(_internalInit, _internalOnError);
  }

  void _internalOnError(Object error, StackTrace stack) {
      if (onError != null){
        onError?.call(error, stack);
        return;
      }
      print("Warning no this.onError handler set");
      print(error);
      print(stack);
  }

  void _internalOnPointerScrollEvent(PointerScrollEvent event) {
    if (zoomOnScroll) {
      targetZoom -=  event.scrollDelta.dy * scrollSensitivity;
      targetZoom = targetZoom.clamp(0.2, 6);
    }
    onPointerScrolled?.call(event);
  }

  void renderText(String text, double x, double y,
      {Canvas? other, TextStyle? style}) =>
    renderTextSpan(
        TextSpan(style: style ?? const TextStyle(), text: text), x, y, other
    );

  void renderTextSpan(TextSpan textSpan, double x, double y, Canvas? other) {
    textPainter.text = textSpan;
    textPainter.layout();
    textPainter.paint(other ?? canvas, Offset(x, y));
  }

  void cameraFollow(double x, double y, [double speed = 0.00075]) {
    final diffX = screenCenterWorldX - x;
    final diffY = screenCenterWorldY - y;
    cameraX -= (diffX * 75) * speed;
    cameraY -= (diffY * 75) * speed;
  }

  void cameraCenter(double x, double y) {
    cameraX = x - (screenCenterX / zoom);
    cameraY = y - (screenCenterY / zoom);
  }

  void redrawCanvas() {
    notifierPaintFrame.value++;
  }

  void refreshPage(){
    final window = document.window;
    if (window == null) return;
    final domain = document.domain;
    if (domain == null) return;
    window.location.href = domain;
  }

  void fullscreenToggle()  =>
    fullScreenActive ? fullScreenExit() : fullScreenEnter();

  void fullScreenExit() => document.exitFullscreen();

  void fullScreenEnter() {
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

  void panCamera() {
    final positionX = screenToWorldX(mousePositionX);
    final positionY = screenToWorldY(mousePositionY);
    final previousX = screenToWorldX(previousMousePositionX);
    final previousY = screenToWorldY(previousMousePositionY);
    final diffX = previousX - positionX;
    final diffY = previousY - positionY;
    cameraX += diffX;
    cameraY += diffY;
  }

  void disableRightClickContextMenu() {
    document.onContextMenu.listen((event) => event.preventDefault());
  }

  void setPaintColorWhite() {
    paint.color = Colors.white;
  }

  void setPaintStrokeWidth(double value) {
    paint.strokeWidth = value;
  }

  void setPaintColor(Color value) {
    if (paint.color == value) return;
    paint.color = value;
  }

  void _internalOnPointerMove(PointerMoveEvent event) {
    previousMousePositionX = mousePositionX;
    previousMousePositionY = mousePositionY;
    mousePositionX = event.position.dx;
    mousePositionY = event.position.dy;
    onMouseMoved?.call(mousePositionX, mousePositionY);
  }

  void _internalOnPointerHover(PointerHoverEvent event) {
    previousMousePositionX = mousePositionX;
    previousMousePositionY = mousePositionY;
    mousePositionX = event.position.dx;
    mousePositionY = event.position.dy;
    touchHeldId = event.pointer;
    onMouseMoved?.call(mousePositionX, mousePositionY);
  }

  /// event.buttons is always 0 and does not seem to correspond to the left or right mouse
  /// click like in internalOnPointerDown
  void _internalOnPointerUp(PointerUpEvent event) {
    watchMouseLeftDown.value = false;
    mouseRightDown.value = false;
  }

  void _internalOnPointerDown(PointerDownEvent event) {
    previousMousePositionX = mousePositionX;
    previousMousePositionY = mousePositionY;
    mousePositionX = event.position.dx;
    mousePositionY = event.position.dy;
    touchDownId = event.pointer;

    if (event.buttons == 1) {
      watchMouseLeftDown.value = true;
    }
    if (event.buttons == 2) {
      mouseRightDown.value = true;
    }
  }

  void _internalOnPointerSignal(PointerSignalEvent pointerSignalEvent) {
    if (pointerSignalEvent is PointerScrollEvent) {
      _internalOnPointerScrollEvent(pointerSignalEvent);
    } else {
      onPointerSignalEvent?.call(pointerSignalEvent);
    }
  }

  void _internalOnTapDown(TapDownDetails details){
     onTapDown?.call(details);
  }

  void _internalOnScaleStart(ScaleStartDetails details){
    touches = details.pointerCount;
    touchPoints = [];
  }

  void _internalOnScaleUpdate(ScaleUpdateDetails details) {
    // final _points = details.focalPoint - details.focalPointDelta;
    touchPoints = List.from(touchPoints)..add(details.focalPoint - details.focalPointDelta);
    touches = details.pointerCount;
  }

  void _internalOnScaleEnd(ScaleEndDetails details){
    touches = details.pointerCount;
    touchPoints = [];
  }

  void _internalOnTap(){
    onTap?.call();
  }

  void _internalOnLongPress(){
    onLongPress?.call();
  }

  void _internalOnLongPressDown(LongPressDownDetails details){
    onLongPressDown?.call(details);
  }

  void _internalOnSecondaryTapDown(TapDownDetails details){
    onSecondaryTapDown?.call(details);
  }

  void _internalPaint(Canvas canvas, Size size) {
    this.canvas = canvas;
    canvas.scale(zoom, zoom);
    canvas.translate(-cameraX, -cameraY);
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

  Duration buildDurationFramesPerSecond(int framesPerSecond) =>
    Duration(milliseconds: convertFramesPerSecondsToMilliseconds(framesPerSecond));

  int convertFramesPerSecondsToMilliseconds(int framesPerSecond) =>
    Milliseconds_Per_Second ~/ framesPerSecond;

  Future _internalInit() async {

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
    this.sharedPreferences = await SharedPreferences.getInstance();
    if (onInit != null) {
      await onInit!(sharedPreferences);
    }
    updateTimer = Timer.periodic(
        watchDurationPerFrame.value,
        _internalOnUpdate,
    );
    watchInitialized.value = true;
  }

  void _internalOnFullScreenChanged(event){
    fullScreen.value = fullScreenActive;
  }

  void resetUpdateTimer(){
    updateTimer?.cancel();
    updateTimer = Timer.periodic(
      watchDurationPerFrame.value,
      _internalOnUpdate,
    );
    onUpdateTimerReset?.call();
  }

  void _internalOnUpdate(Timer timer){
    Screen_Left = cameraX;
    Screen_Right = cameraX + (screen.width / zoom);
    Screen_Top = cameraY;
    Screen_Bottom = cameraY + (screen.height / zoom);
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

  ui.Image get bufferImage => _bufferImage;

  var bufferIndex = 0;
  var batchesRendered = 0;
  var batches1Rendered = 0;
  var batches2Rendered = 0;
  var batches4Rendered = 0;
  var batches8Rendered = 0;
  var batches16Rendered = 0;
  var batches32Rendered = 0;
  var batches64Rendered = 0;
  var batches128Rendered = 0;

  final _bufferSrc1 = Float32List(1 * 4);
  final _bufferDst1 = Float32List(1 * 4);
  final _bufferClr1 = Int32List(1);

  final _bufferSrc2 = Float32List(2 * 4);
  final _bufferDst2 = Float32List(2 * 4);
  final _bufferClr2 = Int32List(2);

  final _bufferSrc4 = Float32List(4 * 4);
  final _bufferDst4 = Float32List(4 * 4);
  final _bufferClr4 = Int32List(4);

  final _bufferSrc8 = Float32List(8 * 4);
  final _bufferDst8 = Float32List(8 * 4);
  final _bufferClr8 = Int32List(8);

  final _bufferSrc16 = Float32List(16 * 4);
  final _bufferDst16 = Float32List(16 * 4);
  final _bufferClr16 = Int32List(16);

  final _bufferSrc32 = Float32List(32 * 4);
  final _bufferDst32 = Float32List(32 * 4);
  final _bufferClr32 = Int32List(32);

  final _bufferSrc64 = Float32List(64 * 4);
  final _bufferDst64 = Float32List(64 * 4);
  final _bufferClr64 = Int32List(64);

  final _bufferSrc128 = Float32List(128 * 4);
  final _bufferDst128 = Float32List(128 * 4);
  final _bufferClr128 = Int32List(128);

  late final bufferSrc = _bufferSrc128;
  late final bufferDst = _bufferDst128;
  late final bufferClr = _bufferClr128;

  void flushBuffer() {
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

  void flushAll(){
    batchesRendered++;
    canvas.drawRawAtlas(_bufferImage, bufferDst, bufferSrc, bufferClr, _bufferBlendMode, null, spritePaint);
    bufferIndex = 0;
    batches128Rendered++;
  }

  void renderSprite({
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
  void renderSpriteRotated({
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

    const piHalf = pi * 0.5;

    final adjX = adj(rotation - piHalf, scaledHeight);
    final adjY = opp(rotation - piHalf, scaledHeight);

    final adjY2 = adj(rotation - piHalf, scaledWidth);
    final adjX2 = opp(rotation - piHalf, scaledWidth);

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

  void renderExternalCanvas({
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

  void renderCircle(double x, double y, double radius, Color color) {
    renderCircleOffset(Offset(x, y), radius, color);
  }

  void renderCircleOffset(Offset offset, double radius, Color color) {
    setPaintColor(color);
    canvas.drawCircle(offset, radius, paint);
  }

  void renderLine(double x1, double y1, double x2, double y2){
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
  }

  void renderCircleOutline({
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
      canvas.drawLine(points[i] + z, points[i + 1] + z, this.paint);
    }
  }

  Future<Map<String, dynamic>> _handleRawKeyMessage(dynamic message) async {
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


  Widget _internalBuildApp(){
    return WatchBuilder(themeData, (ThemeData? themeData){
      return MaterialApp(
        title: title,
        // routes: this.routes ?? {},
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

  Widget _internalBuildCanvas(BuildContext context) {
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
          onSecondaryTapDown: _internalOnSecondaryTapDown,
          child: WatchBuilder(watchBackgroundColor, (Color backgroundColor){
            return Container(
                color: backgroundColor,
                width: screen.width,
                height: screen.height,
                child: CustomPaint(
                  isComplex: true,
                  willChange: true,
                  painter: _EnginePainter(repaint: notifierPaintFrame, engine: this),
                  foregroundPainter: _EngineForegroundPainter(
                      repaint: notifierPaintForeground,
                      engine: this,
                  ),
                )
            );
          })),
    );

    return WatchBuilder(this.cursorType, (CursorType cursorType) =>
        MouseRegion(
          cursor: _internalMapCursorTypeToSystemMouseCursor(cursorType),
          child: child,
        )
    );
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


  double calculateRadianDifference(double a, double b){
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
  static double randomAngle() {
    const pi2 = pi + pi;
    return random.nextDouble() * pi2;
  }

  static T randomItem<T>(List<T> list) => list[random.nextInt(list.length)];

  static double randomGiveOrTake(num value) =>
    randomBetween(-value, value);

  static double randomBetween(num a, num b) =>
    (random.nextDouble() * (b - a)) + a;

  static bool randomBool() =>
    random.nextDouble() > 0.5;

  SystemMouseCursor _internalMapCursorTypeToSystemMouseCursor(CursorType value){
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

  void drawLine(double x1, double y1, double x2, double y2) =>
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);

  bool get fullScreenActive => document.fullscreenElement != null;

  double screenToWorldX(double value)  =>
    cameraX + value / zoom;

  double screenToWorldY(double value) =>
    cameraY + value / zoom;

  double worldToScreenX(double x) =>
    zoom * (x - cameraX);

  double worldToScreenY(double y) =>
    zoom * (y - cameraY);

  double get screenCenterX => screen.width * 0.5;
  double get screenCenterY => screen.height * 0.5;
  double get screenCenterWorldX => screenToWorldX(screenCenterX);
  double get screenCenterWorldY => screenToWorldY(screenCenterY);
  double get mouseWorldX => screenToWorldX(mousePositionX);
  double get mouseWorldY => screenToWorldY(mousePositionY);

  double distanceFromMouse(double x, double y) =>
     distance(mouseWorldX, mouseWorldY, x, y);

  void requestPointerLock() {
    var canvas = document.getElementById('canvas');
    if (canvas != null) {
      canvas.requestPointerLock();
    }
  }

   void setDocumentTitle(String value){
    document.title = value;
  }

  void setFavicon(String filename){
    final link = document.querySelector("link[rel*='icon']");
    if (link == null) return;
    print("setFavicon($filename)");
    link.setAttribute("type", 'image/x-icon');
    link.setAttribute("rel", 'shortcut icon');
    link.setAttribute("href", filename);
    document.getElementsByTagName('head')[0].append(link);
  }

  void setCursorWait(){
    setCursorByName('wait');
  }

  void setCursorPointer(){
    setCursorByName('default');
  }

  void setCursorByName(String name){
    final body = document.body;
    if (body == null) return;
    body.style.cursor = name;
  }

  static int linerInterpolationInt(int a, int b, double t) =>
      (a * (1.0 - t) + b * t).toInt();

  void downloadString({
    required String contents,
    required String filename,
  }) =>
      downloadBytes(utf8.encode(contents), name: filename);

  void downloadBytes(
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

  String enumString(dynamic value){
    final text = value.toString();
    final index = text.indexOf(".");
    if (index == -1) return text;
    return text.substring(index + 1, text.length).replaceAll("_", " ");
  }

  void incrementBufferIndex(){
    this.bufferIndex++;
    if (this.bufferIndex == 128) {
      this.flushAll();
    }
  }

  Future<ui.Image> _generateEmptyImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, 1, 1), Paint());
    final picture = recorder.endRecording();
    return await picture.toImage(1, 1);
  }

  Widget buildAtlasImageButton({
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

  Widget buildAtlasImage({
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
                this.renderExternalCanvas(
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

  Widget buildOnPressed({
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

  Widget buildCanvas({
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

  bool _doNotRepaint(CustomPainter oldDelegate) {
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

  final Engine engine;

  const _EnginePainter({required Listenable repaint, required this.engine})
      : super(repaint: repaint);

  @override
  void paint(Canvas _canvas, Size size) {
    engine._internalPaint(_canvas, size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _EngineForegroundPainter extends CustomPainter {

  final Engine engine;

  const _EngineForegroundPainter({required Listenable repaint, required this.engine})
      : super(repaint: repaint);

  @override
  void paint(Canvas _canvas, Size _size) {
    engine.onDrawForeground?.call(_canvas, _size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// TYPEDEFS
typedef BasicWidgetBuilder = Widget Function();
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

