import 'dart:math' as math;
import 'dart:ui';

import 'mesh.dart';
import 'vec3.dart';

/// Orbit camera looking at [target] from [distance], rotated by [yaw]/[pitch].
class OrbitCamera {
  OrbitCamera({
    this.yaw = homeYaw,
    this.pitch = homePitch,
    this.zoom = 1,
    this.distance = 9,
    this.target = const V3(0, 0.75, 0),
  });

  static const homeYaw = 0.75;
  static const homePitch = 0.38;
  static const minPitch = 0.06;
  static const maxPitch = 1.4;

  double yaw, pitch, zoom, distance;
  V3 target;

  /// Focal length relative to the shortest side of the viewport.
  double lens = 1.75;

  /// Vertical position of [target] on screen (fraction of height).
  double anchorY = 0.52;

  double _cy = 1, _sy = 0, _cp = 1, _sp = 0, _f = 1, _ox = 0, _oy = 0;

  void prepare(Size size) {
    _cy = math.cos(yaw);
    _sy = math.sin(yaw);
    _cp = math.cos(pitch);
    _sp = math.sin(pitch);
    _f = size.shortestSide * lens * zoom;
    _ox = size.width / 2;
    _oy = size.height * anchorY;
  }

  V3 get position => target + V3(_cp * _sy, _sp, _cp * _cy) * distance;

  /// Screen x, screen y and depth (distance along the view axis).
  (double, double, double) project(V3 p) {
    final dx = p.x - target.x, dy = p.y - target.y, dz = p.z - target.z;
    final x1 = dx * _cy - dz * _sy;
    final z1 = dx * _sy + dz * _cy;
    final y2 = dy * _cp - z1 * _sp;
    final z2 = dy * _sp + z1 * _cp;
    final depth = distance - z2;
    final s = _f / depth;
    return (_ox + x1 * s, _oy - y2 * s, depth);
  }

  Offset toScreen(V3 p) {
    final (x, y, _) = project(p);
    return Offset(x, y);
  }

  /// Pixels per world unit at [p].
  double scaleAt(V3 p) {
    final (_, _, depth) = project(p);
    return _f / depth;
  }

  /// World point under screen position [s] at view [depth].
  V3 unproject(Offset s, double depth) {
    final k = _f / depth;
    final x1 = (s.dx - _ox) / k;
    final y2 = -(s.dy - _oy) / k;
    final z2 = distance - depth;
    final y1 = y2 * _cp + z2 * _sp;
    final z1 = -y2 * _sp + z2 * _cp;
    return target + V3(x1 * _cy + z1 * _sy, y1, -x1 * _sy + z1 * _cy);
  }

  /// Frames [b] so it fills most of a thumbnail.
  void fit(Bounds b) {
    target = b.center;
    distance = math.max(1.2, b.radius * 4.2);
    anchorY = 0.5;
  }
}

/// One mesh placed in the scene for a frame.
class RenderItem {
  const RenderItem(
    this.faces, {
    this.offset = V3.zero,
    this.spin = 0,
    this.pivot,
    this.alpha = 1,
    this.glow = 0,
    this.ghost = false,
    this.ghostColor,
  });

  final List<Face> faces;
  final V3 offset;

  /// Rotation around an axis parallel to Z through [pivot] (rolling wheels).
  final double spin;
  final V3? pivot;
  final double alpha;

  /// 0..1 flash towards white (snap / focus feedback).
  final double glow;

  /// Drawn as a translucent placement hint; not pickable.
  final bool ghost;
  final Color? ghostColor;
}

class SceneStyle {
  const SceneStyle({
    required this.paintColor,
    this.ground = true,
    this.shadow = true,
    this.roadScroll,
    this.ghostColor = const Color(0xFFFFA000),
    this.groundScale = 1,
    this.shadowSize = (2.35, 1.1),
    this.contacts = const [],
  });

  final Color paintColor;
  final bool ground, shadow;

  /// When non-null, animated road stripes are drawn (drive mode).
  final double? roadScroll;
  final Color ghostColor;

  /// Turntable size multiplier (smaller for bikes).
  final double groundScale;

  /// Shadow ellipse radii along X and Z.
  final (double, double) shadowSize;

  /// Tight contact shadows (ground point, radius X, radius Z) under wheels.
  final List<(V3, double, double)> contacts;
}

class _Poly {
  _Poly(this.depth, this.pts, this.colors, this.item);
  final double depth;
  final List<Offset> pts;
  final List<Color> colors;
  final int item;
}

/// Result of a frame, used to find which item is under a tap.
class ScenePick {
  ScenePick._(this._polys);
  final List<_Poly> _polys;

  /// Index into the rendered items of the front-most surface at [p].
  int? hit(Offset p) {
    for (var i = _polys.length - 1; i >= 0; i--) {
      final poly = _polys[i];
      if (poly.item >= 0 && _inside(poly.pts, p)) return poly.item;
    }
    return null;
  }

