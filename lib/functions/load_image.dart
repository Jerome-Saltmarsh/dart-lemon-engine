import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';


Future<Image> loadImage(String url) async {
  final ByteData data = await rootBundle.load(url);
  final Uint8List img = Uint8List.view(data.buffer);
  final Completer<Image> completer = new Completer();
  decodeImageFromList(img, (Image img) {
    return completer.complete(img);
  });
  return completer.future;
}
