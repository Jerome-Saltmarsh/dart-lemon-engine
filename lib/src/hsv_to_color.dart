
int hsvToColor({
  required int hue,
  required int saturation,
  required int value,
  required int opacity,
}) {
  double h = hue / 360;
  double s = saturation / 100;
  double v = value / 100;

  int i = (h * 6).floor();
  double f = h * 6 - i;
  double p = v * (1 - s);
  double q = v * (1 - f * s);
  double t = v * (1 - (1 - f) * s);

  double r, g, b;
  switch (i % 6) {
    case 0:
      r = v;
      g = t;
      b = p;
      break;
    case 1:
      r = q;
      g = v;
      b = p;
      break;
    case 2:
      r = p;
      g = v;
      b = t;
      break;
    case 3:
      r = p;
      g = q;
      b = v;
      break;
    case 4:
      r = t;
      g = p;
      b = v;
      break;
    case 5:
      r = v;
      g = p;
      b = q;
      break;
    default:
      r = 0;
      g = 0;
      b = 0;
      break;
  }

  int red = (r * 255).round();
  int green = (g * 255).round();
  int blue = (b * 255).round();

  return (opacity & 0xff) << 24 | (red & 0xff) << 16 | (green & 0xff) << 8 | (blue & 0xff);
}