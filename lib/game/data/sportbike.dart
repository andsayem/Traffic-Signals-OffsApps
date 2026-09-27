import 'dart:ui' show Color;

import '../engine/mesh.dart';
import '../engine/vec3.dart';
import 'motorbike.dart';
import 'part.dart';

// A sports bike: the street bike's frame, engine and wheels wrapped in a
// full front fairing with a windscreen and twin headlights.

const _black = Color(0xFF16181B);
const _glass = Color(0xFF9BC7E6);
const _lens = Color(0xFFF4F8FF);
const _drl = Color(0xFFE3F2FD);
const _amber = Color(0xFFFFA726);

List<VehiclePart> buildSportBike() {
  final parts = buildMotorbike();
  final l = PartList();

  l.add(
    'fairing',
    'Fairing',
    PartGroup.body,
    const V3(1.6, 0.6, 0),
    'The fairing is a streamlined shell that cuts through the air, so the bike goes faster and the rider is shielded from wind.',
    ['engine', 'headlight', 'handlebar'],
    (m) {
      m.paint();
      // Nose cone flowing back into side panels.
      m.loft([
        MeshBuilder.section(0.72, 0.9, 0.045, 0.05, p: 2.2, n: 18),
        MeshBuilder.section(0.68, 0.89, 0.11, 0.12, p: 2.4, n: 18),
        MeshBuilder.section(0.6, 0.87, 0.17, 0.17, p: 2.6, n: 18),
        MeshBuilder.section(0.47, 0.8, 0.23, 0.19, p: 2.8, n: 18),
        MeshBuilder.section(0.32, 0.7, 0.28, 0.2, p: 3, n: 18),
        MeshBuilder.section(0.18, 0.62, 0.25, 0.19, p: 3, n: 18),
        MeshBuilder.section(0.06, 0.56, 0.2, 0.175, p: 3, n: 18),
        MeshBuilder.section(0.0, 0.54, 0.14, 0.16, p: 3, n: 18),
      ]);
      m.bias = -0.05;
      // Side vents.
      m.mat(_black);
      for (final s in const [-1.0, 1.0]) {
        for (var i = 0; i < 3; i++) {
          final x = 0.3 + i * 0.05;
          m.box(x, 0.6, s * 0.195, x + 0.03, 0.72, s * 0.215);
        }
      }
      // Twin headlights with LED brows and flush indicators.
      for (final s in const [-1.0, 1.0]) {
        m.mat(_lens, Finish.light);
        m.hexa([
          V3(0.7, 0.855, s * 0.015), V3(0.655, 0.84, s * 0.125), //
          V3(0.655, 0.915, s * 0.125), V3(0.7, 0.925, s * 0.015),
          V3(0.715, 0.855, s * 0.015), V3(0.67, 0.84, s * 0.125),
          V3(0.67, 0.915, s * 0.125), V3(0.715, 0.925, s * 0.015),
        ]);
        m.mat(_drl, Finish.light);
        m.box(0.655, 0.925, s * 0.03, 0.69, 0.935, s * 0.11);
        m.mat(_amber, Finish.light);
        m.box(0.55, 0.88, s * 0.165, 0.6, 0.9, s * 0.18);
      }
      m.bias = 0;
      // Windscreen.
      m.mat(_glass, Finish.glass);
      m.slab(
        const V3(0.63, 0.99, -0.12),
        const V3(0.63, 0.99, 0.12),
        const V3(0.46, 1.21, -0.09),
        const V3(0.46, 1.21, 0.09),
        const V3(-0.008, 0, 0),
      );
    },
  );

  l.add(
    'belly_pan',
    'Belly Pan',
    PartGroup.body,
    const V3(0, -0.6, 0),
    'The belly pan tidies the airflow under the engine and guards it from stones.',
    ['fairing', 'exhaust'],
    (m) {
      m.paint();
      m.loft([
        MeshBuilder.section(-0.08, 0.2, 0.05, 0.11, p: 2.6),
        MeshBuilder.section(0.08, 0.2, 0.08, 0.16, p: 2.8),
        MeshBuilder.section(0.28, 0.27, 0.11, 0.18, p: 2.8),
        MeshBuilder.section(0.38, 0.38, 0.07, 0.14, p: 2.6),
      ]);
    },
  );

  return [...parts, ...l.parts];
}
