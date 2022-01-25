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
  final DrawCanvas drawCanvasForeground;

  Game({
      required this.title,
      required Function update,
      WidgetBuilder? buildUI,
      Function? init,
      WidgetBuilder? buildLoadingScreen,
      this.routes,
      this.drawCanvasForeground = _defaultDrawCanvasForeground,
      DrawCanvas? drawCanvas,
      Color backgroundColor = Colors.black,
      bool drawCanvasAfterUpdate = true,
      ThemeData? themeData,
  }){
    engine.state.buildLoadingScreen = buildLoadingScreen;
    engine.state.backgroundColor.value = backgroundColor;
    engine.state.themeData.value = themeData;
    engine.state.drawCanvasAfterUpdate = drawCanvasAfterUpdate;
    engine.state.drawCanvas = drawCanvas;
    engine.state.update = update;
    if (buildUI != null){
      engine.state.buildUI = buildUI;
    }
    engine.init(init);
  }

  @override
  _GameState createState() => _GameState();
}

const int millisecondsPerSecond = 1000;

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
              final buildLoadingScreen = engine.state.buildLoadingScreen;
              if (buildLoadingScreen != null){
                return buildLoadingScreen(context);
              }
              return Center(child: Text("Loading"));
            }
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                engine.state.buildContext = context;
                engine.state.screen.width = constraints.maxWidth;
                engine.state.screen.height = constraints.maxHeight;
                return Stack(
                  children: [
                    _buildBody(context),
                    engine.state.buildUI(context),
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
              engine.state.rightClickDown.value = true;
              engine.callbacks.onRightClickDown?.call();
            },
            onSecondaryTapUp: (_) {
              engine.callbacks.onRightClickUp?.call();
              engine.state.rightClickDown.value = false;
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

