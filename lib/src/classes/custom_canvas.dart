
import 'package:flutter/material.dart';
import 'package:lemon_engine/src.dart';


class CustomCanvas extends StatelessWidget {

  final DrawCanvas paint;
  final ValueNotifier<int>? frame;

  const CustomCanvas({
    super.key,
    required this.paint,
    this.frame,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: CustomPainterPainter(
          paint,
          frame
      ),
    );
}

