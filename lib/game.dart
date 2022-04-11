import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lemon_engine/engine.dart';
import 'package:lemon_watch/watch_builder.dart';
import 'enums.dart';

void _defaultDrawCanvasForeground(Canvas canvas, Size size) {
  // do nothing
}

final _screen = engine.screen;
final _camera = engine.camera;
const _padding = 48.0;

class Game extends StatefulWidget {
  final String title;
  final Map<String, WidgetBuilder>? routes;
  final Function init;
  final WidgetBuilder? buildLoadingScreen;
  final WidgetBuilder buildUI;
  final DrawCanvas drawCanvasForeground;
  final int framesPerSecond;

  Game({
      required this.title,
      required this.init,
      required Function update,
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
    engine.backgroundColor.value = backgroundColor;
    engine.drawCanvasAfterUpdate = drawCanvasAfterUpdate;
    engine.themeData.value = themeData;
    engine.drawCanvas.value = drawCanvas;
    engine.update = update;
  }

  void _internalUpdate() {
    _screen.left = _camera.x - _padding;
    _screen.right = _camera.x + (_screen.width / engine.zoom) + _padding;
    _screen.top = _camera.y - _padding;
    _screen.bottom = _camera.y + (_screen.height / engine.zoom) + _padding;

    if (engine.mouseLeftDown.value) {
      engine.mouseLeftDownFrames++;
    }
    
    if (engine.frame % engine.framesPerAnimationFrame == 0){
      engine.animationFrame++;
    }

    engine.update?.call();
    final sX = screenCenterWorldX;
    final sY = screenCenterWorldY;
    final zoomDiff = engine.targetZoom - engine.zoom;
    engine.zoom += zoomDiff * engine.zoomSensitivity;
    engine.cameraCenter(sX, sY);

    if (engine.drawCanvasAfterUpdate) {
      engine.redrawCanvas();
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
  }

  Future _internalInit() async {
    engine.disableRightClickContextMenu();
    engine.paint.isAntiAlias = false;
    await widget.init();
    engine.initialized.value = true;
    int millisecondsPerFrame = millisecondsPerSecond ~/ widget.framesPerSecond;
    Duration updateDuration = Duration(milliseconds: millisecondsPerFrame);
    _updateTimer = Timer.periodic(updateDuration, _update);
    print("Lemon Engine - Update Job Started");
  }

  @override
  Widget build(BuildContext context) {
    return WatchBuilder(engine.themeData, (ThemeData? themeData){
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
                engine.buildContext = context;
                engine.screen.width = constraints.maxWidth;
                engine.screen.height = constraints.maxHeight;
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

    final child = Listener(
      onPointerSignal: (PointerSignalEvent pointerSignalEvent) {
        if (pointerSignalEvent is PointerScrollEvent) {
          engine.callbacks.onMouseScroll?.call(pointerSignalEvent.scrollDelta.dy);
        }
      },
      onPointerDown: (PointerDownEvent event){
        engine.mouseLeftDown.value = true;
      },
      onPointerUp: (PointerUpEvent event){
        engine.mouseLeftDown.value = false;
        engine.mouseLeftDownFrames = 0;
      },
      onPointerHover:(PointerHoverEvent event){
        engine.previousMousePosition.x = engine.mousePosition.x;
        engine.previousMousePosition.y = engine.mousePosition.y;
        engine.mousePosition.x = event.position.dx;
        engine.mousePosition.y = event.position.dy;
        engine.callbacks.onMouseMoved?.call(
            engine.mousePosition, engine.previousMousePosition
        );
      },
      onPointerMove: (PointerMoveEvent event){
        engine.previousMousePosition.x = engine.mousePosition.x;
        engine.previousMousePosition.y = engine.mousePosition.y;
        engine.mousePosition.x = event.position.dx;
        engine.mousePosition.y = event.position.dy;
        engine.callbacks.onMouseMoved?.call(
            engine.mousePosition, engine.previousMousePosition
        );
      },
      child: GestureDetector(
          onLongPress: (){
            engine.callbacks.onLongLeftClicked?.call();
          },
          onTap: (){
            engine.callbacks.onLeftClicked?.call();
          },
          onPanStart: (start) {
            engine.mouseDragging = true;
            engine.callbacks.onPanStarted?.call();
          },
          onPanUpdate: (DragUpdateDetails value) {
            engine.callbacks.onMouseDragging?.call();
          },
          onPanEnd: (value) {
            engine.mouseDragging = false;
          },
          onSecondaryTapDown: (_) {
            engine.callbacks.onRightClicked?.call();
          },
          onSecondaryTapUp: (_) {
            engine.callbacks.onRightClickReleased?.call();
          },
          child: WatchBuilder(engine.backgroundColor, (Color backgroundColor){
            return Container(
                color: backgroundColor,
                width: engine.screen.width,
                height: engine.screen.height,
                child: CustomPaint(
                    painter: _GamePainter(repaint: engine.drawFrame),
                    foregroundPainter: _GameForegroundPainter(repaint: _foregroundFrame),
                )
            );
          })),
    );

    return WatchBuilder(engine.cursorType, (CursorType cursorType){
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
  void paint(Canvas canvas, Size size) {
    engine.canvas = canvas;
    canvas.scale(engine.zoom, engine.zoom);
    canvas.translate(-_camera.x, -_camera.y);
    engine.drawCanvas.value?.call(canvas, size);
    if (engine.drawCanvas.isNotNull){
      engine.flushRenderBuffer();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}


class _GameForegroundPainter extends CustomPainter {

  const _GameForegroundPainter({required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size _size) {
    engine.canvas = canvas;
    canvas.scale(engine.zoom, engine.zoom);
    canvas.translate(-engine.camera.x, -engine.camera.y);
    engine.drawForeground.value?.call(canvas, _size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

