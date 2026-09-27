import 'package:flutter/material.dart';

import '../engine/renderer.dart';
import '../engine/vec3.dart';

/// A name tag pointing at a spot on the 3D model.
class Label3D {
  const Label3D(this.anchor, this.text, this.color, {this.strong = false});
  final V3 anchor;
  final String text;
  final Color color;

  /// Larger, highlighted tag (the selected part).
  final bool strong;
}

/// Draws name tags with leader lines. Tags are staggered vertically so
/// neighbouring names overlap less.
void paintLabels(Canvas canvas, OrbitCamera cam, List<Label3D> labels) {
  for (var i = 0; i < labels.length; i++) {
    final l = labels[i];
    final p = cam.toScreen(l.anchor);
    final lift = l.strong ? 46.0 : 26.0 + (i % 3) * 16;
    final tp = TextPainter(
      text: TextSpan(
        text: l.text,
        style: TextStyle(
          color: Colors.white,
          fontSize: l.strong ? 14 : 11,
          fontWeight: l.strong ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final box = Rect.fromCenter(
      center: p - Offset(0, lift),
      width: tp.width + 14,
      height: tp.height + 8,
    );
    final line = Paint()
      ..color = l.color.withValues(alpha: 0.9)
      ..strokeWidth = l.strong ? 2 : 1.2;
    canvas.drawLine(p, Offset(p.dx, box.bottom), line);
    canvas.drawCircle(p, l.strong ? 4 : 2.5, Paint()..color = l.color);
    final rr = RRect.fromRectAndRadius(box, const Radius.circular(8));
    canvas.drawRRect(rr, Paint()..color = const Color(0xE6161A20));
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = l.strong ? 2 : 1
        ..color = l.color,
    );
    tp.paint(canvas, Offset(box.left + 7, box.top + 4));
  }
}
