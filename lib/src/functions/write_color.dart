
int rgba({
  int r = 0,
  int g = 0,
  int b = 0,
  int a = 0,
}) => int32(a, b, g, r);

int int32(int a, int b, int c, int d) =>
    (a << 24) | (b << 16) | (c << 8) | d;
