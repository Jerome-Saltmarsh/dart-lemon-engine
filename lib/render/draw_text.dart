import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:lemon_engine/state/canvas.dart';
import 'package:lemon_engine/state/textPainter.dart';
import 'package:lemon_engine/state/textStyle.dart';

void drawText(String text, double x, double y, {Canvas? canvas, TextStyle? style}) {
  textPainter.text = TextSpan(style: style ?? textStyle, text: text);
  textPainter.layout();
  textPainter.paint(canvas ?? globalCanvas, Offset(x, y));
}

