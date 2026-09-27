import 'dart:math' as math;
import 'dart:ui' show Color;

import 'vec3.dart';

/// Surface type; drives how a face is lit.
enum Finish { matte, paint, metal, chrome, rubber, glass, light }

enum Axis3 { x, y, z }

/// A flat convex polygon, counter-clockwise seen from outside.
class Face {
  const Face(this.pts, this.color, this.finish, [this.bias = 0, this.normals]);

  final List<V3> pts;

  /// Ignored for [Finish.paint]; the car's current paint colour is used.
  final Color color;
  final Finish finish;

  /// Added to the sort depth; negative values draw the face later (on top).
  final double bias;

  /// Per-vertex normals for smooth shading (see [smoothFaces]).
  final List<V3>? normals;
}

/// Unit normal of a planar polygon (Newell's method).
V3 polygonNormal(List<V3> pts) {
  var x = 0.0, y = 0.0, z = 0.0;
  for (var i = 0; i < pts.length; i++) {
    final a = pts[i], b = pts[(i + 1) % pts.length];
    x += (a.y - b.y) * (a.z + b.z);
    y += (a.z - b.z) * (a.x + b.x);
    z += (a.x - b.x) * (a.y + b.y);
  }
  return V3(x, y, z).normalized;
}

/// Adds per-vertex normals so curved surfaces (tyres, tubes, arches) shade
/// smoothly. Normals are averaged over neighbouring faces of the same
/// material whose angle is below [creaseDeg]; sharper edges stay crisp.
List<Face> smoothFaces(List<Face> faces, {double creaseDeg = 42}) {
  final cosCrease = math.cos(creaseDeg * math.pi / 180);
  final normals = [for (final f in faces) polygonNormal(f.pts)];
  int key(V3 p) => Object.hash(
    (p.x * 2e3).round(),
    (p.y * 2e3).round(),
    (p.z * 2e3).round(),
  );
  final byVertex = <int, List<int>>{};
  for (var i = 0; i < faces.length; i++) {
    for (final p in faces[i].pts) {
      (byVertex[key(p)] ??= []).add(i);
    }
  }
  return [
    for (var i = 0; i < faces.length; i++)
      Face(faces[i].pts, faces[i].color, faces[i].finish, faces[i].bias, [
        for (final p in faces[i].pts)
          () {
            final n0 = normals[i];
            var sum = V3.zero;
            for (final j in byVertex[key(p)]!) {
              if (faces[j].finish == faces[i].finish &&
                  faces[j].color == faces[i].color &&
                  normals[j].dot(n0) >= cosCrease) {
                sum = sum + normals[j];
              }
            }
            return sum.length == 0 ? n0 : sum.normalized;
          }(),
      ]),
  ];
}

/// Builds low-poly geometry from simple convex primitives.
///
/// Every primitive fixes its own winding (faces point away from the
/// primitive's centre), and large quads are split so the painter's-algorithm
/// depth sort stays accurate.
class MeshBuilder {
  MeshBuilder({this.maxEdge = 0.4});

  /// Largest quad edge before splitting; lower it under small attached
  /// details so they depth-sort correctly.
  double maxEdge;
  final List<Face> faces = [];

  /// Depth bias for following faces (see [Face.bias]).
  double bias = 0;

  Color _color = const Color(0xFF888888);
  Finish _finish = Finish.matte;

  /// Sets the material used by the following primitives.
  void mat(Color color, [Finish finish = Finish.matte]) {
    _color = color;
    _finish = finish;
  }

  void paint() => mat(const Color(0xFF000000), Finish.paint);

  void quad(V3 a, V3 b, V3 c, V3 d, {V3? inside}) {
    if (inside != null) {
      final n = (c - a).cross(d - b);
      final mid = (a + b + c + d) * 0.25;
      if (n.dot(mid - inside) < 0) {
        final t = b;
        b = d;
        d = t;
      }
    }
    final nu = math.max(
      1,
      (math.max((b - a).length, (c - d).length) / maxEdge).ceil(),
    );
    final nv = math.max(
      1,
      (math.max((d - a).length, (c - b).length) / maxEdge).ceil(),
    );
    if (nu == 1 && nv == 1) {
      faces.add(Face([a, b, c, d], _color, _finish, bias));
      return;
    }
    V3 at(int i, int j) =>
        V3.lerp(V3.lerp(a, b, i / nu), V3.lerp(d, c, i / nu), j / nv);
    for (var i = 0; i < nu; i++) {
      for (var j = 0; j < nv; j++) {
        faces.add(
          Face(
            [at(i, j), at(i + 1, j), at(i + 1, j + 1), at(i, j + 1)],
            _color,
            _finish,
            bias,
          ),
        );
      }
    }
  }

