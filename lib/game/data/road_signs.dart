import 'dart:math' as math;
import 'dart:ui' show Color;

import '../engine/mesh.dart';
import '../engine/vec3.dart';
import 'part.dart';

// Roadside traffic signs shown while a finished vehicle is driving. Plates
// face +Z (towards the default camera) and stand on a grey pole.

const _pole = Color(0xFF9AA3AD);
const _red = Color(0xFFD32F2F);
const _white = Color(0xFFF5F5F5);
const _black = Color(0xFF1B1B1B);
const _blue = Color(0xFF1565C0);
const _yellow = Color(0xFFFFC107);

/// The kinds of sign, in the order they appear along the road.
enum RoadSignKind { speedLimit, warning, stop, keepLeft }

final _cache = <(RoadSignKind, int), List<Face>>{};

/// Sign mesh at scale [s] (the vehicle's ground scale), base at the origin.
List<Face> roadSign(RoadSignKind kind, double s) =>
    _cache.putIfAbsent((kind, (s * 100).round()), () => _build(kind, s));

List<Face> _build(RoadSignKind kind, double s) => buildMesh((m) {
  final h = 1.25 * s; // plate centre height
  final r = 0.24 * s; // plate radius
  final c = V3(0, h, 0);
  const t = 0.02;

  m.maxEdge = 0.2 * s;
  m.mat(_pole, Finish.metal);
  m.cylinder(
    V3(0, (h - r) / 2, -0.03 * s),
    0.028 * s,
    h - r,
    Axis3.y,
    segs: 10,
  );
  m.cylinder(V3(0, 0.02 * s, -0.03 * s), 0.07 * s, 0.04 * s, Axis3.y, segs: 12);

  switch (kind) {
    case RoadSignKind.speedLimit:
      m.mat(_red);
      m.cylinder(c, r, t * s, Axis3.z, segs: 28);
      m.bias = -0.02;
      m.mat(_white);
      m.cylinder(
        c + V3(0, 0, t * s * 0.6),
        r * 0.76,
        t * s * 0.3,
        Axis3.z,
        segs: 28,
      );
      // "40" as two chunky digits.
      m.bias = -0.04;
      m.mat(_black);
      final z0 = c.z + t * s * 1.0, z1 = z0 + 0.006 * s;
      final dh = r * 0.64, dw = r * 0.34, st = r * 0.12;
      // 4
      final x4 = c.x - r * 0.42;
      m.box(x4, h - st / 2, z0, x4 + dw, h + st / 2, z1);
      m.box(x4 + dw - st, h - dh / 2, z0, x4 + dw, h + dh / 2, z1);
      m.box(x4, h, z0, x4 + st, h + dh / 2, z1);
      // 0
      final x0 = c.x + r * 0.06;
      m.box(x0, h - dh / 2, z0, x0 + st, h + dh / 2, z1);
      m.box(x0 + dw - st, h - dh / 2, z0, x0 + dw, h + dh / 2, z1);
      m.box(x0, h + dh / 2 - st, z0, x0 + dw, h + dh / 2, z1);
      m.box(x0, h - dh / 2, z0, x0 + dw, h - dh / 2 + st, z1);
    case RoadSignKind.stop:
      m.mat(_red);
      // Octagon with flat top: rotate the 8 sides by 22.5°.
      final pts = [
        for (var i = 0; i < 8; i++)
          () {
            final a = math.pi / 8 + i * math.pi / 4;
            return (math.cos(a) * r * 1.05, math.sin(a) * r * 1.05);
          }(),
      ];
      m.polygon([
        for (final (x, y) in pts) V3(x, h + y, t * s),
      ], inside: c - V3(0, 0, 1));
      m.polygon([
        for (final (x, y) in pts) V3(x, h + y, 0),
      ], inside: c + V3(0, 0, 1));
      for (var i = 0; i < 8; i++) {
        final (ax, ay) = pts[i];
        final (bx, by) = pts[(i + 1) % 8];
        m.quad(
          V3(ax, h + ay, 0),
          V3(bx, h + by, 0),
          V3(bx, h + by, t * s),
          V3(ax, h + ay, t * s),
          inside: c + V3(0, 0, t * s / 2),
        );
      }
      // White "STOP" band.
      m.bias = -0.03;
      m.mat(_white);
      m.box(
        -r * 0.66,
        h - r * 0.16,
        t * s,
        r * 0.66,
        h + r * 0.16,
        t * s + 0.004 * s,
      );
    case RoadSignKind.warning:
      final a = V3(0, h + r * 1.05, 0),
          b = V3(-r * 1.1, h - r * 0.8, 0),
          d = V3(r * 1.1, h - r * 0.8, 0);
      final f = V3(0, 0, t * s);
      m.mat(_red);
      m.polygon([a + f, b + f, d + f], inside: c);
      m.polygon([a, d, b], inside: c + f * 2);
      m.quad(a, b, b + f, a + f, inside: c + f * 0.5);
      m.quad(b, d, d + f, b + f, inside: c + f * 0.5);
      m.quad(d, a, a + f, d + f, inside: c + f * 0.5);
      m.bias = -0.02;
      m.mat(_white);
      final k = 0.7;
      V3 inset(V3 p) => V3(
        p.x * k,
        h - r * 0.18 + (p.y - h + r * 0.18) * k,
        t * s + 0.003 * s,
      );
      m.polygon([inset(a), inset(b), inset(d)], inside: c);
      m.bias = -0.04;
      m.mat(_black);
      final z0 = t * s + 0.004 * s, z1 = z0 + 0.003 * s;
      m.box(-r * 0.07, h - r * 0.15, z0, r * 0.07, h + r * 0.5, z1);
      m.box(-r * 0.07, h - r * 0.42, z0, r * 0.07, h - r * 0.28, z1);
    case RoadSignKind.keepLeft:
      m.mat(_blue);
      m.cylinder(c, r, t * s, Axis3.z, segs: 28);
      m.bias = -0.03;
      m.mat(_white);
      final z0 = c.z + t * s * 0.5, z1 = z0 + 0.004 * s;
      // Arrow pointing down-left.
      final w = r * 0.14;
      for (var i = 0; i < 6; i++) {
        final u = -0.35 + i * 0.12;
        m.box(
          r * u - w / 2,
          h - r * u - w / 2,
          z0,
          r * u + w / 2,
          h - r * u + w / 2,
          z1,
        );
      }
      m.box(
        -r * 0.45,
        h - r * 0.45 - w / 2,
        z0,
        -r * 0.05,
        h - r * 0.45 + w / 2,
        z1,
      );
      m.box(
        -r * 0.45 - w / 2,
        h - r * 0.45,
        z0,
        -r * 0.45 + w / 2,
        h - r * 0.05,
        z1,
      );
  }
  m.bias = 0;
  // A small yellow reflector on the pole so it reads at a glance.
  m.mat(_yellow, Finish.light);
  m.box(-0.03 * s, 0.5 * s, 0.0, 0.03 * s, 0.56 * s, 0.006 * s);
});
