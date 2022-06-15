
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;
import 'canvas.dart';
import 'engine.dart';

class LemonEngineDraw {

  void circle(double x, double y, double radius, Color color) {
    circleOffset(Offset(x, y), radius, color);
  }

  void circleOffset(Offset offset, double radius, Color color) {
    engine.paint.color = color;
    canvas.drawCircle(offset, radius, engine.paint);
  }

  void atlas(ui.Image image, List<RSTransform> transforms, List<Rect> rects){
    canvas.drawAtlas(image, transforms, rects, null, null, null, engine.paint);
  }

  void drawCircleOutline({
    required double radius,
    required double x,
    required double y,
    required Color color,
    int sides = 6,
    double width = 3,
  }) {
    double r = (pi * 2) / sides;
    List<Offset> points = [];
    Offset z = Offset(x, y);
    engine.setPaintColor(color);
    engine.paint.strokeWidth = width;

    for (int i = 0; i <= sides; i++) {
      double a1 = i * r;
      points.add(Offset(cos(a1) * radius, sin(a1) * radius));
    }
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i] + z, points[i + 1] + z, engine.paint);
    }
  }
}