  static bool _inside(List<Offset> pts, Offset p) {
    var inside = false;
    for (var i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      final a = pts[i], b = pts[j];
      if ((a.dy > p.dy) != (b.dy > p.dy) &&
          p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
        inside = !inside;
      }
    }
    return inside;
  }
}

final V3 _key = const V3(0.45, 0.85, 0.35).normalized;
final V3 _fill = const V3(-0.6, 0.35, -0.5).normalized;

class _Mat {
  const _Mat(
    this.reflect,
    this.fresnel,
    this.shine,
    this.spec, {
    this.tint = false,
  });

  /// Base mirror reflectivity, extra reflectivity at grazing angles.
  final double reflect, fresnel;
  final double shine, spec;

  /// Reflections take the base colour (metals).
  final bool tint;
}

const _mats = {
  Finish.matte: _Mat(0.02, 0.06, 8, 0.05),
  Finish.paint: _Mat(0.08, 0.6, 70, 0.75),
  Finish.metal: _Mat(0.28, 0.3, 24, 0.4, tint: true),
  Finish.chrome: _Mat(0.82, 0.18, 50, 1.0, tint: true),
  Finish.rubber: _Mat(0.01, 0.1, 6, 0.05),
  Finish.glass: _Mat(0.3, 0.65, 90, 1.0),
  Finish.light: _Mat(0, 0, 1, 0),
};

/// Studio environment seen in reflections: bright sky, a softbox band,
/// dark floor.
(double, double, double) _env(V3 r) {
  final y = r.y;
  double er, eg, eb;
  if (y >= 0) {
    final k = math.pow(y, 0.6).toDouble();
    er = 0.5 + 0.38 * k;
    eg = 0.55 + 0.37 * k;
    eb = 0.63 + 0.35 * k;
  } else {
    final k = math.min(1.0, -y * 3);
    er = 0.5 - 0.36 * k;
    eg = 0.55 - 0.4 * k;
    eb = 0.63 - 0.45 * k;
  }
  final band = math.exp(-math.pow((y - 0.3) / 0.07, 2)) * 0.7;
  return (er + band, eg + band, eb + band);
}

Color _shade(Face f, V3 n, V3 view, RenderItem item, SceneStyle style) {
  if (item.ghost) {
    final k = 0.7 + 0.3 * math.max(0, n.dot(_key));
    final g = item.ghostColor ?? style.ghostColor;
    return Color.from(
      alpha: item.alpha,
      red: (g.r * k).clamp(0, 1),
      green: (g.g * k).clamp(0, 1),
      blue: (g.b * k).clamp(0, 1),
    );
  }

  final base = f.finish == Finish.paint ? style.paintColor : f.color;
  double r = base.r, g = base.g, b = base.b;
  var alpha = item.alpha;

  if (f.finish != Finish.light) {
    final m = _mats[f.finish]!;
    final nv = math.max(0.0, n.dot(view));
    final diff =
        0.3 +
        0.12 * n.y +
        0.62 * math.max(0.0, n.dot(_key)) +
        0.18 * math.max(0.0, n.dot(_fill));
    final fres = (m.reflect + m.fresnel * math.pow(1 - nv, 4)).clamp(0.0, 1.0);
    final refl = n * (2 * n.dot(view)) - view;
    final (er, eg, eb) = _env(refl);
    final h = (_key + view).normalized;
    final spec = math.pow(math.max(0.0, n.dot(h)), m.shine).toDouble() * m.spec;
    final tr = m.tint ? r : 1.0, tg = m.tint ? g : 1.0, tb = m.tint ? b : 1.0;
    r = r * diff * (1 - fres) + er * tr * fres + spec;
    g = g * diff * (1 - fres) + eg * tg * fres + spec;
    b = b * diff * (1 - fres) + eb * tb * fres + spec;
    if (f.finish == Finish.glass) alpha *= 0.3 + fres * 0.6 + spec * 0.3;
  }

  if (item.glow > 0) {
    final t = item.glow * 0.55;
    r += (1 - r) * t;
    g += (1 - g) * t;
    b += (1 - b) * t;
  }
  return Color.from(
    alpha: alpha.clamp(0.0, 1.0),
    red: r.clamp(0.0, 1.0),
    green: g.clamp(0.0, 1.0),
    blue: b.clamp(0.0, 1.0),
  );
}

