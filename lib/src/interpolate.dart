
/// @t a decimal between 0 and 1
int interpolate({required int start, required int end, required double t}) =>
  (start * (1.0 - t) + end * t).toInt();

double interpolateDouble({required double start, required double end, required double t}) =>
    (start * (1.0 - t) + end * t);