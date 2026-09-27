import 'package:flutter/material.dart';

import '../data/part.dart';
import '../engine/renderer.dart';

/// Small static 3D render of a single part for the parts tray.
class PartThumbnail extends StatelessWidget {
  const PartThumbnail({
    super.key,
    required this.part,
    required this.paintColor,
  });

  final VehiclePart part;
  final Color paintColor;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ThumbPainter(part, paintColor),
      ),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.part, this.paintColor);

  final VehiclePart part;
  final Color paintColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cam = OrbitCamera(yaw: 0.8, pitch: 0.45)..fit(part.bounds);
    drawScene(canvas, size, cam, [
      RenderItem(part.faces),
    ], SceneStyle(paintColor: paintColor, ground: false, shadow: false));
  }

  @override
  bool shouldRepaint(_ThumbPainter old) =>
      old.part != part || old.paintColor != paintColor;
}
