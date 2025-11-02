import 'dart:async';
import 'dart:math';
import 'dart:ui' as DartUI;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_engine/src.dart';

abstract class LemonEngine extends StatelessWidget {

  Widget buildUI(BuildContext context);

  Future onInit();

  void onUpdate();

  void onDispose();
  /// override safe
  void onTapDown(TapDownDetails details) { }
  /// override safe
  void onTap() {}
  /// override safe
  void onLongPress() {}
  /// override safe
  void onLongPressDown(LongPressDownDetails details) {}
  /// override safe
  void onSecondaryTapDown(TapDownDetails details) {}
  /// override safe
  void onScreenSizeChanged(
      double previousWidth,
      double previousHeight,
      double newWidth,
      double newHeight,
  ){}
  /// override safe
  void onDrawCanvas(Canvas canvas, Size size);
  /// override safe
  void onDrawForeground(Canvas canvas, Size size) {}
  /// override safe
  void onLeftClicked() {

  }

  /// override safe
  void onMouseMoved(double x, double y) {}
  /// override safe
  Function(PointerScrollEvent value)? onPointerScrolled;
  /// override safe
  Function(PointerSignalEvent value)? onPointerSignalEvent;
  /// override safe
  void onRightClicked(){}
  /// override safe
  void onRightClickReleased(){}
  /// override safe
  void onMouseEnterCanvas(){}
  /// override safe
  void onMouseExitCanvas(){}
  /// override safe
  /// triggered the first moment the key is pressed down
  void onKeyPressed(PhysicalKeyboardKey keyCode){}
  /// override safe
  void onKeyUp(PhysicalKeyboardKey keyCode) {}
  /// override safe
  void onKeyDown(PhysicalKeyboardKey keyCode) {}
  /// override safe
  void onScaleStart(ScaleStartDetails details){ }
  /// override safe
  void onScaleUpdate(ScaleUpdateDetails details){ }
  /// override safe
  void onScaleEnd(ScaleEndDetails details){ }

  /// override safe
  Widget buildLoadingPage(BuildContext context) => Text("LOADING");

  Timer? updateTimer;
  ThemeData? themeData;

  var _mouseRightDown = false;
  var _mouseLeftDown = false;
  var _durationPerUpdate = _convertFramesPerSecondToDuration(60);
  var _initCallAmount = 0;
  var _keyboardEventHandlerRegistered = false;
  var _bufferBlendMode = BlendMode.dstATop;
  var _initFinished = false;
  var _initStarted = false;

  var debugShowRenderFrame = false;
  // var internalBuildCreated = false;
  var buildingInternal = false;
  var appInitialized = false;
  var mouseOverCanvas = false;
  var touchDownId = 0;
  var touchHeldId = 0;
  var scrollSensitivity = 0.0005;
  var zoomSensitivity = 0.05;
  var targetZoom = 1.0;
  var zoomOnScroll = true;
  var mousePositionX = 0.0;
  var mousePositionY = 0.0;
  var previousMousePositionX = 0.0;
  var previousMousePositionY = 0.0;
  var zoom = 1.0;
  var zoomMin = 0.1;
  var zoomMax = 6.0;
  var cameraX = 0.0;
  var cameraY = 0.0;
  var updateFrame = 0;
  var screenTop = 0.0;
  var screenRight = 0.0;
  var screenBottom = 0.0;
  var screenLeft = 0.0;
  var screenWidth = 0.0;
  var screenHeight = 0.0;
  var screenInitialized = false;
  var renders = 0;
  var bufferIndex = 0;
  var notifierTotalRenders = ValueNotifier(0);

  final _notifierPaintFrame = ValueNotifier<int>(0);
  final _notifierCursorType = ValueNotifier(SystemMouseCursors.basic);
  final _notifierPaintForeground = ValueNotifier<int>(0);

  final String? title;
  final Color backgroundColor;
  final keyState = <PhysicalKeyboardKey, bool>{ };
  final onTickTracker = FpsTracker();
  final bufferSrc = Float32List(BufferLength * 4);
  final bufferDst = Float32List(BufferLength * 4);
  final bufferClr = Int32List(BufferLength);
  final paint = Paint()
    ..color = Colors.white
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill
    ..isAntiAlias = false
    ..strokeWidth = 1;

