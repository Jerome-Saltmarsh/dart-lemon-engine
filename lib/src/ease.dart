

import 'dart:math';

class EaseFunctions {

  static double inSine(double x) => 1 - cos((x * pi) * 0.5);
  static double outSine(double x) => sin((x * pi) * 0.5);
  static double inOutSine(double x) => -(cos(pi * x) - 1) / 2;

  static double inQuad(double x) => x * x;
  static double outQuad(double x) => 1 - (1 - x) * (1 - x);
  static double inOutQuad(double x) => x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2;

  static double inCubic(double x) => x * x * x;
  static double outCubic(double x) => 1.0 - pow(1.0 - x, 3);
  static double inOutCubic(double x) => x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2;

  static double inQuart(double x) => x * x * x * x;
  static double outQuart(double x) => 1.0 - pow(1.0 - x, 4);
  static double inOutQuart(double x) => x < 0.5 ? 8 * x * x * x * x : 1 - pow(-2 * x + 2, 4) / 2;

  static double inQuint(double x) => x * x * x * x * x;
  static double outQuint(double x) => 1.0 - pow(1 - x, 5);
  static double inOutQuint(double x) => x < 0.5 ? 16 * x * x * x * x * x : 1 - pow(-2 * x + 2, 5) / 2;

  static double inExpo(double x) => x == 0.0 ? 0.0 : pow(2, 10.0 * x - 10.0).toDouble();
  static double outExpo(double x) => x == 1 ? 1.0 : 1 - pow(2, -10 * x).toDouble();
  static double inOutExpo(double x) => x == 0
      ? 0
      : x == 1
      ? 1
      : x < 0.5
      ? pow(2, 20 * x - 10) / 2
      : (2 - pow(2, -20 * x + 10)) / 2;



  static double inCirc(double x) => 1 - sqrt(1 - pow(x, 2));
  static double outCirc(double x) => sqrt(1 - pow(x - 1, 2));
  static double inOutCirc(double x) => x < 0.5
      ? (1 - sqrt(1 - pow(2 * x, 2))) / 2
      : (sqrt(1 - pow(-2 * x + 2, 2)) + 1) / 2;


}

typedef EaseFunction = double Function(double i);

enum EaseType {
  In_Sine(EaseFunctions.inSine),
  Out_Sine(EaseFunctions.outSine),
  In_Out_Sine(EaseFunctions.inOutSine),
  In_Quad(EaseFunctions.inQuad),
  Out_Quad(EaseFunctions.outQuad),
  In_Out_Quad(EaseFunctions.inOutQuad),
  In_Cubic(EaseFunctions.inCubic),
  Out_Cubic(EaseFunctions.outCubic),
  In_Out_Cubic(EaseFunctions.inOutCubic),
  In_Quart(EaseFunctions.inQuart),
  Out_Quart(EaseFunctions.outQuart),
  In_Out_Quart(EaseFunctions.inOutQuart),
  In_Quint(EaseFunctions.inQuint),
  Out_Quint(EaseFunctions.outQuint),
  In_Out_Quint(EaseFunctions.inOutQuint),
  In_Expo(EaseFunctions.inExpo),
  Out_Expo(EaseFunctions.outExpo),
  In_Out_Expo(EaseFunctions.inOutExpo),
  In_Circ(EaseFunctions.inCirc),
  Out_Circ(EaseFunctions.outCirc),
  In_Out_Circ(EaseFunctions.inOutCirc);

  const EaseType(this.function);

  final EaseFunction function;

  List<double> generate({required int length}) =>
      List.generate(
        length,
            (i) => function(i * (1 / length)),
        growable: false,
      );
}