ScenePick drawScene(
  Canvas canvas,
  Size size,
  OrbitCamera cam,
  List<RenderItem> items,
  SceneStyle style,
) {
  cam.prepare(size);
  if (style.ground) _drawGround(canvas, cam, style);

  final camPos = cam.position;
  final polys = <_Poly>[];

  for (var idx = 0; idx < items.length; idx++) {
    final item = items[idx];
    final pivot = item.pivot;
    final spin = pivot != null && item.spin != 0;
    final cs = math.cos(item.spin), sn = math.sin(item.spin);
    final off = item.offset;
    V3 turn(V3 v) => V3(v.x * cs - v.y * sn, v.x * sn + v.y * cs, v.z);

    for (final f in item.faces) {
      final n = f.pts.length;
      final pts = List<V3>.generate(n, (i) {
        final p = f.pts[i];
        if (!spin) return p + off;
        return pivot + turn(p - pivot) + off;
      }, growable: false);

      final normal = polygonNormal(pts);
      if (normal.length == 0) continue;
      var center = pts[0];
      for (var i = 1; i < n; i++) {
        center = center + pts[i];
      }
      center = center * (1 / n);
      if (normal.dot(camPos - center) <= 0) continue;

      final screen = <Offset>[];
      var depth = 0.0;
      var behind = false;
      for (final p in pts) {
        final (sx, sy, d) = cam.project(p);
        if (d < 0.1) behind = true;
        depth += d;
        screen.add(Offset(sx, sy));
      }
      if (behind) continue;

      final vn = f.normals;
      final colors = List<Color>.generate(n, (i) {
        var nrm = vn == null ? normal : vn[i];
        if (spin && vn != null) nrm = turn(nrm);
        return _shade(f, nrm, (camPos - pts[i]).normalized, item, style);
      }, growable: false);
      if (colors[0].a <= 0.01) continue;
      polys.add(
        _Poly(depth / n + f.bias, screen, colors, item.ghost ? -1 : idx),
      );
    }
  }

  polys.sort((a, b) => b.depth.compareTo(a.depth));
  if (polys.isNotEmpty) {
    final positions = <Offset>[];
    final colors = <Color>[];
    for (final p in polys) {
      final s = p.pts, c = p.colors;
      for (var i = 1; i < s.length - 1; i++) {
        positions
          ..add(s[0])
          ..add(s[i])
          ..add(s[i + 1]);
        colors
          ..add(c[0])
          ..add(c[i])
          ..add(c[i + 1]);
      }
    }
    canvas.drawVertices(
      Vertices(VertexMode.triangles, positions, colors: colors),
      BlendMode.dst,
      Paint(),
    );
  }
  return ScenePick._(polys);
}

Path _ellipsePath(OrbitCamera cam, V3 c, double rx, double rz) {
  final path = Path();
  const segs = 48;
  for (var i = 0; i <= segs; i++) {
    final a = i / segs * math.pi * 2;
    final o = cam.toScreen(
      V3(c.x + math.cos(a) * rx, c.y, c.z + math.sin(a) * rz),
    );
    i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
  }
  return path..close();
}

void _drawGround(Canvas canvas, OrbitCamera cam, SceneStyle style) {
  final s = style.groundScale;
  final r = 3.4 * s;
  // Turntable pedestal with a soft radial gradient top.
  canvas.drawPath(
    _ellipsePath(cam, V3(0, -0.16 * s, 0), r, r),
    Paint()..color = const Color(0xFF12151A),
  );
  final top = _ellipsePath(cam, V3.zero, r, r);
  final c = cam.toScreen(V3.zero);
  final edge = cam.toScreen(V3(r, 0, 0));
  canvas.drawPath(
    top,
    Paint()
      ..shader = Gradient.radial(
        c,
        math.max(1, (edge - c).distance * 1.1),
        const [Color(0xFF3A414C), Color(0xFF262B33)],
      ),
  );
  canvas.drawPath(
    top,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFA000).withValues(alpha: 0.55),
  );

  final line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0x1FFFFFFF);
  canvas.drawPath(_ellipsePath(cam, V3.zero, r * 0.72, r * 0.72), line);
  for (var i = 0; i < 12; i++) {
    final a = i / 12 * math.pi * 2;
    canvas.drawLine(
      cam.toScreen(V3(math.cos(a) * r * 0.72, 0, math.sin(a) * r * 0.72)),
      cam.toScreen(V3(math.cos(a) * r, 0, math.sin(a) * r)),
      line,
    );
  }

  final scroll = style.roadScroll;
  if (scroll != null) {
    final dash = Paint()..color = const Color(0xCCFFFFFF);
    final len = 0.45 * s, period = 0.9 * s, w = 0.05 * s;
    for (final z in [-1.35 * s, 1.35 * s]) {
      final lim = math.sqrt(r * r - z * z) - 0.05;
      final phase = scroll % period;
      for (var x = -lim - period + phase; x < lim; x += period) {
        final a = math.max(-lim, x), b = math.min(lim, x + len);
        if (b <= a) continue;
        final p = [
          V3(a, 0.002, z - w),
          V3(b, 0.002, z - w),
          V3(b, 0.002, z + w),
          V3(a, 0.002, z + w),
        ].map(cam.toScreen).toList();
        canvas.drawPath(Path()..addPolygon(p, true), dash);
      }
    }
  }

  if (style.shadow) {
    canvas.drawPath(
      _ellipsePath(
        cam,
        const V3(0, 0.003, 0),
        style.shadowSize.$1,
        style.shadowSize.$2,
      ),
      Paint()
        ..color = const Color(0x80000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    final contact = Paint()
      ..color = const Color(0xB0000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    for (final (p, rx, rz) in style.contacts) {
      canvas.drawPath(_ellipsePath(cam, p, rx, rz), contact);
    }
  }
}
