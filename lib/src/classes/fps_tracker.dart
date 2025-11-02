

import 'package:flutter/cupertino.dart';

class FpsTracker {

  final fps = ValueNotifier(0);
  var _previous = DateTime.now();

  void update(){
    var now = DateTime.now();
    final diff = now.difference(_previous);
    _previous = now;
    fps.value = _convertDurationToFramesPerSecond(diff);
  }
}

int _convertDurationToFramesPerSecond(Duration duration) =>
    duration.inMilliseconds <= 0 ? 0 :
    Duration.millisecondsPerSecond ~/ duration.inMilliseconds;
