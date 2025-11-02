import 'package:flutter/cupertino.dart';

import '../../src.dart';

class CanvasPainter extends CustomPainter {

  final DrawCanvas drawCanvas;

  const CanvasPainter({
    required Listenable repaint,
    required this.drawCanvas,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas _canvas, Size size) {
    drawCanvas(_canvas, size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
