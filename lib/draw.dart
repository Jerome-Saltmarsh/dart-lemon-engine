
import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;
import 'engine.dart';

class LemonEngineDraw {

  void circle(double x, double y, double radius, Color color) {
    circleOffset(Offset(x, y), radius, color);
  }

  void circleOffset(Offset offset, double radius, Color color) {
    engine.state.paint.color = color;
    engine.state.canvas.drawCircle(offset, radius, engine.state.paint);
  }

  void text(String text, double x, double y, {Canvas? canvas, required TextStyle style}) {
    engine.state.textPainter.text = TextSpan(style: style, text: text);
    engine.state.textPainter.layout();
    engine.state.textPainter.paint(canvas ?? engine.state.canvas, Offset(x, y));
  }

  void atlas(ui.Image image, List<RSTransform> transforms, List<Rect> rects){
    engine.state.canvas.drawAtlas(image, transforms, rects, null, null, null, engine.state.paint);
  }
}