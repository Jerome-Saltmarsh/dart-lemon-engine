import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_engine/lemon_engine.dart';
import 'package:lemon_engine/src/math.dart';
import 'package:lemon_watch/src.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

class Engine extends StatelessWidget {

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
  Function(double delta)? onUpdate;
  /// override safe
  /// gets called when update timer is changed
  Function? onUpdateDurationChanged;
  /// override safe
  Function? onMouseEnterCanvas;
  /// override safe
  Function? onMouseExitCanvas;
  /// triggered if the state of the key is down
  void Function(int keyCode)? onKeyDown;
  /// triggered the first moment the key is pressed down
  void Function(int keyCode)? onKeyPressed;
  /// triggered upon key release
  void Function(int keyCode)? onKeyUp;
  /// override safe
  Function? dispose;
  /// override safe
  WidgetBuilder loadingScreenBuilder = (context) => Text("LOADING");
  /// override safe
  Function(Object error, StackTrace stack)? onError;

  /// milliseconds elapsed since last render frame
  final msRender = Watch(0);
  /// milliseconds elapsed since last update frame
  final msUpdate = Watch(0);
  List<Offset> touchPoints = [];
  final keyState = <int, bool>{ };
  final renderFramesSkipped = Watch(0);
  final keyStateDuration = <int, int>{ };
  final Map<String, TextSpan> textSpans = {
  };

  final paint = Paint()
    ..color = Colors.white
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill
    ..isAntiAlias = false
    ..strokeWidth = 1;

  Timer? updateTimer;

  final keyboardState = <LogicalKeyboardKey, int>{};
  final themeData = Watch<ThemeData?>(null);
  final fullScreen = Watch(false);
  final deviceType = Watch(DeviceType.Computer);
  final cursorType = Watch(CursorType.Precise);
  final notifierPaintFrame = ValueNotifier<int>(0);
  final notifierPaintForeground = ValueNotifier<int>(0);
  final screen = Screen();

  late BuildContext buildContext;
  late Canvas canvas;
  late ui.Image _bufferImage;

  late final sharedPreferences;

  var _bufferBlendMode = BlendMode.dstATop;