  late Canvas canvas;
  late DartUI.Image _bufferImage;
  late DartUI.Image atlas;



  static const BufferLength = 131072 ~/ 2;

  LemonEngine({
    this.title,
    this.themeData,
    this.backgroundColor = Colors.black,
    int? updateFps,
  }){
    // this.watchMouseLeftDown.onChanged(_internalOnChangedMouseLeftDown);
    if (updateFps != null){
      setUpdateFPS(updateFps);
    } else {
      restartUpdateTimer();
    }
  }

  Duration get durationPerUpdate => _durationPerUpdate;

  set durationPerUpdate(Duration value){
    if (_durationPerUpdate.inMilliseconds == value.inMilliseconds) return;
    print('engine.durationPerUpdate($value)');
    _durationPerUpdate = value;
    restartUpdateTimer();
  }

  SystemMouseCursor get cursorType => _notifierCursorType.value;

  set cursorType(SystemMouseCursor value) => _notifierCursorType.value = value;

  set bufferImage(DartUI.Image image){
    if (_bufferImage == image) return;
    flushBuffer();
    _bufferImage = image;
  }

  bool get mouseLeftDown => _mouseLeftDown;

  bool get mouseRightDown => _mouseRightDown;

  set bufferBlendMode(BlendMode value){
    if (_bufferBlendMode == value) return;
    flushBuffer();
    _bufferBlendMode = value;
  }

  void setUpdateFPS(int fps) =>
      durationPerUpdate = _convertFramesPerSecondToDuration(fps);

  set color(Color value){
    final paint = this.paint;
    if (paint.color == value) return;
    flushBuffer();
    paint.color = value;
  }

  Color get color => paint.color;

  BlendMode get bufferBlendMode => _bufferBlendMode;

  double get screenCenterRenderX => (screenLeft + screenRight) * 0.5;

  double get screenCenterRenderY => (screenTop + screenBottom) * 0.5;

  bool get isLocalHost => Uri.base.host == 'localhost';

  bool get keyPressedShiftLeft =>
      keyPressed(PhysicalKeyboardKey.shiftLeft);

  bool get keyPressedSpace =>
      keyPressed(PhysicalKeyboardKey.space);

  bool keyPressed(PhysicalKeyboardKey key) =>
      keyState[key] ?? false;

  void _internalSetScreenSize(double width, double height){
    if (screenWidth == width && screenHeight == height) return;
    if (!screenInitialized) {
      screenInitialized = true;
      screenWidth = width;
      screenHeight = height;
      return;
    }
    final previousScreenWidth = screenWidth;
    final previousScreenHeight = screenHeight;
    screenWidth = width;
    screenHeight = height;
    onScreenSizeChanged(
      previousScreenWidth,
      previousScreenHeight,
      screenWidth,
      screenHeight,
    );
  }

