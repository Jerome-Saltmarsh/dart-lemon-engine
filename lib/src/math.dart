import 'dart:math';

/// measure the distance between two points
double distance(double x1, double y1, double x2, double y2) =>
    hyp(x1 - x2, y1 - y2);

/// radians between two points
double angleBetween(double x1, double y1, double x2, double y2) =>
    angle(x1 - x2, y1 - y2);

/// in radians
double angle(double adjacent, double opposite) {
  const pi2 = pi * 2;
  final angle = atan2(opposite, adjacent);
  return angle < 0 ? pi2 + angle : angle;
}

/// pythagoras
double hyp(num adjacent, num opposite) =>
    sqrt((adjacent * adjacent) + (opposite * opposite));

double adj(double radians, double magnitude) =>
    cos(radians) * magnitude;

double opp(double radians, double magnitude) =>
    sin(radians) * magnitude;

