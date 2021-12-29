import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_engine/state/cursor.dart';
import 'package:lemon_engine/state/initialized.dart';
import 'package:lemon_watch/watch.dart';
import 'package:lemon_watch/watch_builder.dart';
import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart';

import 'classes/vector2.dart';
import 'functions/disable_right_click_context_menu.dart';
import 'functions/screen_to_world.dart';
import 'properties/mouse_world.dart';
import 'state/build_context.dart';
import 'state/camera.dart';
import 'state/canvas.dart';
import 'state/mouseDragging.dart';
import 'state/onMouseScroll.dart';
import 'state/paint.dart';
import 'state/screen.dart';
import 'state/zoom.dart';
import 'typedefs/DrawCanvas.dart';

// private global variables
Offset _mousePosition = Offset(0, 0);
Offset _previousMousePosition = Offset(0, 0);
Offset _mouseDelta = Offset(0, 0);
bool _clickProcessed = true;
late StateSetter uiSetState;
// bool canvasActive =

// global properties
Offset get mousePosition => _mousePosition;

Offset get previousMousePosition => _previousMousePosition;

Offset get mouseVelocity => _mouseDelta;

double get mouseX => _mousePosition.dx;

double get mouseY => _mousePosition.dy;

Offset get mouse => Offset(mouseX, mouseY);

Offset get mouseWorld => Offset(mouseWorldX, mouseWorldY);

Vector2 get mouseWorldV2 => Vector2(mouseWorldX, mouseWorldY);

double get screenCenterX => screen.width * 0.5;
double get screenCenterY => screen.height * 0.5;

double get screenCenterWorldX => screenToWorldX(screenCenterX);

double get screenCenterWorldY => screenToWorldY(screenCenterY);

Offset get screenCenterWorld => Offset(screenCenterWorldX, screenCenterWorldY);

bool get mouseAvailable => true;

bool get mouseClicked => !_clickProcessed;

int _millisecondsSinceLastFrame = 50;
DateTime _previousUpdateTime = DateTime.now();

int get millisecondsSinceLastFrame => _millisecondsSinceLastFrame;

StreamController<bool> onRightClickChanged = StreamController.broadcast();

final _KeyboardEvents keyboardEvents = _KeyboardEvents();

class _KeyboardEvents {
  ValueChanged<RawKeyEvent>? _listener;

  void listen(ValueChanged<RawKeyEvent>? value){
    if (_listener == value) return;
    if (_listener != null){
      RawKeyboard.instance.removeListener(_listener!);
    }
    if (value != null){
      RawKeyboard.instance.addListener(value);
    }
    _listener = value;
  }
}

final _MouseEvents mouseEvents = _MouseEvents();

class _MouseEvents {
  Watch<Function?> onLeftClicked = Watch(null);
  Watch<Function?> onLongLeftClicked = Watch(null);
  Watch<Function?> onPanStarted = Watch(null);
}

final _UI ui = _UI();

class _UI {
  final Watch<int> fps = Watch(0);
  final Watch<Color> backgroundColor = Watch(Colors.white);
  bool drawCanvasAfterUpdate = true;
}

void _defaultDrawCanvasForeground(Canvas canvas, Size size) {
  // do nothing
}

class Game extends StatefulWidget {
  final String title;
  final Function init;
  final Function update;
  final WidgetBuilder? buildLoadingScreen;
  final WidgetBuilder buildUI;
  final DrawCanvas drawCanvas;
  final DrawCanvas drawCanvasForeground;
  final int framesPerSecond;
  final ThemeData? themeData;

  Game({
      required this.title,
      required this.init,
      required this.update,
      required this.buildUI,
      required this.drawCanvas,
      this.buildLoadingScreen,
      this.drawCanvasForeground = _defaultDrawCanvasForeground,
      Color backgroundColor = Colors.black,
      bool drawCanvasAfterUpdate = true,
      this.framesPerSecond = 60,
      this.themeData
  }){
    ui.backgroundColor.value = backgroundColor;
    ui.drawCanvasAfterUpdate = drawCanvasAfterUpdate;
  }

