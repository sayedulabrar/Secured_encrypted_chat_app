import 'package:flutter/material.dart';
import 'dart:math' show pi, sin;
import 'dart:async';

class ShakingListTile extends StatefulWidget {
  final Widget child;

  const ShakingListTile({Key? key, required this.child}) : super(key: key);

  @override
  _ShakingListTileState createState() => _ShakingListTileState();
}

class _ShakingListTileState extends State<ShakingListTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _startAnimationCycle();
  }

  void _startAnimationCycle() {
    _controller.repeat(reverse: true);
    _timer = Timer(const Duration(seconds: 2), () {
      _controller.stop();
      _timer = Timer(const Duration(seconds: 2), _startAnimationCycle);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(sin(_controller.value * 2 * pi) * 2, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}