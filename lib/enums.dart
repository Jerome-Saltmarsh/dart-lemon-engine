import 'package:flutter/services.dart';

enum CursorType {
  None,
  Basic,
  Forbidden,
  Precise,
  Click,
}

final List<CursorType> cursorTypes = CursorType.values;

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