  void tri(V3 a, V3 b, V3 c, {V3? inside}) {
    if (inside != null) {
      final n = (b - a).cross(c - a);
      final mid = (a + b + c) * (1 / 3);
      if (n.dot(mid - inside) < 0) {
        final t = b;
        b = c;
        c = t;
      }
    }
    faces.add(Face([a, b, c], _color, _finish, bias));
  }

  /// Convex planar polygon, drawn without subdivision.
  void polygon(List<V3> pts, {V3? inside}) {
    if (inside != null) {
      final n = polygonNormal(pts);
      var mid = V3.zero;
      for (final q in pts) {
        mid = mid + q;
      }
      mid = mid * (1 / pts.length);
      if (n.dot(mid - inside) < 0) pts = pts.reversed.toList();
    }
    faces.add(Face(pts, _color, _finish, bias));
  }

  // Corner order matches an axis-aligned box:
  // 0:(-x,-y,-z) 1:(+x,-y,-z) 2:(+x,+y,-z) 3:(-x,+y,-z), 4..7 same at +z.
  // Face index: 0:+z 1:-z 2:+x 3:-x 4:+y 5:-y
  static const _hexFaces = [
    [4, 5, 6, 7],
    [1, 0, 3, 2],
    [5, 1, 2, 6],
    [0, 4, 7, 3],
    [7, 6, 2, 3],
    [0, 1, 5, 4],
  ];

  /// A six-sided convex solid from 8 corners (see corner order above).
  void hexa(List<V3> c, {Set<int> skip = const {}}) {
    var center = V3.zero;
    for (final p in c) {
      center = center + p;
    }
    center = center * (1 / 8);
    for (var i = 0; i < 6; i++) {
      if (skip.contains(i)) continue;
      final f = _hexFaces[i];
      quad(c[f[0]], c[f[1]], c[f[2]], c[f[3]], inside: center);
    }
  }

  void box(
    double x0,
    double y0,
    double z0,
    double x1,
    double y1,
    double z1, {
    Set<int> skip = const {},
  }) {
    hexa([
      V3(x0, y0, z0), V3(x1, y0, z0), V3(x1, y1, z0), V3(x0, y1, z0), //
      V3(x0, y0, z1), V3(x1, y0, z1), V3(x1, y1, z1), V3(x0, y1, z1),
    ], skip: skip);
  }

  /// A thin plate spanning bottom edge [a0]→[a1] and top edge [b0]→[b1],
  /// extruded by [thick].
  void slab(V3 a0, V3 a1, V3 b0, V3 b1, V3 thick) {
    hexa([a0, a1, b1, b0, a0 + thick, a1 + thick, b1 + thick, b0 + thick]);
  }

  /// Side panel whose lower/upper edges follow [bottom]/[top] along X,
  /// extruded between [z0] and [z1].
  void profile(
    List<double> xs,
    double Function(double) bottom,
    double Function(double) top,
    double z0,
    double z1,
  ) {
    for (var i = 0; i < xs.length - 1; i++) {
      final a = xs[i], b = xs[i + 1];
      final skip = <int>{if (i > 0) 3, if (i < xs.length - 2) 2};
      hexa([
        V3(a, bottom(a), z0), V3(b, bottom(b), z0), //
        V3(b, top(b), z0), V3(a, top(a), z0),
        V3(a, bottom(a), z1), V3(b, bottom(b), z1),
        V3(b, top(b), z1), V3(a, top(a), z1),
      ], skip: skip);
    }
  }

  static V3 _onAxis(V3 c, Axis3 axis, double u, double v, double h) {
    switch (axis) {
      case Axis3.x:
        return V3(c.x + h, c.y + u, c.z + v);
      case Axis3.y:
        return V3(c.x + u, c.y + h, c.z + v);
      case Axis3.z:
        return V3(c.x + u, c.y + v, c.z + h);
    }
  }

  /// Cylinder (or cone when [topRadius] differs) centred on [c].
  void cylinder(
    V3 c,
    double radius,
    double length,
    Axis3 axis, {
    int segs = 16,
    double? topRadius,
    Color? capColor,
    Finish? capFinish,
  }) {
    final h = length / 2;
    final rt = topRadius ?? radius;
    V3 p(int i, double hh, double r) {
      final a = i / segs * math.pi * 2;
      return _onAxis(c, axis, math.cos(a) * r, math.sin(a) * r, hh);
    }

    for (var i = 0; i < segs; i++) {
      quad(
        p(i, -h, radius),
        p(i + 1, -h, radius),
        p(i + 1, h, rt),
        p(i, h, rt),
        inside: c,
      );
    }
    final sideColor = _color, sideFinish = _finish;
    if (capColor != null) mat(capColor, capFinish ?? _finish);
    // Each cap is one polygon so it depth-sorts as a single piece.
    polygon([for (var i = 0; i < segs; i++) p(i, h, rt)], inside: c);
    polygon([for (var i = 0; i < segs; i++) p(i, -h, radius)], inside: c);
    mat(sideColor, sideFinish);
  }

