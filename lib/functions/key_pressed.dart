
import 'package:flutter/services.dart';

bool keyPressed(LogicalKeyboardKey key) {
  return RawKeyboard.instance.keysPressed.contains(key);
}