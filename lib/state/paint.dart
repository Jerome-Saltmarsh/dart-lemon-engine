import 'dart:ui';

import 'package:flutter/material.dart';

final Paint paint = Paint()
  ..color = Colors.white
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.fill
  ..isAntiAlias = false
  ..strokeWidth = 1;

void setColorBlue(){
  setColor(Colors.blue);
}

void setColorRed(){
  setColor(Colors.blue);
}

void setColorWhite(){
  setColor(Colors.white);
}

void setStrokeWidth(double value){
  paint.strokeWidth = value;
}

void setColor(Color value) {
  if (paint.color == value) return;
  paint.color = value;
}