  /// Curved band between radii [r0]..[r1] from angle [a0] to [a1],
  /// spanning [h0]..[h1] along [axis] (mudguards, tyres).
  void arc(
    V3 c,
    double r0,
    double r1,
    double a0,
    double a1,
    double h0,
    double h1,
    Axis3 axis, {
    int segs = 16,
  }) {
    V3 p(int i, double r, double h) {
      final a = a0 + (a1 - a0) * i / segs;
      return _onAxis(c, axis, math.cos(a) * r, math.sin(a) * r, h);
    }

    final full = (a1 - a0).abs() >= math.pi * 2 - 1e-6;
    for (var i = 0; i < segs; i++) {
      hexa(
        [
          p(i, r0, h0),
          p(i + 1, r0, h0),
          p(i + 1, r1, h0),
          p(i, r1, h0),
          p(i, r0, h1),
          p(i + 1, r0, h1),
          p(i + 1, r1, h1),
          p(i, r1, h1),
        ],
        skip: {if (full || i > 0) 3, if (full || i < segs - 1) 2},
      );
    }
  }

  /// Square-section ring around [axis] (steering wheel, tyres).
  void ring(V3 c, double radius, double tube, Axis3 axis, {int segs = 20}) =>
      arc(
        c,
        radius - tube,
        radius + tube,
        0,
        math.pi * 2,
        -tube,
        tube,
        axis,
        segs: segs,
      );

  /// Round tube from [a] to [b] (bike frames, forks, exhaust pipes).
  void rod(V3 a, V3 b, double r, {int segs = 8, double? endRadius}) {
    final d = (b - a).normalized;
    final helper = d.y.abs() < 0.9 ? const V3(0, 1, 0) : const V3(1, 0, 0);
    final u = d.cross(helper).normalized, v = d.cross(u);
    final r1 = endRadius ?? r;
    V3 p(V3 c, int i, double rr) {
      final t = i / segs * math.pi * 2;
      return c + u * (math.cos(t) * rr) + v * (math.sin(t) * rr);
    }

    final center = (a + b) * 0.5;
    for (var i = 0; i < segs; i++) {
      quad(
        p(a, i, r),
        p(a, i + 1, r),
        p(b, i + 1, r1),
        p(b, i, r1),
        inside: center,
      );
    }
    polygon([for (var i = 0; i < segs; i++) p(b, i, r1)], inside: center);
    polygon([for (var i = 0; i < segs; i++) p(a, i, r)], inside: center);
  }

  /// Rounded cross-section in the YZ plane at [x] (superellipse: [p] = 2 is
  /// an ellipse, larger values are boxier). Used as a [loft] section.
  static List<V3> section(
    double x,
    double cy,
    double ry,
    double rz, {
    double cz = 0,
    double p = 2.4,
    int n = 18,
  }) {
    double f(double v) => v.sign * math.pow(v.abs(), 2 / p).toDouble();
    return [
      for (var i = 0; i < n; i++)
        () {
          final a = i / n * math.pi * 2;
          return V3(x, cy + f(math.sin(a)) * ry, cz + f(math.cos(a)) * rz);
        }(),
    ];
  }

  /// Smooth skin through a series of cross-sections with equal point counts
  /// (fuel tanks, seats, headlight shells). Ends are capped.
  void loft(List<List<V3>> sections, {bool caps = true}) {
    V3 centroid(List<V3> s) {
      var c = V3.zero;
      for (final p in s) {
        c = c + p;
      }
      return c * (1 / s.length);
    }

    final centers = [for (final s in sections) centroid(s)];
    for (var i = 0; i < sections.length - 1; i++) {
      final a = sections[i], b = sections[i + 1];
      final inside = (centers[i] + centers[i + 1]) * 0.5;
      for (var j = 0; j < a.length; j++) {
        final k = (j + 1) % a.length;
        quad(a[j], a[k], b[k], b[j], inside: inside);
      }
    }
    if (caps) {
      polygon(sections.first, inside: centers[1]);
      polygon(sections.last, inside: centers[centers.length - 2]);
    }
  }

