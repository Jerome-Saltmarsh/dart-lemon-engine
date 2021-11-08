import 'dart:async';

import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart';
import 'classes/vector2.dart';
import 'functions/screen_to_world.dart';
import 'functions/disable_right_click_context_menu.dart';
import 'properties/mouse_world.dart';
import 'state/build_context.dart';
import 'state/camera.dart';
import 'state/canvas.dart';
import 'state/mouseDragging.dart';
import 'state/onMouseScroll.dart';
import 'state/screen.dart';
import 'state/size.dart';
import 'state/zoom.dart';
import 'typedefs/DrawCanvas.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'state/paint.dart';

// private global variables
Offset _mousePosition = Offset(0,0);
Offset _previousMousePosition = Offset(0,0);
Offset _mouseDelta = Offset(0,0);
bool _clickProcessed = true;
late StateSetter uiSetState;

// global properties
Offset get mousePosition => _mousePosition;

Offset get previousMousePosition => _previousMousePosition;

Offset get mouseVelocity => _mouseDelta;

double get mouseX => _mousePosition.dx;

double get mouseY => _mousePosition.dy;

Offset get mouse => Offset(mouseX, mouseY);

Offset get mouseWorld => Offset(mouseWorldX, mouseWorldY);

Vector2 get mouseWorldV2 => Vector2(mouseWorldX, mouseWorldY);

double get screenCenterX => screenWidth * 0.5;

double get screenCenterY => screenHeight * 0.5;

double get screenWidth => globalSize.width;

double get screenHeight => globalSize.height;

double get screenCenterWorldX => screenToWorldX(screenCenterX);

double get screenCenterWorldY => screenToWorldY(screenCenterY);

Offset get screenCenterWorld => Offset(screenCenterWorldX, screenCenterWorldY);

bool get mouseAvailable => mouseX != null;

bool get mouseClicked => !_clickProcessed;

int _millisecondsSinceLastFrame = 0;
DateTime _previousUpdateTime = DateTime.now();

int get millisecondsSinceLastFrame => _millisecondsSinceLastFrame;

StreamController<bool> onRightClickChanged = StreamController.broadcast();

void _defaultDrawCanvasForeground(Canvas canvas, Size size){
  // do nothing
}

class Game extends StatefulWidget {
  final String title;
  final Function init;
  final Function update;
  final WidgetBuilder buildUI;
  final DrawCanvas drawCanvas;
  final DrawCanvas drawCanvasForeground;
  final Color backgroundColor;
  final bool drawCanvasAfterUpdate;
  final int framesPerSecond;
  final ThemeData? themeData;

  Game({
      required this.title,
      required this.init,
      required this.update,
      required this.buildUI,
      required this.drawCanvas,
      this.drawCanvasForeground = _defaultDrawCanvasForeground,
      this.backgroundColor = Colors.black,
      this.drawCanvasAfterUpdate = true,
      this.framesPerSecond = 60,
      this.themeData
  });

  void _internalUpdate() {
    DateTime now = DateTime.now();
    _millisecondsSinceLastFrame =
        now.difference(_previousUpdateTime).inMilliseconds;
    _previousUpdateTime = now;

    screen.left = camera.x;
    screen.right = camera.x + (screenWidth / zoom);
    screen.top = camera.y;
    screen.bottom = camera.y + (screenHeight / zoom);
    update();
    _clickProcessed = true;

    if (drawCanvasAfterUpdate){
      redrawCanvas();
    }
  }

  @override
  _GameState createState() => _GameState();
}

void redrawCanvas() {
  _frame.value++;
}

void rebuildUI() {
  uiSetState(_doNothing);
}

void _doNothing() {}

final _frame = ValueNotifier<int>(0);
final _foregroundFrame = ValueNotifier<int>(0);
const int millisecondsPerSecond = 1000;


bool _rightClickDown = false;

bool get rightClickDown => _rightClickDown;

class _GameState extends State<Game> {
  late Timer _updateTimer;

  void _update(Timer timer) {
    widget._internalUpdate();
  }

  @override
  void initState() {
    super.initState();
    int millisecondsPerFrame = millisecondsPerSecond ~/ widget.framesPerSecond;
    Duration updateDuration = Duration(milliseconds: millisecondsPerFrame);
    _updateTimer = Timer.periodic(updateDuration, _update);
    disableRightClickContextMenu();
    paint.isAntiAlias = false;
    widget.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      theme: widget.themeData ?? ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            globalContext = context;
            globalSize = MediaQuery.of(context).size;
            return Stack(
              children: [
                _buildBody(context),
                _buildUI(),
              ],
            );
          },
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildBody(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      onHover: (PointerHoverEvent pointerHoverEvent) {
        _previousMousePosition = _mousePosition;
        _mousePosition = pointerHoverEvent.position;
        _mouseDelta = pointerHoverEvent.delta;
      },
      child: PositionedTapDetector2(
        onLongPress: (TapPosition position) {
          _previousMousePosition = _mousePosition;
          _mousePosition = position.relative ?? Offset(0, 0);
        },
        onTap: (position) {
          _clickProcessed = false;
        },
        child: Listener(
          onPointerSignal: (pointerSignalEvent) {
            if (pointerSignalEvent is PointerScrollEvent) {
              onMouseScroll(pointerSignalEvent.scrollDelta.dy);
            }
          },
          child: GestureDetector(
              onSecondaryTapDown: (_) {
                _rightClickDown = true;
                onRightClickChanged.add(true);
              },
              onSecondaryTapUp: (_) {
                onRightClickChanged.add(false);
                _rightClickDown = false;
              },
              onPanStart: (start) {
                mouseDragging = true;
                _previousMousePosition = _mousePosition;
                _mousePosition = start.globalPosition;
              },
              onPanEnd: (value) {
                mouseDragging = false;
              },
              onPanUpdate: (DragUpdateDetails value) {
                _previousMousePosition = _mousePosition;
                _mousePosition = value.globalPosition;
              },
              child: Container(
                  color: widget.backgroundColor,
                  width: globalSize.width,
                  height: globalSize.height,
                  child: CustomPaint(
                      painter: _GamePainter(
                          drawCanvas: widget.drawCanvas, repaint: _frame),
                      foregroundPainter: widget.drawCanvasForeground != null
                          ? _GamePainter(
                              drawCanvas: widget.drawCanvasForeground,
                              repaint: _foregroundFrame)
                          : null))),
        ),
      ),
    );
  }

  Widget _buildUI() {
    return StatefulBuilder(builder: (context, drawUI) {
      uiSetState = drawUI;
      globalContext = context;
      return widget.buildUI(context);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _updateTimer.cancel();
  }
}

class _GamePainter extends CustomPainter {
  final DrawCanvas drawCanvas;

  const _GamePainter({required this.drawCanvas, required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas _canvas, Size _size) {
    globalCanvas = _canvas;
    globalSize = _size;
    _canvas.scale(zoom, zoom);
    _canvas.translate(-camera.x, -camera.y);
    drawCanvas(_canvas, _size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
