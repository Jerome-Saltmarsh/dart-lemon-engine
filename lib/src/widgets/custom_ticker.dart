import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class CustomTicker extends StatefulWidget {

  final Widget? child;
  final Function(Duration elapsed) onTrick;
  final Function? onDispose;

  const CustomTicker({super.key, required this.onTrick, this.child, this.onDispose});

  @override
  _CustomTickerState createState() => _CustomTickerState();
}

class _CustomTickerState extends State<CustomTicker> with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(widget.onTrick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
    widget.onDispose?.call();
  }

  @override
  Widget build(BuildContext context) => widget.child ?? Container();
}
