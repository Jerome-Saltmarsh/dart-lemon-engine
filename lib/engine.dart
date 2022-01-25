import 'package:lemon_engine/actions.dart';
import 'package:lemon_engine/callbacks.dart';
import 'package:lemon_engine/draw.dart';
import 'package:lemon_engine/queries.dart';
import 'package:lemon_engine/state.dart';
import 'package:lemon_engine/utilities.dart';

final _Engine engine = _Engine();

class _Engine {
  final state = LemonEngineState();
  final actions = LemonEngineActions();
  final utilities = LemonEngineUtilities();
  final callbacks = LemonEngineCallbacks();
  final draw = LemonEngineDraw();
  final queries = LemonEngineQueries();
}