  /// Smooth body through [centers] with elliptical cross-sections
  /// ([radii] = depth, width); width runs along [side] (torsos).
  void tube(
    List<V3> centers,
    List<(double, double)> radii, {
    V3 side = const V3(0, 0, 1),
    int n = 16,
  }) {
    final sections = <List<V3>>[];
    for (var i = 0; i < centers.length; i++) {
      final a = centers[i == 0 ? 0 : i - 1];
      final b = centers[i == centers.length - 1 ? i : i + 1];
      final t = (b - a).normalized;
      final w = (side - t * side.dot(t)).normalized;
      final u = w.cross(t);
      final (ru, rw) = radii[i];
      sections.add([
        for (var k = 0; k < n; k++)
          centers[i] +
              u * (math.cos(k / n * math.pi * 2) * ru) +
              w * (math.sin(k / n * math.pi * 2) * rw),
      ]);
    }
    loft(sections);
  }

  /// Sphere (heads, hands, joints). [from]..[to] (0..1, back to front along
  /// X) keeps only part of it; [yScale] squashes it vertically (visors).
  void sphere(
    V3 c,
    double r, {
    int rings = 8,
    int segs = 14,
    double from = 0.06,
    double to = 0.94,
    double yScale = 1,
  }) {
    loft([
      for (var i = 0; i <= rings; i++)
        () {
          final a = (from + (to - from) * i / rings) * math.pi;
          return section(
            c.x - math.cos(a) * r,
            c.y,
            math.sin(a) * r * yScale,
            math.sin(a) * r,
            cz: c.z,
            p: 2,
            n: segs,
          );
        }(),
    ]);
  }

  /// Doughnut with a round cross-section around [axis] (tyres).
  void torus(
    V3 c,
    double radius,
    double tube,
    Axis3 axis, {
    int major = 30,
    int minor = 10,
  }) {
    V3 p(int i, int j) {
      final u = i / major * math.pi * 2, v = j / minor * math.pi * 2;
      final r = radius + tube * math.cos(v);
      return _onAxis(
        c,
        axis,
        math.cos(u) * r,
        math.sin(u) * r,
        tube * math.sin(v),
      );
    }

    for (var i = 0; i < major; i++) {
      final um = (i + 0.5) / major * math.pi * 2;
      final core = _onAxis(
        c,
        axis,
        math.cos(um) * radius,
        math.sin(um) * radius,
        0,
      );
      for (var j = 0; j < minor; j++) {
        quad(p(i, j), p(i + 1, j), p(i + 1, j + 1), p(i, j + 1), inside: core);
      }
    }
  }

  /// Coil spring of [turns] around the line [a]→[b].
  void helix(
    V3 a,
    V3 b,
    double radius,
    double turns,
    double wire, {
    int perTurn = 10,
  }) {
    final axis = b - a;
    final d = axis.normalized;
    final helper = d.y.abs() < 0.9 ? const V3(0, 1, 0) : const V3(1, 0, 0);
    final u = d.cross(helper).normalized, v = d.cross(u);
    final steps = (turns * perTurn).round();
    V3 at(int i) {
      final t = i / steps, ang = t * turns * math.pi * 2;
      return a +
          axis * t +
          u * (math.cos(ang) * radius) +
          v * (math.sin(ang) * radius);
    }

    for (var i = 0; i < steps; i++) {
      rod(at(i), at(i + 1), wire, segs: 5);
    }
  }

  /// Rods joining consecutive [points].
  void rods(List<V3> points, double r, {int segs = 8}) {
    for (var i = 0; i < points.length - 1; i++) {
      rod(points[i], points[i + 1], r, segs: segs);
    }
  }

  /// A flat bar in the plane z = [z0]..[z1] rotated by [angle] around [c]
  /// (wheel spokes).
  void spokeZ(
    V3 c,
    double angle,
    double r0,
    double r1,
    double halfWidth,
    double z0,
    double z1,
  ) {
    final ca = math.cos(angle), sa = math.sin(angle);
    V3 p(double r, double w, double z) =>
        V3(c.x + ca * r - sa * w, c.y + sa * r + ca * w, z);
    hexa([
      p(r0, -halfWidth, z0),
      p(r1, -halfWidth, z0),
      p(r1, halfWidth, z0),
      p(r0, halfWidth, z0),
      p(r0, -halfWidth, z1),
      p(r1, -halfWidth, z1),
      p(r1, halfWidth, z1),
      p(r0, halfWidth, z1),
    ]);
  }

  /// Evenly spaced samples from [a] to [b] inclusive, roughly [step] apart.
  static List<double> steps(double a, double b, double step) {
    final n = math.max(1, ((b - a).abs() / step).ceil());
    return [for (var i = 0; i <= n; i++) a + (b - a) * i / n];
  }
}
