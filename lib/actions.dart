
import 'dart:html';

void fullScreenEnter() {
  final element = document.documentElement;
  if (element == null){
    return print("fullScreenEnter() error: document.documentElement == null");
  }
  element.requestFullscreen();
}