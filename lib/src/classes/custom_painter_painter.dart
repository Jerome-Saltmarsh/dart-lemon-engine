import 'package:flutter/material.dart';
import 'package:lemon_engine/src.dart';

class CustomPainterPainter extends CustomPainter {

  final DrawCanvas paintCanvas;

  CustomPainterPainter(this.paintCanvas, ValueNotifier<int>? frame) :
        super(repaint: frame);

  @override
  void paint(Canvas canvas, Size size) => paintCanvas(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
