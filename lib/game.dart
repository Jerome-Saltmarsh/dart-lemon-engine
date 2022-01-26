import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_engine/engine.dart';
import 'package:lemon_watch/watch_builder.dart';
import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart';
import 'package:universal_html/html.dart';

import 'enums.dart';

// private global variables
Offset _mousePosition = Offset(0, 0);
Offset _previousMousePosition = Offset(0, 0);

// global properties
Offset get mousePosition => _mousePosition;

Offset get previousMousePosition => _previousMousePosition;

double get mouseX => _mousePosition.dx;

double get mouseY => _mousePosition.dy;

Offset get mouse => Offset(mouseX, mouseY);

Offset get mouseWorld => Offset(mouseWorldX, mouseWorldY);

double get screenCenterX => engine.state.screen.width * 0.5;
double get screenCenterY => engine.state.screen.height * 0.5;

double get screenCenterWorldX => screenToWorldX(screenCenterX);

double get screenCenterWorldY => screenToWorldY(screenCenterY);

Offset get screenCenterWorld => Offset(screenCenterWorldX, screenCenterWorldY);

int get millisecondsSinceLastFrame => engine.state.millisecondsSinceLastFrame;

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
    engine.state.backgroundColor.value = backgroundColor;
    engine.state.drawCanvasAfterUpdate = drawCanvasAfterUpdate;
    engine.state.themeData.value = themeData;
    engine.state.drawCanvas = drawCanvas;
  }

  void _internalUpdate() {
    DateTime now = DateTime.now();
    engine.state.millisecondsSinceLastFrame = now.difference(engine.state.previousUpdateTime).inMilliseconds;
    if (engine.state.millisecondsSinceLastFrame > 0){
      engine.state.fps.value = millisecondsPerSecond ~/ engine.state.millisecondsSinceLastFrame;
    }
    engine.state.previousUpdateTime = now;
    engine.state.screen.left = engine.state.camera.x;
    engine.state.screen.right = engine.state.camera.x + (engine.state.screen.width / engine.state.zoom);
    engine.state.screen.top = engine.state.camera.y;
    engine.state.screen.bottom = engine.state.camera.y + (engine.state.screen.height / engine.state.zoom);
    update();

    if (engine.state.drawCanvasAfterUpdate) {
      engine.actions.redrawCanvas();
    }
  }

  @override
  _GameState createState() => _GameState();
}

final _foregroundFrame = ValueNotifier<int>(0);



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
        _mousePosition = Offset(value.page.x.toDouble(), value.page.y.toDouble());
        engine.callbacks.onMouseMoved?.call(
          _mousePosition, _previousMousePosition
        );
      }
    }, false);
  }

  Future _internalInit() async {
    engine.actions.disableRightClickContextMenu();
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
    return NullableWatchBuilder<ThemeData?>(engine.state.themeData, (ThemeData? themeData){
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
                    _buildCanvas(context),
                    widget.buildUI(context),
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

  Widget _buildCanvas(BuildContext context) {

    Widget child = PositionedTapDetector2(
      onLongPress: (TapPosition position) {
        engine.callbacks.onLongLeftClicked?.call();

      },
      onTap: (position) {
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
              onRightClickChanged.add(true);
            },
            onSecondaryTapUp: (_) {
              onRightClickChanged.add(false);
            },
            onPanStart: (start) {
              engine.state.mouseDragging = true;
              engine.callbacks.onPanStarted?.call();
            },
            onPanEnd: (value) {
              engine.state.mouseDragging = false;
            },
            onPanUpdate: (DragUpdateDetails value) {
              engine.callbacks.onMouseDragging?.call();
            },
            child: WatchBuilder(engine.state.backgroundColor, (Color backgroundColor){
              return Container(
                  color: backgroundColor,
                  width: engine.state.screen.width,
                  height: engine.state.screen.height,
                  child: CustomPaint(
                      painter: _GamePainter(repaint: engine.state.drawFrame),
                      foregroundPainter: _GamePainter(
                          repaint: _foregroundFrame)));
            })),
      ),
    );

    return WatchBuilder(engine.state.cursorType, (CursorType cursorType){
      return MouseRegion(
        cursor: mapCursorTypeToSystemMouseCursor(cursorType),
        child: child,
      );
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

