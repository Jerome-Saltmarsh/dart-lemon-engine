int convertDurationToFramesPerSecond(Duration duration) =>
    Duration.millisecondsPerSecond ~/ duration.inMilliseconds;