  void _internalOnPointerScrollEvent(PointerScrollEvent event) {
    if (zoomOnScroll) {
      targetZoom -=  event.scrollDelta.dy * scrollSensitivity;
      targetZoom = targetZoom.clamp(zoomMin, zoomMax);
    }
    onPointerScrolled?.call(event);
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

  void _internalOnPointerMove(PointerMoveEvent event) {
    previousMousePositionX = mousePositionX;
    previousMousePositionY = mousePositionY;
    mousePositionX = event.position.dx;
    mousePositionY = event.position.dy;
    onMouseMoved(mousePositionX, mousePositionY);
  }

  void _internalOnPointerHover(PointerHoverEvent event) {
    previousMousePositionX = mousePositionX;
    previousMousePositionY = mousePositionY;
    mousePositionX = event.position.dx;
    mousePositionY = event.position.dy;
    touchHeldId = event.pointer;
    onMouseMoved(mousePositionX, mousePositionY);
  }

  /// event.buttons is always 0 and does not seem to correspond to the left or right mouse
  /// click like in internalOnPointerDown
  void _internalOnPointerUp(PointerUpEvent event) {
    if (_mouseLeftDown){
      _mouseLeftDown = false;
    }
    if (_mouseRightDown){
      _mouseRightDown = false;
    }
    // _mouseLeftDownFrames = 0;
  }

  void _internalOnPointerDown(PointerDownEvent event) {
    previousMousePositionX = mousePositionX;
    previousMousePositionY = mousePositionY;
    mousePositionX = event.position.dx;
    mousePositionY = event.position.dy;
    touchDownId = event.pointer;

    if (event.buttons == 1) {
      if (!_mouseLeftDown){
        _mouseLeftDown = true;
        onLeftClicked();
      }
    }
    if (event.buttons == 2) {
      if (!_mouseRightDown){
        _mouseRightDown = true;
        onRightClicked();
      }
    }
  }

  void _internalOnPointerSignal(PointerSignalEvent pointerSignalEvent) {
    if (pointerSignalEvent is PointerScrollEvent) {
      _internalOnPointerScrollEvent(pointerSignalEvent);
    } else {
      onPointerSignalEvent?.call(pointerSignalEvent);
    }
  }

  void _internalPaint(Canvas canvas, Size size) {
    this.canvas = canvas;
    canvas.scale(zoom, zoom);
    canvas.translate(-cameraX, -cameraY);
    renders = 0;

    final sX = screenCenterWorldX;
    final sY = screenCenterWorldY;
    final zoomDiff = targetZoom - zoom;
    zoom += zoomDiff * zoomSensitivity;
    cameraCenter(sX, sY);
    onDrawCanvas(canvas, size);
    flushBuffer();
    notifierTotalRenders.value = renders;
    assert (bufferIndex == 0);
  }

  Future _internalInit() async {
    if (_initStarted) return;
    _initStarted = true;
    _initCallAmount++;
    print("engine.internalInit()");
    if (_initCallAmount > 1) {
      print('engine - warning init called ${_initCallAmount}');
      return;
    }
    _bufferImage = await _generateEmptyImage();
    atlas = await _generateEmptyImage();
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
    await onInit();
    _initFinished = true;
    registerKeyEventHandler();
    restartUpdateTimer();
    onReady();
  }
  
  void onReady(){}

  void registerKeyEventHandler() {
    if (_keyboardEventHandlerRegistered) return;
    print('engine.registerKeyEventHandler()');
    _keyboardEventHandlerRegistered = true;
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  void deregisterKeyEventHandler() {
    if (!_keyboardEventHandlerRegistered) return;
    print('engine.deregisterKeyEventHandler()');
    _keyboardEventHandlerRegistered = false;
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!_keyboardEventHandlerRegistered) {
      return false;
    }

    final key = event.physicalKey;
    if (event is KeyDownEvent) {
      if (keyState[key] != true){
        keyState[key] = true;
        onKeyPressed(key);
      }
      onKeyDown(key);
    }
    if (event is KeyUpEvent) {
      keyState[key] = false;
      onKeyUp(key);
    }
    onKeyEvent(event);
    return true;
  }

  void onKeyEvent(KeyEvent event){

  }

  void _internalOnUpdate(Timer timer){
    if (!_initFinished){
      return;
    }

    updateFrame++;
    screenLeft = cameraX;
    screenRight = cameraX + (screenWidth / zoom);
    screenTop = cameraY;
    screenBottom = cameraY + (screenHeight / zoom);
    onUpdate();
  }

  void renderGame() => _notifierPaintFrame.value++;

  DartUI.Image get bufferImage => _bufferImage;

  void flushBuffer() {

    if (bufferIndex == 0) {
      return;
    }

    final bufferViewLength = bufferIndex * 4;
    final viewDst = Float32List.sublistView(bufferDst, 0, bufferViewLength);
    final viewSrc = Float32List.sublistView(bufferSrc, 0, bufferViewLength);
    final viewClr = Int32List.sublistView(bufferClr, 0, bufferIndex);

    canvas.drawRawAtlas(
      bufferImage,
      viewDst,
      viewSrc,
      viewClr,
      bufferBlendMode,
      null,
      paint,
    );

    bufferIndex = 0;
  }

  void renderImage({
    required DartUI.Image image,
    required double dstX,
    required double dstY,
    double anchorX = 0.5,
    double anchorY = 0.5,
    double scale = 1.0,
    int color = 1,
  }) => render(
        color: color,
        srcX: 0,
        srcY: 0,
        srcWidth: image.width.toDouble(),
        srcHeight: image.height.toDouble(),
        scale: scale,
        rotation: 0,
        dstX: dstX - (image.width * anchorX * scale),
        dstY: dstY - (image.height * anchorY * scale),
    );

  void renderSprite({
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
  }) =>
      render(
        color: color,
        srcX: srcX,
        srcY: srcY,
        srcWidth: srcWidth,
        srcHeight: srcHeight,
        scale: scale,
        rotation: 0,
        dstX: dstX - (srcWidth * anchorX * scale),
        dstY: dstY - (srcHeight * anchorY * scale),
     );

  void renderRotated({
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

    final adjX = _adj(rotation - piHalf, scaledHeight);
    final adjY = _opp(rotation - piHalf, scaledHeight);

    final adjY2 = _adj(rotation - piHalf, scaledWidth);
    final adjX2 = _opp(rotation - piHalf, scaledWidth);

    render(
        color: color,
        srcX: srcX,
        srcY: srcY,
        srcWidth: srcWidth,
        srcHeight: srcHeight,
        scale: cos(rotation) * scale,
        rotation: sin(rotation) * scale,
        dstX: tx + adjX2 + adjX,
        dstY: ty - adjY2 + adjY,
    );
  }

  void renderFastRotated({
    required double srcX,
    required double srcY,
    required double srcWidth,
    required double srcHeight,
    required double dstX,
    required double dstY,
    required double rotation,
    required Int32List clr,
    required Float32List src,
    required Float32List dst,
    double anchorX = 0.5,
    double anchorY = 0.5,
    double scale = 1.0,
    int color = 1,
  }){
    renders++;
    const PI_HALF = pi * 0.5;

    final scos = cos(rotation) * scale;
    final ssin = sin(rotation) * scale;
    final width = -scos * anchorX + ssin * anchorY;
    final height = -ssin * anchorX - scos * anchorY;
    final tx = dstX + width;
    final ty = dstY + height;
    final scaledHeight = srcHeight * scale * anchorY;
    final scaledWidth = srcWidth * scale * anchorX;
    final adjX = _adj(rotation - PI_HALF, scaledHeight);
    final adjY = _opp(rotation - PI_HALF, scaledHeight);
    final adjY2 = _adj(rotation - PI_HALF, scaledWidth);
    final adjX2 = _opp(rotation - PI_HALF, scaledWidth);
    final index = bufferIndex++;
    final i = index << 2;

    clr[index] = color;
    src[i] = srcX;
    src[i + 1] = srcY;
    src[i + 2] = srcX + srcWidth;
    src[i + 3] = srcY + srcHeight;
    dst[i] = cos(rotation) * scale;
    dst[i + 1] = sin(rotation) * scale;
    dst[i + 2] = tx + adjX2 + adjX;
    dst[i + 3] = ty - adjY2 + adjY;
}

  void render({
    required int color,
    required double srcX,
    required double srcY,
    required double srcWidth,
    required double srcHeight,
    required double scale,
    required double rotation,
    required double dstX,
    required double dstY,
  }) =>
      renderFast(
        color: color,
        srcX: srcX,
        srcY: srcY,
        srcWidth: srcWidth,
        srcHeight: srcHeight,
        scale: scale,
        rotation: rotation,
        dstX: dstX,
        dstY: dstY,
        clr: bufferClr,
        src: bufferSrc,
        dst: bufferDst,
      );

  @pragma('vm:prefer-inline')
  void renderFast({
    required int color,
    required double srcY,
    required double srcX,
    required double srcWidth,
    required double srcHeight,
    required double scale,
    required double rotation,
    required double dstX,
    required double dstY,
    required Int32List clr,
    required Float32List src,
    required Float32List dst,
  }){
    renders++;
    final index = bufferIndex++;
    final i = index << 2;
    clr[index] = color;
    src[i + 0] = srcX;
    src[i + 1] = srcY;
    src[i + 2] = srcX + srcWidth;
    src[i + 3] = srcY + srcHeight;
    dst[i + 0] = scale;
    dst[i + 1] = rotation;
    dst[i + 2] = dstX;
    dst[i + 3] = dstY;
  }

  Widget _internalBuildApp() => MaterialApp(
    title: title,
    theme: themeData,
    home: Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext layoutBuilderContext, BoxConstraints constraints) {
          _internalSetScreenSize(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            children: [
              _internalBuildCanvas(layoutBuilderContext),
              buildUI(layoutBuilderContext),
            ],
          );
        },
      ),
    ),
    debugShowCheckedModeBanner: false,
  );


  Widget _internalBuildCanvas(BuildContext context) {
    print('lemonEngine._internalBuildCanvas()');
    final child = Listener(
      onPointerDown: _internalOnPointerDown,
      onPointerMove: _internalOnPointerMove,
      onPointerUp: _internalOnPointerUp,
      onPointerHover: _internalOnPointerHover,
      onPointerSignal: _internalOnPointerSignal,
      child: GestureDetector(
          onScaleStart: onScaleStart,
          onScaleUpdate: onScaleUpdate,
          onScaleEnd: onScaleEnd,
          onTapDown: onTapDown,
          onTap: onTap,
          onLongPress: onLongPress,
          onLongPressDown: onLongPressDown,
          onSecondaryTapDown: onSecondaryTapDown,
          child: MouseRegion(
            hitTestBehavior: HitTestBehavior.deferToChild,
            onEnter: (_) {
              mouseOverCanvas = true;
              onMouseEnterCanvas();
            },
            onExit: (_) {
              mouseOverCanvas = false;
              onMouseExitCanvas();
            },
            child: Container(
                color: backgroundColor,
                width: screenWidth,
                height: screenHeight,
                child: CustomPaint(
                  isComplex: false,
                  willChange: true,
                  painter: CanvasPainter(
                    repaint: _notifierPaintFrame,
                    drawCanvas: _internalPaint,
                  ),
                  foregroundPainter: CanvasPainter(
                    repaint: _notifierPaintForeground,
                    drawCanvas: onDrawForeground,
                  ),
                )
            ),
          )
      )
    );

    return CustomTicker(
      onTick: onTick,
      onDispose: onDispose,
      child: ValueListenableBuilder(
          valueListenable: _notifierCursorType,
          builder: (context, cursorTypeValue, _) =>
              MouseRegion(
                cursor: cursorTypeValue,
                child: child,
              ),
      ),
    );

    // return child;
  }

  void onTick(Duration duration){
    onTickTracker.update();
  }

  void drawLine(double x1, double y1, double x2, double y2) =>
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);

  double screenToWorldX(double value)  =>
    cameraX + value / zoom;

  double screenToWorldY(double value) =>
    cameraY + value / zoom;

  double worldToScreenX(double x) =>
    zoom * (x - cameraX);

  double worldToScreenY(double y) =>
    zoom * (y - cameraY);

  double get screenCenterX => screenWidth * 0.5;

  double get screenCenterY => screenHeight * 0.5;

  double get screenCenterWorldX => screenToWorldX(screenCenterX);

  double get screenCenterWorldY => screenToWorldY(screenCenterY);

  double get mouseWorldX => screenToWorldX(mousePositionX);

  double get mouseWorldY => screenToWorldY(mousePositionY);

  bool isOnscreen(double x, double y, {required double padding}) =>
        x >= screenLeft - padding &&
        x <= screenRight + padding &&
        y >= screenTop - padding &&
        y <= screenBottom + padding ;

  Future<DartUI.Image> _generateEmptyImage() async {
    final recorder = DartUI.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, 1, 1), Paint());
    final picture = recorder.endRecording();
    return await picture.toImage(1, 1);
  }

  @override
  Widget build(BuildContext context) {
    print("engine.build()");

    return FutureBuilder(future: _internalInit(), builder: (context, snapshot) {

      if (snapshot.hasError) {
        final error = snapshot.error?.toString() ?? '';
        print('engine.error: $error');
        return MaterialApp(
          title: title,
          theme: themeData,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: Text(error, style: TextStyle(color: Colors.white))),
          ),
        );
      }

      if (snapshot.connectionState != ConnectionState.done) {
        MaterialApp(
          title: title,
          theme: themeData,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.black,
            body: buildLoadingPage(context),
          ),
        );
      }

      return _internalBuildApp();
    });
  }

  void restartUpdateTimer() {
    updateTimer?.cancel();
    updateTimer = Timer.periodic(
      _durationPerUpdate,
      _internalOnUpdate,
    );
  }
}

// UTILITY FUNCTIONS

Duration _convertFramesPerSecondToDuration(int framesPerSecond) =>
    Duration(milliseconds: (Duration.millisecondsPerSecond / framesPerSecond).round());

double _adj(double radians, double magnitude) =>
    cos(radians) * magnitude;

double _opp(double radians, double magnitude) =>
    sin(radians) * magnitude;

