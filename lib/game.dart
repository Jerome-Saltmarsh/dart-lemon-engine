import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_engine/engine.dart';
import 'package:lemon_watch/watch.dart';
import 'package:lemon_watch/watch_builder.dart';
import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart';
import 'package:universal_html/html.dart';

import 'enums.dart';
import 'functions/disable_right_click_context_menu.dart';
import 'functions/screen_to_world.dart';
import 'properties/mouse_world.dart';
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

double get screenCenterX => engine.state.screen.width * 0.5;
double get screenCenterY => engine.state.screen.height * 0.5;

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

final _UI ui = _UI();

class _UI {
  final Watch<int> fps = Watch(0);
  final Watch<Color> backgroundColor = Watch(Colors.white);
  bool drawCanvasAfterUpdate = true;
  final Watch<ThemeData?> themeData = Watch(null);
}

void _defaultDrawCanvasForeground(Canvas canvas, Size size) {
  // do nothing
}

class Game extends StatefulWidget {
  final String title;
  final Map<String, WidgetBuilder>? routes;
  final Function init;
  final Function update;
  final WidgetBuilder? buildLoadingScreen;
  final WidgetBuilder buildUI;
  final DrawCanvas drawCanvasForeground;
  final int framesPerSecond;

  Game({
      required this.title,
      required this.init,
      required this.update,
      required this.buildUI,
      this.buildLoadingScreen,
      this.routes,
      this.drawCanvasForeground = _defaultDrawCanvasForeground,
      DrawCanvas? drawCanvas,
      Color backgroundColor = Colors.black,
      bool drawCanvasAfterUpdate = true,
      this.framesPerSecond = 60,
      ThemeData? themeData,

  }){
    ui.backgroundColor.value = backgroundColor;
    ui.drawCanvasAfterUpdate = drawCanvasAfterUpdate;
    ui.themeData.value = themeData;
    engine.state.drawCanvas = drawCanvas;
  }

  void _internalUpdate() {
    DateTime now = DateTime.now();
    _millisecondsSinceLastFrame = now.difference(_previousUpdateTime).inMilliseconds;
    if (_millisecondsSinceLastFrame > 0){
      ui.fps.value = 1000 ~/ _millisecondsSinceLastFrame;
    }
    _previousUpdateTime = now;
    engine.state.screen.left = engine.state.camera.x;
    engine.state.screen.right = engine.state.camera.x + (engine.state.screen.width / engine.state.zoom);
    engine.state.screen.top = engine.state.camera.y;
    engine.state.screen.bottom = engine.state.camera.y + (engine.state.screen.height / engine.state.zoom);
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

    document.addEventListener("mousemove", (value){
      if (value is MouseEvent){
        _previousMousePosition = _mousePosition;
        // value.page
        // _mousePosition = Offset(value.screen.x.toDouble(), value.screen.y.toDouble());
        _mousePosition = Offset(value.page.x.toDouble(), value.page.y.toDouble());

        engine.callbacks.onMouseMoved?.call(
          _mousePosition, _previousMousePosition
        );
      }
    }, false);
  }

  Future _internalInit() async {
    disableRightClickContextMenu();
    engine.state.paint.isAntiAlias = false;
    await widget.init();
    engine.state.initialized.value = true;
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
      return NullableWatchBuilder<ThemeData?>(ui.themeData, (ThemeData? themeData){
        return MaterialApp(
          title: widget.title,
          routes: widget.routes ?? {},
          theme: themeData,
          home: Scaffold(
            body: WatchBuilder(engine.state.initialized, (bool? value) {
              if (value != true) {
                WidgetBuilder? buildLoadingScreen = widget.buildLoadingScreen;
                if (buildLoadingScreen != null){
                  return buildLoadingScreen(context);
                }
                return Text("Loading");
              }
              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  engine.state.buildContext = context;
                  engine.state.screen.width = constraints.maxWidth;
                  engine.state.screen.height = constraints.maxHeight;
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
    });
  }

  Widget _buildBody(BuildContext context) {

    Widget child = PositionedTapDetector2(
      onLongPress: (TapPosition position) {
        _previousMousePosition = _mousePosition;
        _mousePosition = position.relative ?? Offset(0, 0);
        engine.callbacks.onLongLeftClicked?.call();

      },
      onTap: (position) {
        _clickProcessed = false;
        engine.callbacks.onLeftClicked?.call();
      },
      child: Listener(
        onPointerSignal: (pointerSignalEvent) {
          if (pointerSignalEvent is PointerScrollEvent) {
            engine.callbacks.onMouseScroll?.call(pointerSignalEvent.scrollDelta.dy);
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
              engine.state.mouseDragging = true;
              _previousMousePosition = _mousePosition;
              _mousePosition = start.globalPosition;
              engine.callbacks.onPanStarted?.call();
            },
            onPanEnd: (value) {
              engine.state.mouseDragging = false;
            },
            onPanUpdate: (DragUpdateDetails value) {
              _previousMousePosition = _mousePosition;
              _mousePosition = value.globalPosition;
              engine.callbacks.onMouseDragging?.call();
            },
            child: WatchBuilder(ui.backgroundColor, (Color backgroundColor){
              return Container(
                  color: backgroundColor,
                  width: engine.state.screen.width,
                  height: engine.state.screen.height,
                  child: CustomPaint(
                      painter: _GamePainter(repaint: _frame),
                      foregroundPainter: _GamePainter(
                          repaint: _foregroundFrame)));
            })),
      ),
    );

    return WatchBuilder(engine.state.cursorType, (CursorType cursorType){
      return MouseRegion(
        cursor: mapCursorTypeToSystemMouseCursor(cursorType),
        onHover: (PointerHoverEvent pointerHoverEvent) {
          _mouseDelta = pointerHoverEvent.delta;
        },
        child: child,
      );
    });
  }

  Widget _buildUI() {
    return StatefulBuilder(builder: (context, drawUI) {
      uiSetState = drawUI;
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

  const _GamePainter({required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas _canvas, Size _size) {
    engine.state.canvas = _canvas;
    _canvas.scale(engine.state.zoom, engine.state.zoom);
    _canvas.translate(-engine.state.camera.x, -engine.state.camera.y);
    engine.state.drawCanvas?.call(_canvas, _size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

