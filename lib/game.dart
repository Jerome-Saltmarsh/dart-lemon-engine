import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_engine/engine.dart';
import 'package:lemon_watch/watch_builder.dart';
import 'package:positioned_tap_detector_2/positioned_tap_detector_2.dart';

import 'enums.dart';

Offset get mouseWorld => Offset(mouseWorldX, mouseWorldY);
double get screenCenterX => engine.state.screen.width * 0.5;
double get screenCenterY => engine.state.screen.height * 0.5;
double get screenCenterWorldX => screenToWorldX(screenCenterX);
double get screenCenterWorldY => screenToWorldY(screenCenterY);
Offset get screenCenterWorld => Offset(screenCenterWorldX, screenCenterWorldY);


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
  final Function update;
  final WidgetBuilder? buildLoadingScreen;
  final WidgetBuilder buildUI;
  final DrawCanvas drawCanvasForeground;
  final int framesPerSecond;

  Game({
      required this.title,
      Function? init,
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
    engine.state.themeData.value = themeData;
    engine.state.drawCanvasAfterUpdate = drawCanvasAfterUpdate;
    engine.state.drawCanvas = drawCanvas;
    engine.state.update = update;
    engine.init(init);
  }

  @override
  _GameState createState() => _GameState();
}

const int millisecondsPerSecond = 1000;
bool _rightClickDown = false;
bool get rightClickDown => _rightClickDown;

class _GameState extends State<Game> {

  @override
  Widget build(BuildContext context) {
    return NullableWatchBuilder<ThemeData?>(engine.state.themeData, (ThemeData? themeData){
      return MaterialApp(
        title: widget.title,
        routes: widget.routes ?? {},
        theme: themeData,
        home: Scaffold(
          body: WatchBuilder(engine.initialized, (bool? value) {
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
  }

  Widget _buildBody(BuildContext context) {

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
              _rightClickDown = true;
              onRightClickChanged.add(true);
            },
            onSecondaryTapUp: (_) {
              onRightClickChanged.add(false);
              _rightClickDown = false;
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
                      painter: _GamePainter(repaint: engine.state.canvasFrame),
                      foregroundPainter: _GamePainter(
                          repaint: engine.state.foregroundCanvasFrame)));
            })),
      ),
    );

    return WatchBuilder(engine.state.cursorType, (CursorType cursorType){
      return MouseRegion(
        cursor: mapCursorTypeToSystemMouseCursor(cursorType),
        // onHover: (PointerHoverEvent pointerHoverEvent) {
        //   _mouseDelta = pointerHoverEvent.delta;
        // },
        child: child,
      );
    });
  }

  Widget _buildUI() {
    return widget.buildUI(context);
  }

  @override
  void dispose() {
    super.dispose();
    engine.dispose();
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

