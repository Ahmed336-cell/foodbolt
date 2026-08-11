import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/food_visuals.dart';

class RaceLane {
  const RaceLane({
    required this.id,
    required this.name,
    required this.isWinner,
    this.category,
  });

  final String id;
  final String name;
  final String? category;
  final bool isWinner;
}

/// Deterministic motion — every client draws the same race.
/// Critical: progress(t: 0) == 0 for ALL lanes so nobody starts ahead.
class RaceMotion {
  RaceMotion._();

  static int seedOf(String id) {
    var hash = 7;
    for (final code in id.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash;
  }

  static double progress({
    required double t,
    required String id,
    required bool isWinner,
  }) {
    if (t <= 0) return 0;
    if (t >= 1) return isWinner ? 1 : _ceiling(id);

    final seed = seedOf(id);
    final jitter = (seed % 1000) / 1000;
    final phase = jitter * pi * 2;

    // Wobble fades in AND out so start + finish stay clean.
    final envelope = sin(t * pi).clamp(0.0, 1.0);
    final wobble = sin(t * (5 + jitter * 4) + phase) * 0.055 * envelope;

    if (isWinner) {
      // Shared early pace with the pack, then a late surge.
      final base = Curves.easeInOutCubic.transform(t);
      return (base + wobble * 0.35).clamp(0.0, 1.0);
    }

    final ceiling = _ceiling(id);
    final base = Curves.easeInOut.transform(t) * ceiling;
    return (base + wobble).clamp(0.0, ceiling);
  }

  static double _ceiling(String id) {
    final jitter = (seedOf(id) % 1000) / 1000;
    return 0.72 + jitter * 0.20;
  }

  static double bob({required double t, required String id}) {
    if (t <= 0) return 0;
    final jitter = (seedOf(id) % 700) / 700;
    return sin(t * 42 + jitter * pi * 2) * 3;
  }
}

/// Vertical side-by-side lanes. Cars climb bottom → top, all driven by the
/// same `t` so they leave the start line together with zero lag.
class RaceTrack extends StatelessWidget {
  const RaceTrack({
    super.key,
    required this.lanes,
    required this.t,
    required this.running,
  });

  final List<RaceLane> lanes;
  final double t;
  final bool running;

  @override
  Widget build(BuildContext context) {
    if (lanes.isEmpty) return const SizedBox.shrink();

    final ranked = [...lanes]..sort((a, b) {
        final pa = RaceMotion.progress(t: t, id: a.id, isWinner: a.isWinner);
        final pb = RaceMotion.progress(t: t, id: b.id, isWinner: b.isWinner);
        return pb.compareTo(pa);
      });

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < lanes.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _VerticalLane(
                  lane: lanes[i],
                  t: t,
                  running: running,
                  rank: ranked.indexOf(lanes[i]) + 1,
                  laneIndex: i,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _VerticalLane extends StatelessWidget {
  const _VerticalLane({
    required this.lane,
    required this.t,
    required this.running,
    required this.rank,
    required this.laneIndex,
  });

  final RaceLane lane;
  final double t;
  final bool running;
  final int rank;
  final int laneIndex;

  static const _rankColors = <Color>[
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFFFF8F00),
    Color(0xFF43A047),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
  ];

  @override
  Widget build(BuildContext context) {
    final progress =
        RaceMotion.progress(t: t, id: lane.id, isWinner: lane.isWinner);
    final colors = FoodVisuals.gradientFor(lane.name);
    final accent = _rankColors[laneIndex % _rankColors.length];
    final emoji = FoodVisuals.emojiFor(name: lane.name, category: lane.category);

    return Column(
      children: [
        // Live rank pill at top
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: rank == 1
                ? const Color(0xFFFFC300)
                : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '#$rank',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: rank == 1 ? Colors.black87 : Colors.white70,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const racerSize = 42.0;
              const bottomPad = 8.0;
              const topPad = 22.0; // room for finish line
              final travel = (constraints.maxHeight - racerSize - bottomPad - topPad)
                  .clamp(0.0, double.infinity);
              // Bottom = 0, top = finish. dy measured from top of stack.
              final dy = topPad + (1 - progress) * travel;
              final bobX = running ? RaceMotion.bob(t: t, id: lane.id) : 0.0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _VerticalTrackPainter(
                        scroll: t,
                        accent: accent,
                        running: running,
                      ),
                    ),
                  ),
                  // Kart climbs bottom → top
                  Positioned(
                    left: (constraints.maxWidth - racerSize) / 2 + bobX * 0.3,
                    top: dy,
                    child: _Kart(
                      emoji: emoji,
                      colors: colors,
                      size: racerSize,
                      running: running && progress > 0 && progress < 1,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Brand badge under the start line
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(
                lane.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Kart extends StatelessWidget {
  const _Kart({
    required this.emoji,
    required this.colors,
    required this.size,
    required this.running,
  });

  final String emoji;
  final List<Color> colors;
  final double size;
  final bool running;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Exhaust dust below when climbing
        if (running)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final s = 5.0 - i;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Opacity(
                    opacity: 0.45 - i * 0.1,
                    child: Container(
                      width: s,
                      height: s,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(size * 0.32),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.55),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(emoji, style: TextStyle(fontSize: size * 0.48)),
        ),
      ],
    );
  }
}

class _VerticalTrackPainter extends CustomPainter {
  _VerticalTrackPainter({
    required this.scroll,
    required this.accent,
    required this.running,
  });

  final double scroll;
  final Color accent;
  final bool running;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 0, size.width - 4, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    // Track body
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1F35),
            Color.lerp(const Color(0xFF12162A), accent, 0.18)!,
          ],
        ).createShader(rect),
    );

    // Neon border
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = accent.withValues(alpha: 0.55),
    );

    canvas.save();
    canvas.clipRRect(rrect);

    // Center dashed line scrolling downward (speed illusion)
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: running ? 0.7 : 0.28)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    const dashH = 12.0;
    const gap = 14.0;
    final offset = running ? (scroll * 280) % (dashH + gap) : 0.0;
    final x = rect.center.dx;
    for (var y = -dashH + offset; y < size.height; y += dashH + gap) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dashH), dashPaint);
    }

    // Checkered finish at TOP
    const cell = 5.0;
    final finishTop = 4.0;
    final finishHeight = cell * 3;
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col * cell < rect.width - 4; col++) {
        final isDark = (row + col).isEven;
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left + 2 + col * cell,
            finishTop + row * cell,
            cell,
            cell,
          ),
          Paint()..color = isDark ? Colors.black87 : Colors.white,
        );
      }
    }
    // Soft glow under finish
    canvas.drawRect(
      Rect.fromLTWH(rect.left, finishTop + finishHeight, rect.width, 6),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromLTWH(rect.left, finishTop + finishHeight, rect.width, 6),
        ),
    );

    // Start line at BOTTOM
    final startY = size.height - 6;
    canvas.drawLine(
      Offset(rect.left + 4, startY),
      Offset(rect.right - 4, startY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 2,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VerticalTrackPainter oldDelegate) =>
      oldDelegate.scroll != scroll ||
      oldDelegate.running != running ||
      oldDelegate.accent != accent;
}
