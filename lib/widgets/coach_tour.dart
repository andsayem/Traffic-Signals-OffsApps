import 'package:flutter/material.dart';
import '../utils/theme_constants.dart';

/// One step of a [CoachTour]: highlights the widget behind [targetKey]
/// (or, if it has no size, the area returned by [fallbackRect]).
class CoachStep {
  const CoachStep({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    this.targetKey,
    this.fallbackRect,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final GlobalKey? targetKey;
  final Rect Function(Size screen)? fallbackRect;
}

/// A lightweight spotlight tour: dims the screen, cuts a glowing hole
/// around each target and explains it with a card + Next/Skip.
class CoachTour {
  CoachTour._();

  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    List<CoachStep> steps, {
    VoidCallback? onFinish,
    Future<void> Function(int index)? beforeStep,
  }) {
    if (_entry != null || steps.isEmpty) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CoachOverlay(
        steps: steps,
        beforeStep: beforeStep,
        onClose: () {
          entry.remove();
          _entry = null;
          onFinish?.call();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

class _CoachOverlay extends StatefulWidget {
  const _CoachOverlay({
    required this.steps,
    required this.onClose,
    this.beforeStep,
  });

  final List<CoachStep> steps;
  final VoidCallback onClose;
  final Future<void> Function(int index)? beforeStep;

  @override
  State<_CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<_CoachOverlay>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  Rect? _hole;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _goTo(0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _goTo(int index) async {
    await widget.beforeStep?.call(index);
    // Let any scroll triggered by beforeStep settle before measuring.
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    setState(() {
      _index = index;
      _hole = _measure(widget.steps[index]);
    });
  }

  Rect? _measure(CoachStep step) {
    final box =
        step.targetKey?.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.attached) {
      return (box.localToGlobal(Offset.zero) & box.size).inflate(8);
    }
    final size = MediaQuery.sizeOf(context);
    return step.fallbackRect?.call(size);
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      widget.onClose();
    } else {
      _goTo(_index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final size = MediaQuery.sizeOf(context);
    final hole = _hole;
    // Put the card on whichever side of the hole has more room.
    final cardBelow = hole == null || hole.center.dy < size.height / 2;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dim + spotlight hole (tapping the dim area advances).
          GestureDetector(
            onTap: _next,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => CustomPaint(
                size: size,
                painter: _SpotlightPainter(
                  hole: hole,
                  color: step.color,
                  pulse: _pulse.value,
                ),
              ),
            ),
          ),

          // Explanation card
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            left: 16,
            right: 16,
            top: cardBelow ? (hole?.bottom ?? size.height * 0.3) + 16 : null,
            bottom: cardBelow ? null : size.height - hole.top + 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _CoachCard(
                key: ValueKey(_index),
                step: step,
                index: _index,
                total: widget.steps.length,
                onNext: _next,
                onSkip: widget.onClose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    super.key,
    required this.step,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  final CoachStep step;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: step.color.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: step.color.withValues(alpha: 0.3), blurRadius: 24),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(step.icon, color: step.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${index + 1} / $total',
                style: TextStyle(
                  color: step.color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            step.body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!isLast)
                TextButton(
                  onPressed: onSkip,
                  child: const Text(
                    'Skip tour',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: step.color,
                  foregroundColor: step.color == ThemeConstants.signalYellow
                      ? Colors.black
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  size: 18,
                ),
                label: Text(
                  isLast ? "Got it, let's go!" : 'Next',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.hole,
    required this.color,
    required this.pulse,
  });

  final Rect? hole;
  final Color color;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.78);
    final h = hole;
    if (h == null) {
      canvas.drawRect(Offset.zero & size, dim);
      return;
    }
    final rrect = RRect.fromRectAndRadius(h, const Radius.circular(22));
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(rrect),
      ),
      dim,
    );
    // Pulsing glow ring around the target
    canvas.drawRRect(
      rrect.inflate(3 + 5 * pulse),
      Paint()
        ..color = color.withValues(alpha: 0.9 - 0.6 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.color != color || old.pulse != pulse;
}
