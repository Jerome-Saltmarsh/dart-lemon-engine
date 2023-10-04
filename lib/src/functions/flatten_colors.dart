
import 'dart:typed_data';

/// Converts a [Uint32List] of colors to a [Uint8List] with flattened ARGB components.
/// The input [colors] list must not be null, and its length should be divisible by 4.
Uint8List flattenUInt32List(Uint32List colors) {
  final colorsLength = colors.length;
  final flattenedColors = Uint8List(colorsLength * 4);

  for (var i = 0; i < colorsLength;) {
    final color = colors[i];
    final alpha = (color >> 24) & 0xFF;
    final red = (color >> 16) & 0xFF;
    final green = (color >> 8) & 0xFF;
    final blue = color & 0xFF;
    flattenedColors[i++] = alpha;
    flattenedColors[i++] = red;
    flattenedColors[i++] = green;
    flattenedColors[i++] = blue;
  }
  return flattenedColors;
}
