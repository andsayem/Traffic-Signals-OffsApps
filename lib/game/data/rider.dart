import 'dart:math' as math;
import 'dart:ui' show Color;

import '../engine/mesh.dart';
import '../engine/vec3.dart';

const _skin = Color(0xFFC68C5C);
const _hair = Color(0xFF1B1B1B);

/// Clothes and gear for a rider.
class RiderLook {
  const RiderLook({
    required this.top,
    required this.pants,
    required this.shoes,
    this.helmet = false,
    this.helmetColor,
    this.gloves = false,
    this.shorts = false,
  });

  final Color top, pants, shoes;
  final bool helmet;

  /// Null paints the helmet in the vehicle's colour.
  final Color? helmetColor;
  final bool gloves;
  final bool shorts;
}

/// Crank the rider's feet follow (bicycles).
class Pedals {
  const Pedals({
    required this.center,
    required this.crank,
    required this.footZ,
    required this.spinRatio,
  });

  final V3 center;
  final double crank, footZ;

  /// Crank turns relative to the wheels (matches the crankset part).
  final double spinRatio;
}

/// Where a seated rider's joints are. Body points use z as the body centre
/// line; limb points give the right side, with z measured from [hip].z and
/// mirrored for the left.
class RiderPose {
  const RiderPose({
    required this.look,
    required this.hip,
    required this.shoulders,
    required this.head,
    required this.elbow,
    required this.hand,
    this.knee,
    this.foot,
    this.pedals,
    this.hipWidth = 0.1,
    this.shoulderWidth = 0.19,
    this.thigh = 0.46,
    this.shin = 0.46,
  });

  final RiderLook look;
  final V3 hip, shoulders, head;
  final V3 elbow, hand;
  final V3? knee, foot;
  final Pedals? pedals;
  final double hipWidth, shoulderWidth, thigh, shin;

  V3 side(V3 p, double s) => V3(p.x, p.y, hip.z + s * p.z);
}

/// Torso, head and arms (everything except the legs).
List<Face> buildRiderUpper(RiderPose p) {
  final m = MeshBuilder(maxEdge: 0.12);
  final look = p.look;
  final up = (p.shoulders - p.hip).normalized;

  // Pelvis and torso.
  m.mat(look.pants);
  m.rod(
    p.hip + const V3(0, 0, -1) * p.hipWidth,
    p.hip + const V3(0, 0, 1) * p.hipWidth,
    0.085,
    segs: 12,
  );
  m.mat(look.top);
  final waist = V3.lerp(p.hip, p.shoulders, 0.3);
  final chest = V3.lerp(p.hip, p.shoulders, 0.72);
  m.tube(
    [p.hip + up * 0.02, waist, chest, p.shoulders, p.shoulders + up * 0.05],
    const [
      (0.1, 0.15),
      (0.095, 0.155),
      (0.11, 0.18),
      (0.09, 0.18),
      (0.05, 0.1),
    ],
  );

  // Neck and head.
  m.mat(_skin);
  m.rod(p.shoulders, p.head, 0.045, segs: 10);
  m.sphere(p.head, 0.095);
  if (look.helmet) {
    final full = look.helmetColor == null; // motorbike: full-face helmet
    if (full) {
      m.paint();
    } else {
      m.mat(look.helmetColor!, Finish.metal);
    }
    m.sphere(
      p.head + const V3(-0.01, 0.025, 0),
      full ? 0.128 : 0.118,
      yScale: full ? 1 : 0.85,
    );
    if (full) {
      // Tinted visor wrapping the front of the helmet.
      m.mat(const Color(0xFF34495E), Finish.chrome);
      m.sphere(
        p.head + const V3(-0.01, 0.01, 0),
        0.131,
        from: 0.64,
        to: 0.95,
        yScale: 0.42,
      );
    }
  } else {
    m.mat(_hair);
    m.sphere(p.head + const V3(-0.015, 0.03, 0), 0.093);
  }

  // Arms.
  for (final s in const [-1.0, 1.0]) {
    final sh = p.shoulders + V3(0, -0.02, s * p.shoulderWidth);
    final el = p.side(p.elbow, s), ha = p.side(p.hand, s);
    m.mat(look.top);
    m.sphere(sh, 0.052, rings: 6, segs: 10);
    m.rod(sh, el, 0.046, endRadius: 0.04, segs: 10);
    m.sphere(el, 0.04, rings: 5, segs: 10);
    m.rod(el, ha, 0.038, endRadius: 0.033, segs: 10);
    m.mat(look.gloves ? const Color(0xFF212121) : _skin);
    m.sphere(ha, 0.037, rings: 5, segs: 10);
  }
  return smoothFaces(m.faces);
}

/// Legs, either fixed (from [RiderPose.knee]/[RiderPose.foot]) or following
/// the pedals at crank rotation [spin] (radians, same sign as the renderer).
List<Face> buildRiderLegs(RiderPose p, {double spin = 0}) {
  final m = MeshBuilder(maxEdge: 0.12);
  for (final s in const [-1.0, 1.0]) {
    final hip = p.hip + V3(0, 0, s * p.hipWidth);
    late V3 knee, foot;
    final pedals = p.pedals;
    if (pedals != null) {
      // Pedal position on the rotating crank, foot resting on top.
      final a = spin;
      final dy = s * pedals.crank;
      foot = V3(
        pedals.center.x - dy * math.sin(a),
        pedals.center.y + dy * math.cos(a) + 0.035,
        p.hip.z + s * pedals.footZ,
      );
      knee = _solveKnee(hip, foot, p.thigh, p.shin);
    } else {
      knee = p.side(p.knee!, s);
      foot = p.side(p.foot!, s);
    }
    m.mat(p.look.pants);
    m.rod(hip, knee, 0.064, endRadius: 0.05, segs: 12);
    m.sphere(knee, 0.05, rings: 5, segs: 10);
    if (p.look.shorts) {
      final mid = V3.lerp(knee, foot, 0.12);
      m.mat(_skin);
      m.rod(mid, foot, 0.048, endRadius: 0.038, segs: 10);
    } else {
      m.rod(knee, foot, 0.049, endRadius: 0.042, segs: 10);
    }
    m.mat(p.look.shoes);
    m.rod(
      foot + const V3(-0.05, 0, 0),
      foot + const V3(0.09, -0.01, 0),
      0.04,
      endRadius: 0.034,
      segs: 10,
    );
  }
  return smoothFaces(m.faces);
}

/// Two-bone leg: knee position bending forward (+X).
V3 _solveKnee(V3 hip, V3 foot, double l1, double l2) {
  final flat = V3(foot.x - hip.x, foot.y - hip.y, 0);
  final d = math.min(flat.length, l1 + l2 - 0.005);
  final dir = flat.normalized;
  final a = (l1 * l1 - l2 * l2 + d * d) / (2 * d);
  final h = math.sqrt(math.max(0, l1 * l1 - a * a));
  var perp = V3(-dir.y, dir.x, 0);
  if (perp.x < 0) perp = -perp;
  final k = hip + dir * a + perp * h;
  return V3(k.x, k.y, hip.z + (foot.z - hip.z) * 0.5);
}
