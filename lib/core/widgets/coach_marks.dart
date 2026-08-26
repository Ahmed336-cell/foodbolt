import 'package:flutter/material.dart';

/// A single step in the guided tour.
class CoachStep {
  const CoachStep({
    required this.title,
    required this.body,
    this.icon,
    this.alignment = Alignment.center,
  });

  final String title;
  final String body;
  final IconData? icon;
  final Alignment alignment;
}

/// Full-screen overlay that walks the user through a list of [CoachStep]s.
/// Disappears after the last step.
class CoachMarksOverlay extends StatefulWidget {
  const CoachMarksOverlay({
    super.key,
    required this.steps,
    required this.onFinish,
  });

  final List<CoachStep> steps;
  final VoidCallback onFinish;

  @override
  State<CoachMarksOverlay> createState() => _CoachMarksOverlayState();
}

class _CoachMarksOverlayState extends State<CoachMarksOverlay>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  late Animation<double> _fade = CurvedAnimation(
    parent: _anim,
    curve: Curves.easeOut,
  );

  void _next() {
    if (_current >= widget.steps.length - 1) {
      widget.onFinish();
      return;
    }
    _anim.forward(from: 0);
    setState(() => _current++);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_current];
    final isLast = _current == widget.steps.length - 1;

    return GestureDetector(
      onTap: _next,
      child: Material(
        color: Colors.black54,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (step.icon != null)
                        Icon(step.icon, size: 44, color: const Color(0xFFE85D04)),
                      if (step.icon != null) const SizedBox(height: 12),
                      Text(
                        step.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        step.body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_current + 1} / ${widget.steps.length}',
                            style: const TextStyle(
                              color: Color(0xFF999999),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE85D04),
                              foregroundColor: Colors.white,
                              // Theme uses Size.fromHeight(56) → infinite width.
                              // That breaks inside a Row; pin a finite min size.
                              minimumSize: const Size(56, 44),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              isLast ? '✓' : '→',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
