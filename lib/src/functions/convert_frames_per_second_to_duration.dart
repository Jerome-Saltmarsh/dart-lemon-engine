

Duration convertFramesPerSecondToDuration(int framesPerSecond) =>
    Duration(milliseconds: (Duration.millisecondsPerSecond / framesPerSecond).round());