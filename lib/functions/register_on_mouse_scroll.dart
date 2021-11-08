

import 'package:lemon_engine/state/onMouseScroll.dart';

void registerOnMouseScroll(Function(double value) value){
  onMouseScroll = value;
}