
import 'dart:ui';

import 'package:flutter/services.dart';

Future<Image> loadAssetImage(String url) async {
  final bytes = await loadAssetBytes(url);
  return await buildImageBytes(bytes);
}

Future<Uint8List> loadAssetBytes(String url) async {
  final byteData = await rootBundle.load(url);
  return Uint8List.view(byteData.buffer);
}

Future<Image> buildImageBytes(Uint8List bytes) async {
  final codec = await instantiateImageCodec(bytes);
  final frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}