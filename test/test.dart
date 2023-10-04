
import 'package:lemon_engine/lemon_engine.dart';
import 'package:test/test.dart';

void main() {
  test('convertFramesPerSecondToDuration', () {

    expect(convertFramesPerSecondToDuration(30).inMilliseconds, 33);
  });
}
