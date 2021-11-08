import 'package:lemon_engine/functions/screen_to_world.dart';
import 'package:lemon_engine/game.dart';

double get mouseWorldX => screenToWorldX(mouseX);
double get mouseWorldY => screenToWorldY(mouseY);