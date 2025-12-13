import 'package:flutter/material.dart';
import 'dart:math';

class FlyingHeart extends StatefulWidget {
  @override
  _FlyingHeartState createState() => _FlyingHeartState();
}

class _FlyingHeartState extends State<FlyingHeart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<Offset> _position;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    // Animation Duration: 2 seconds to float up
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
    );

    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2, curve: Curves.easeOut)),
    );

    // Wiggle effect (Random left/right movement)
    final double endX = (_random.nextDouble() * 100) - 50; 
    _position = Tween<Offset>(begin: Offset.zero, end: Offset(endX, -300)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward().then((_) {
      if (mounted) {
        // Remove self from tree is tricky in pure Flutter without a manager, 
        // but for this visual effect, letting it finish is fine.
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Random Heart Color
    final color = [Colors.red, Colors.pink, Colors.purple, Colors.orange][_random.nextInt(4)];
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _position.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _opacity.value,
              child: Icon(Icons.favorite, color: color, size: 30),
            ),
          ),
        );
      },
    );
  }
}