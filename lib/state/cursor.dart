
import 'package:flutter/services.dart';
import 'package:lemon_watch/watch.dart';

final Watch<CursorType> cursorType = Watch(CursorType.Precise);

enum CursorType {
  None,
  Basic,
  Forbidden,
  Precise,
  Click,
}

SystemMouseCursor mapCursorTypeToSystemMouseCursor(CursorType value){
  switch(value){
    case CursorType.Forbidden:
      return SystemMouseCursors.forbidden;
    case CursorType.Precise:
      return SystemMouseCursors.precise;
    case CursorType.None:
      return SystemMouseCursors.none;
    case CursorType.Click:
      return SystemMouseCursors.click;
    default:
      return SystemMouseCursors.basic;
  }
}