  var textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr
  );
  var lastRenderTime = DateTime.now();
  var lastUpdateTime = DateTime.now();
  var minMSPerRender = 5;
  var mouseOverCanvas = false;
  var touches = 0;
  var touchDownId = 0;
  var touchHeldId = 0;
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
  var cameraX = 0.0;
  var cameraY = 0.0;
  var updateFrame = 0;
  var Screen_Top = 0.0;
  var Screen_Right = 0.0;
  var Screen_Bottom = 0.0;
  var Screen_Left = 0.0;

  final _renderCirclePositions = Float32List(_renderCircleSegments * 6);

  final watchBackgroundColor = Watch(Default_Background_Color);
  final watchBuildUI = Watch<WidgetBuilder?>(null);
  final watchTitle = Watch(Default_Title);

  late final durationPerUpdate = Watch(
      Default_Duration_Per_Update,
      onChanged: onChangedDurationPerUpdate,
  );

  late final watchMouseLeftDown = Watch(false, onChanged: _internalOnChangedMouseLeftDown);
  final mouseRightDown = Watch(false);

  // DEFAULTS
  static const _renderCircleSegments = 24;
  static const Default_Background_Color = Colors.black;
  static const Default_Duration_Per_Update = Duration(milliseconds: 40);
  static const Default_Title = "DEMO";

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
  
  void setBlendModeModulate(){
    bufferBlendMode = BlendMode.modulate;
  }
  
  void setBlendModeDstATop(){
    bufferBlendMode = BlendMode.dstATop;
  }

  set buildUI(WidgetBuilder? value) => watchBuildUI.value = value;

  set title(String value) => watchTitle.value = value;

  set backgroundColor(Color value) => watchBackgroundColor.value = value;

  set color(Color value){
    if (color == value)
      return;

    paint.color = value;
    flushBuffer();
  }

  Color get color => paint.color;

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

  Engine({
    required Function(double delta) update,
    required DrawCanvas render,
    WidgetBuilder? buildUI,
    String title = Default_Title,
    Function(SharedPreferences sharedPreferences)? init,
    WidgetBuilder? buildLoadingScreen,
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
    this.dispose,
    Function(int keyCode)? onKeyPressed,
    Function(int keyCode)? onKeyDown,
    Function(int keyCode)? onKeyUp,
    Function(double x, double y)? onMouseMoved,
    Function(PointerScrollEvent value)? onMouseScroll,
    Function(SharedPreferences sharedPreferences)? onInit,
    Function(Object error, StackTrace stack)? onError,
    bool setPathUrlStrategy = true,
    Color backgroundColor = Default_Background_Color,
    Duration? durationPerUpdate = Default_Duration_Per_Update,
  }){
    this.watchTitle.value = title;
    this.onInit = init;
    this.onUpdate = update;
    this.watchBuildUI.value = buildUI;
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

    if (buildLoadingScreen != null){
      this.loadingScreenBuilder = buildLoadingScreen;
    }

    // if (setPathUrlStrategy){
    //   us.setPathUrlStrategy();
    // }
    // WidgetsFlutterBinding.ensureInitialized();
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
    final now = DateTime.now();
    final duration = now.difference(lastRenderTime);
    if (duration.inMilliseconds < minMSPerRender){
      renderFramesSkipped.value++;
      return;
    }

    lastRenderTime = now;
    notifierPaintFrame.value++;
    msRender.value = duration.inMilliseconds;
  }

  void refreshPage(){
    final window = html.document.window;
    if (window == null) return;
    final domain = html.document.domain;
    if (domain == null) return;
    window.location.href = domain;
  }

  void fullscreenToggle()  =>
    fullScreenActive ? fullScreenExit() : fullScreenEnter();

  void fullScreenExit() => html.document.exitFullscreen();

  void fullScreenEnter() => html.document.documentElement?.requestFullscreen();

  void panCamera() {
    final positionX = screenToWorldX(mousePositionX);
    final positionY = screenToWorldY(mousePositionY);
    final previousX = screenToWorldX(previousMousePositionX);
    final previousY = screenToWorldY(previousMousePositionY);
    final diffX = (previousX - positionX) * zoom;
    final diffY = (previousY - positionY) * zoom;
    cameraX += diffX;
    cameraY += diffY;
  }

  void disableRightClickContextMenu() {
    html.document.onContextMenu.listen((event) => event.preventDefault());
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
    Duration.millisecondsPerSecond ~/ framesPerSecond;

  var _initCallAmount = 0;

  void enableKeyEventHandler(){
    SystemChannels.keyEvent.setMessageHandler(_handleRawKeyMessage);
  }

  void disableKeyEventHandler(){
    SystemChannels.keyEvent.setMessageHandler(null);
  }

  Future _internalInit() async {
    _initCallAmount++;
    print("engine.internalInit()");
    if (_initCallAmount > 1){
      print('engine - warning init called ${_initCallAmount}');
      return;
    }
    enableKeyEventHandler();
    _bufferImage = await _generateEmptyImage();
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;

    mouseRightDown.onChanged((bool value) {
      if (value) {
        onRightClicked?.call();
      }
    });

    html.document.addEventListener('fullscreenchange', _internalOnFullScreenChanged);

    disableRightClickContextMenu();
    paint.isAntiAlias = false;
    this.sharedPreferences = await SharedPreferences.getInstance();
    if (onInit != null) {
      await onInit!(sharedPreferences);
    }
    durationPerUpdate.value = Default_Duration_Per_Update;

    if (!internalBuildCreated){
      internalBuild = _internalBuildApp();
      internalBuildCreated = true;
    }
    app.value = internalBuild;


  }

  void _internalOnFullScreenChanged(event){
    fullScreen.value = fullScreenActive;
  }

  void _internalOnUpdate(Timer timer){
    final now = DateTime.now();
    final updateDuration = now.difference(lastUpdateTime);
    msUpdate.value = updateDuration.inMilliseconds;
    lastUpdateTime = now;

    updateFrame++;
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

    final durationPerUpdateMS = durationPerUpdate.value.inMilliseconds;
    onUpdate?.call(updateDuration.inMilliseconds / (durationPerUpdateMS > 0 ? durationPerUpdateMS : 1));
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
     durationPerUpdate.value = buildDurationFramesPerSecond(framesPerSecond);

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

    if (this.bufferIndex == 0)
      return;

    var flushIndex = 0;

    final bufferDst = this.bufferDst;
    final bufferSrc = this.bufferSrc;
    final bufferClr = this.bufferClr;
    final image = this.bufferImage;
    final blendMode = this.bufferBlendMode;
    final paint = this.paint;
    final canvas = this.canvas;

    final bufferIndex = this.bufferIndex;

    while (flushIndex < bufferIndex) {
      final remaining = bufferIndex - flushIndex;
      assert (remaining > 0);

      if (remaining == 1) {
        final f = flushIndex << 2;
        _bufferClr1[0] = bufferClr[flushIndex];
        _bufferDst1.setRange(0, 4, bufferDst, f);
        _bufferSrc1.setRange(0, 4, bufferSrc, f);
        canvas.drawRawAtlas(
          image,
          _bufferDst1,
          _bufferSrc1,
          _bufferClr1,
          blendMode,
          null,
          paint,
        );
        this.bufferIndex = 0;
        batches1Rendered++;
        return;
      }

      if (remaining < 4) {
        for (var i = 0; i < 2; i++) {
          final start = i << 2;
          final end = start + 4;
          final f = flushIndex << 2;
          _bufferClr2[i] = bufferClr[flushIndex];
          _bufferDst2.setRange(start, end, bufferDst, f);
          _bufferSrc2.setRange(start, end, bufferSrc, f);
          flushIndex++;
        }
        canvas.drawRawAtlas(
          image,
          _bufferDst2,
          _bufferSrc2,
          _bufferClr2,
          blendMode,
          null,
          paint,
        );
        batches2Rendered++;
        continue;
      }

      if (remaining < 8) {
        final clr = _bufferClr4;
        final dst = _bufferDst4;
        final src = _bufferSrc4;
        for (var i = 0; i < 4; i++) {
          final start = i << 2;
          final end = start + 4;
          final f = flushIndex << 2;
          clr[i] = bufferClr[flushIndex];
          dst.setRange(start, end, bufferDst, f);
          src.setRange(start, end, bufferSrc, f);
          flushIndex++;
        }
        canvas.drawRawAtlas(
          image,
          dst,
          src,
          clr,
          blendMode,
          null,
          paint,
        );
        batches4Rendered++;
        continue;
      }

      if (remaining < 16) {
        final clr = _bufferClr8;
        final dst = _bufferDst8;
        final src = _bufferSrc8;
        for (var i = 0; i < 8; i++) {
          final start = i << 2;
          final end = start + 4;
          final f = flushIndex << 2;
          clr[i] = bufferClr[flushIndex];
          dst.setRange(start, end, bufferDst, f);
          src.setRange(start, end, bufferSrc, f);
          flushIndex++;
        }
        canvas.drawRawAtlas(
          image,
          dst,
          src,
          clr,
          blendMode,
          null,
          paint,
        );
        batches8Rendered++;
        continue;
      }

      if (remaining < 32) {
        final clr = _bufferClr16;
        final dst = _bufferDst16;
        final src = _bufferSrc16;
        for (var i = 0; i < 16; i++) {
          final start = i << 2;
          final end = start + 4;
          final f = flushIndex << 2;
          clr[i] = bufferClr[flushIndex];
          dst.setRange(start, end, bufferDst, f);
          src.setRange(start, end, bufferSrc, f);
          flushIndex++;
        }
        canvas.drawRawAtlas(
          image,
          dst,
          src,
          clr,
          blendMode,
          null,
          paint,
        );
        batches16Rendered++;
        continue;
      }

      if (remaining < 64) {
        final clr = _bufferClr32;
        final dst = _bufferDst32;
        final src = _bufferSrc32;
        for (var i = 0; i < 32; i++) {
          final start = i << 2;
          final end = start + 4;
          final f = flushIndex << 2;
          clr[i] = bufferClr[flushIndex];
          dst.setRange(start, end, bufferDst, f);
          src.setRange(start, end, bufferSrc, f);
          flushIndex++;
        }
        canvas.drawRawAtlas(
          image,
          dst,
          src,
          clr,
          blendMode,
          null,
          paint,
        );
        batches32Rendered++;
        continue;
      }

      if (remaining < 128) {
        final dst64 = _bufferDst64;
        final src64 = _bufferSrc64;
        final clr64 = _bufferClr64;
        for (var i = 0; i < 64; i++) {
          final start = i << 2;
          final end = start + 4;
          final f = flushIndex << 2;
          clr64[i] = bufferClr[flushIndex];
          dst64.setRange(start, end, bufferDst, f);
          src64.setRange(start, end, bufferSrc, f);
          flushIndex++;
        }
        canvas.drawRawAtlas(
          image,
          dst64,
          src64,
          clr64,
          blendMode,
          null,
          paint,
        );
        batches64Rendered++;
        continue;
      }

      throw Exception();
    }
    this.bufferIndex = 0;
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
    render(
        color: color,
        srcLeft: srcX,
        srcTop: srcY,
        srcRight: srcX + srcWidth,
        srcBottom: srcY + srcHeight,
        scale: scale,
        rotation: 0,
        dstX: dstX - (srcWidth * anchorX * scale),
        dstY: dstY - (srcHeight * anchorY * scale),
    );
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
    render(
        color: color,
        srcLeft: srcX,
        srcTop: srcY,
        srcRight: srcX + srcWidth,
        srcBottom: srcY + srcHeight,
        scale: cos(rotation) * scale,
        rotation: sin(rotation) * scale,
        dstX: tx + adjX2 + adjX,
        dstY: ty - adjY2 + adjY,
    );
  }

  void render({
    required int color,
    required double srcLeft,
    required double srcTop,
    required double srcRight,
    required double srcBottom,
    required double scale,
    required double rotation,
    required double dstX,
    required double dstY,
  }){
    final index = bufferIndex;
    final i = index << 2;
    final src = this.bufferSrc;
    final dst = this.bufferDst;
    bufferClr[index] = color;
    src[i] = srcLeft;
    src[i + 1] = srcTop;
    src[i + 2] = srcRight;
    src[i + 3] = srcBottom;
    dst[i] = scale;
    dst[i + 1] = rotation;
    dst[i + 2] = dstX;
    dst[i + 3] = dstY;

    bufferIndex++;
    if (bufferIndex == 128) {
      flushAll();
    }
  }

  void renderCircle(double x, double y, double radius, Color color) {
    renderCircleOffset(Offset(x, y), radius, color);
  }

  void renderCircleOffset(Offset offset, double radius, Color color) {
    setPaintColor(color);
    canvas.drawCircle(offset, radius, paint);
  }

  void renderCircleFilled({
    required double radius,
    required double x,
    required double y,
  }){
    final angle = (2 * 3.14159) / _renderCircleSegments;
    var j = 0;
    for (int i = 0; i < _renderCircleSegments; i++) {
      _renderCirclePositions[j++] = x;
      _renderCirclePositions[j++] = y;
      _renderCirclePositions[j++] = x + adj(angle * i, radius);
      _renderCirclePositions[j++] = y + opp(angle * i, radius);
      _renderCirclePositions[j++] = x + adj(angle * (i + 1), radius);
      _renderCirclePositions[j++] = y + opp(angle * (i + 1), radius);
    }

    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _renderCirclePositions,
      textureCoordinates: null,
      colors: null,
      indices: null,
    );

    canvas.drawVertices(vertices, ui.BlendMode.srcOver, paint);
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

  Widget _internalBuildApp() => WatchBuilder(themeData, (ThemeData? themeData) =>
      CustomTicker(
        onTrick: _onTickElapsed,
        onDispose: _internalDispose,
        child: Builder(
          builder: (context) {
            print('MaterialApp()');
            return MaterialApp(
              title: title,
              theme: themeData,
              home: Scaffold(
                body: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    _internalSetScreenSize(constraints.maxWidth, constraints.maxHeight);
                    buildContext = context;
                    return Stack(
                      children: [
                        _internalBuildCanvas(context),
                        WatchBuilder(watchBuildUI, (WidgetBuilder? buildUI)
                        => buildUI != null ? buildUI(context) : const SizedBox()
                        ),
                      ],
                    );
                  },
                ),
              ),
              debugShowCheckedModeBanner: false,
            );
          }
        ),
      ));

  void _onTickElapsed(Duration duration) => redrawCanvas();

  void _internalDispose(){
    print("engine.dispose()");
    // updateTimer?.cancel();
    dispose?.call();
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
          child: WatchBuilder(watchBackgroundColor, (Color backgroundColor) =>
            MouseRegion(
              hitTestBehavior: HitTestBehavior.deferToChild,
              onEnter: (_) {
                mouseOverCanvas = true;
                onMouseEnterCanvas?.call();
              },
              onExit: (_) {
                mouseOverCanvas = false;
                onMouseExitCanvas?.call();
              },
              child: Container(
                  color: backgroundColor,
                  width: screen.width,
                  height: screen.height,
                  child: CustomPaint(
                    isComplex: true,
                    willChange: true,
                    painter: _EnginePainter(
                        repaint: notifierPaintFrame,
                        engine: this,
                    ),
                    foregroundPainter: _EngineForegroundPainter(
                        repaint: notifierPaintForeground,
                        engine: this,
                    ),
                  )
              ),
            ))),
    );

    return WatchBuilder(this.cursorType, (CursorType cursorType) =>
        MouseRegion(
          cursor: _internalMapCursorTypeToSystemMouseCursor(cursorType),
          child: child,
        )
    );
  }

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

  bool get fullScreenActive => html.document.fullscreenElement != null;

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
    var canvas = html.document.getElementById('canvas');
    if (canvas != null) {
      canvas.requestPointerLock();
    }
  }

   void setDocumentTitle(String value){
     html.document.title = value;
  }

  void setFavicon(String filename){
    final link = html.document.querySelector("link[rel*='icon']");
    if (link == null) return;
    print("setFavicon($filename)");
    link.setAttribute("type", 'image/x-icon');
    link.setAttribute("rel", 'shortcut icon');
    link.setAttribute("href", filename);
    html.document.getElementsByTagName('head')[0].append(link);
  }

  void setCursorWait(){
    setCursorByName('wait');
  }

  void setCursorPointer(){
    setCursorByName('pointer');
  }

  void setCursorDefault(){
    setCursorByName('default');
  }

  void setCursorCrosshair(){
    setCursorByName('crosshair');
  }

  void setCursorByName(String name){
    final body = html.document.body;
    if (body == null) return;
    body.style.cursor = name;
    print("body.style.cursor: ${body.style.cursor}");
  }

  void flushAll(){
    batchesRendered++;
    canvas.drawRawAtlas(
      _bufferImage,
      bufferDst,
      bufferSrc,
      bufferClr,
      _bufferBlendMode,
      null,
      paint,
    );
    bufferIndex = 0;
    batches128Rendered++;
  }

  bool isOnscreen(double x, double y, {required double padding}) {

    if (x < Screen_Left - padding || x > Screen_Right + padding)
      return false;

    return y > Screen_Top - padding && y < Screen_Bottom + padding;
  }

  Future<ui.Image> _generateEmptyImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, 1, 1), Paint());
    final picture = recorder.endRecording();
    return await picture.toImage(1, 1);
  }

  Widget buildAtlasImage({
    required ui.Image image,
    required double srcX,
    required double srcY,
    required double srcWidth,
    required double srcHeight,
    double scale = 1.0,
    int? color,
  }) =>
      Container(
        alignment: Alignment.center,
        width: srcWidth * scale,
        height: srcHeight * scale,
        child: buildCanvas(
            paint: (Canvas canvas, Size size) =>
                renderCanvas(
                  canvas: canvas,
                  image: image,
                  srcX: srcX,
                  srcY: srcY,
                  srcWidth: srcWidth,
                  srcHeight: srcHeight,
                  dstX: 0,
                  dstY: 0,
                  scale: scale,
                  color: color ?? 1,
                  blendMode: color != null ? BlendMode.modulate : BlendMode.dstATop,
                )
        ),
      );

  Widget buildCanvas({
    required PaintCanvas paint,
    ValueNotifier<int>? frame,
  })=> CustomPaint(
      painter: CustomPainterPainter(
          paint,
          frame
      ),
    );


  late final Watch<Widget> app;
  late WatchBuilder<Widget> appBuilder;
  var appInitialized = false;

  late Widget internalBuild;
  var internalBuildCreated = false;
  var buildingInternal = false;

  @override
  Widget build(BuildContext context) {
    print("engine.build()");


    if (!appInitialized){
      print('engine.initializing()');
      appInitialized = true;

      app = Watch<Widget>(MaterialApp(
        title: title,
        theme: themeData.value,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: loadingScreenBuilder(context),
        ),
      ));

      appBuilder = WatchBuilder(app, (t) => t);

      _internalInit().catchError((error){
        app.value = MaterialApp(
          title: title,
          theme: themeData.value,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: Text(error.toString(), style: TextStyle(color: Colors.white))),
          ),
        );
      });
    } else {
      print('engine.build() already initialized');
      if (!internalBuildCreated) {
        internalBuild = _internalBuildApp();
        internalBuildCreated = true;
      }
      app.value = internalBuild;
    }
    return appBuilder;
  }

  void onChangedDurationPerUpdate(Duration duration){
    print('engine.onChangedDurationPerUpdate(milliseconds: ${duration.inMilliseconds})');
    updateTimer?.cancel();
    updateTimer = Timer.periodic(
      duration,
      _internalOnUpdate,
    );
    onUpdateDurationChanged?.call();
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

class Screen {
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

class CustomPainterPainter extends CustomPainter {

  final PaintCanvas paintCanvas;

  CustomPainterPainter(this.paintCanvas, ValueNotifier<int>? frame) : super(repaint: frame);

  @override
  void paint(Canvas canvas, Size size) => paintCanvas(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

}


