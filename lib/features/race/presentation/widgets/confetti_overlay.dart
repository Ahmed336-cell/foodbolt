import 'dart:math';

import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, this.pieces = 70});

  final int pieces;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  late final List<_Piece> _confetti = List.generate(
    widget.pieces,
    (i) => _Piece.random(Random(i * 7919)),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(_confetti, _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Piece {
  _Piece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.color,
    required this.spin,
    required this.drift,
  });

  final double x;
  final double delay;
  final double speed;
  final double size;
  final Color color;
  final double spin;
  final double drift;

  static const _colors = [
    Color(0xFFE85D04),
    Color(0xFFF48C06),
    Color(0xFFFFC300),
    Color(0xFF2A9D8F),
    Color(0xFF9B5DE5),
    Color(0xFFFF8FA3),
  ];

  factory _Piece.random(Random r) {
    return _Piece(
      x: r.nextDouble(),
      delay: r.nextDouble(),
      speed: 0.6 + r.nextDouble() * 0.8,
      size: 5 + r.nextDouble() * 7,
      color: _colors[r.nextInt(_colors.length)],
      spin: (r.nextDouble() - 0.5) * 12,
      drift: (r.nextDouble() - 0.5) * 0.25,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final progress = ((t * p.speed) + p.delay) % 1.0;
      final dy = progress * (size.height + 60) - 30;
      final dx = (p.x + sin(progress * pi * 2) * p.drift) * size.width;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(progress * p.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.55,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = p.color,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
