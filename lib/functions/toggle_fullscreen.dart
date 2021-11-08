import 'package:lemon_engine/functions/fullscreen_exit.dart';
import 'package:lemon_engine/properties/fullscreen_active.dart';

import 'fullscreen_enter.dart';

void toggleFullScreen(){
  if(fullScreenActive){
    fullScreenExit();
  }else{
    fullScreenEnter();
  }
}