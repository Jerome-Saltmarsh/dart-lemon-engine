
import 'dart:math';

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

  void drawCircleOutline({
    required double radius,
    required double x,
    required double y,
    required Color color,
    int sides = 6
  }) {
    double r = (pi * 2) / sides;
    List<Offset> points = [];
    Offset z = Offset(x, y);
    engine.actions.setPaintColor(color);
    engine.state.paint.strokeWidth = 3;

    for (int i = 0; i <= sides; i++) {
      double a1 = i * r;
      points.add(Offset(cos(a1) * radius, sin(a1) * radius));
    }
    for (int i = 0; i < points.length - 1; i++) {
      engine.state.canvas.drawLine(points[i] + z, points[i + 1] + z, engine.state.paint);
    }
  }

}