  void _internalUpdate() {
    DateTime now = DateTime.now();
    _millisecondsSinceLastFrame = now.difference(_previousUpdateTime).inMilliseconds;
    if (_millisecondsSinceLastFrame > 0){
      ui.fps.value = 1000 ~/ _millisecondsSinceLastFrame;
    }
    _previousUpdateTime = now;
    screen.left = camera.x;
    screen.right = camera.x + (screen.width / zoom);
    screen.top = camera.y;
    screen.bottom = camera.y + (screen.height / zoom);
    update();
    _clickProcessed = true;

    if (ui.drawCanvasAfterUpdate) {
      redrawCanvas();
    }
  }

  @override
  _GameState createState() => _GameState();
}

void redrawCanvas() {
  _frame.value++;
}

final _frame = ValueNotifier<int>(0);
final _foregroundFrame = ValueNotifier<int>(0);
const int millisecondsPerSecond = 1000;
bool _rightClickDown = false;
bool get rightClickDown => _rightClickDown;

final Watch<WidgetBuilder?> overrideBuilder = Watch(null);


class _GameState extends State<Game> {
  late Timer _updateTimer;

  void _update(Timer timer) {
    widget._internalUpdate();
  }

  @override
  void initState() {
    super.initState();
    print("lemon_engine.init()");
    _internalInit();
  }

  Future _internalInit() async {
    disableRightClickContextMenu();
    paint.isAntiAlias = false;
    await widget.init();
    initialized(true);
    int millisecondsPerFrame = millisecondsPerSecond ~/ widget.framesPerSecond;
    Duration updateDuration = Duration(milliseconds: millisecondsPerFrame);
    _updateTimer = Timer.periodic(updateDuration, _update);
    print("Lemon Engine - Update Job Started");
  }

  @override
  Widget build(BuildContext context) {
    return NullableWatchBuilder<WidgetBuilder?>(overrideBuilder, (WidgetBuilder? builder){
      if (builder != null){
        return builder(context);
      }

      return MaterialApp(
        title: widget.title,
        home: Scaffold(
          body: WatchBuilder(initialized, (bool? value) {
            if (value != true) {
              WidgetBuilder? buildLoadingScreen = widget.buildLoadingScreen;
              if (buildLoadingScreen != null){
                return buildLoadingScreen(context);
              }
              return Text("Loading");
            }
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                globalContext = context;
                screen.width = constraints.maxWidth;
                screen.height = constraints.maxHeight;

                return Stack(
                  children: [
                    _buildBody(context),
                    _buildUI(),
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

  Widget _buildBody(BuildContext context) {

    Widget child = PositionedTapDetector2(
      onLongPress: (TapPosition position) {
        _previousMousePosition = _mousePosition;
        _mousePosition = position.relative ?? Offset(0, 0);
        mouseEvents.onLongLeftClicked.value?.call();

      },
      onTap: (position) {
        _clickProcessed = false;
        mouseEvents.onLeftClicked.value?.call();
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
              mouseEvents.onPanStarted.value?.call();
            },
            onPanEnd: (value) {
              mouseDragging = false;
            },
            onPanUpdate: (DragUpdateDetails value) {
              _previousMousePosition = _mousePosition;
              _mousePosition = value.globalPosition;
            },
            child: WatchBuilder(ui.backgroundColor, (Color backgroundColor){
              return Container(
                  color: backgroundColor,
                  width: screen.width,
                  height: screen.height,
                  child: CustomPaint(
                      painter: _GamePainter(
                          drawCanvas: widget.drawCanvas, repaint: _frame),
                      foregroundPainter: _GamePainter(
                          drawCanvas: widget.drawCanvasForeground,
                          repaint: _foregroundFrame)));
            })),
      ),
    );

    return WatchBuilder(cursorType, (CursorType cursorType){
      return MouseRegion(
        cursor: mapCursorTypeToSystemMouseCursor(cursorType),
        onHover: (PointerHoverEvent pointerHoverEvent) {
          _previousMousePosition = _mousePosition;
          _mousePosition = pointerHoverEvent.position;
          _mouseDelta = pointerHoverEvent.delta;
        },
        child: child,
      );
    });
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
    _canvas.scale(zoom, zoom);
    _canvas.translate(-camera.x, -camera.y);
    drawCanvas(_canvas, _size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

