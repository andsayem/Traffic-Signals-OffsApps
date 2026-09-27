import 'dart:math' as math;
import 'dart:ui' show Color;

import '../engine/mesh.dart';
import '../engine/vec3.dart';
import 'part.dart';

// ---------------------------------------------------------------------------
// A parametric modern car: curved body sides with a shoulder line, crowned
// hood and trunk, a greenhouse that leans inwards (tumblehome), raked glass
// and detailed alloy wheels. Every model built from it shares the same part
// ids as the original sedan, so levels, hints and translations keep working.
// ---------------------------------------------------------------------------

const _chassis = Color(0xFF2A2E35);
const _frame = Color(0xFF3B4048);
const _metal = Color(0xFF8C939C);
const _darkMetal = Color(0xFF4A5059);
const _chrome = Color(0xFFD5DAE0);
const _alloy = Color(0xFFB9C0C8);
const _tire = Color(0xFF17181B);
const _engineRed = Color(0xFFC62828);
const _leather = Color(0xFF3A2C26);
const _leatherLight = Color(0xFF55403A);
const _glass = Color(0xFF6FA8CF);
const _trim = Color(0xFF1C1F23);
const _plastic = Color(0xFF26292E);
const _headlight = Color(0xFFF4F8FF);
const _drl = Color(0xFFE3F2FD);
const _taillight = Color(0xFFD50000);
const _amber = Color(0xFFFFA726);
const _plate = Color(0xFFF1F1F1);
const _gauge = Color(0xFF80DEEA);
const _caliper = Color(0xFFD32F2F);

/// Proportions of one car model. Units are metres-ish; +X is the nose.
class CarSpec {
  const CarSpec({
    required this.wheelX,
    required this.wheelR,
    required this.halfW,
    required this.noseX,
    required this.tailX,
    required this.lift,
    required this.belt,
    required this.hoodNose,
    required this.trunkTop,
    required this.cabinFront,
    required this.cabinRear,
    required this.roofFront,
    required this.roofRear,
    required this.roofY,
    this.hatch = false,
    this.roofRails = false,
    this.cladding = false,
  });

  final double wheelX, wheelR, halfW, noseX, tailX;

  /// Extra ride height (SUVs sit higher).
  final double lift;

  /// Shoulder (belt) line height along the doors.
  final double belt;
  final double hoodNose, trunkTop;

  /// Where the windscreen / rear glass meet the body.
  final double cabinFront, cabinRear;

  /// Where the glass meets the roof.
  final double roofFront, roofRear, roofY;

  /// Near-vertical tailgate instead of a saloon boot.
  final bool hatch;
  final bool roofRails;

  /// Black plastic arch and sill trim (SUV look).
  final bool cladding;

  double get wheelY => wheelR + lift * 0.4;
  double get wheelZ => halfW - 0.15;
  double get sillY => 0.34 + lift;
  double get floorY => 0.3 + lift;
}

const sedanSpec = CarSpec(
  wheelX: 1.38,
  wheelR: 0.36,
  halfW: 0.92,
  noseX: 2.3,
  tailX: -2.28,
  lift: 0,
  belt: 0.96,
  hoodNose: 0.78,
  trunkTop: 0.95,
  cabinFront: 1.0,
  cabinRear: -1.5,
  roofFront: 0.18,
  roofRear: -0.8,
  roofY: 1.5,
);

const suvSpec = CarSpec(
  wheelX: 1.42,
  wheelR: 0.42,
  halfW: 0.96,
  noseX: 2.3,
  tailX: -2.2,
  lift: 0.18,
  belt: 1.22,
  hoodNose: 1.02,
  trunkTop: 1.2,
  cabinFront: 1.12,
  cabinRear: -1.95,
  roofFront: 0.3,
  roofRear: -1.8,
  roofY: 1.86,
  hatch: true,
  roofRails: true,
  cladding: true,
);

/// Geometry helpers shared by the parts of one [CarSpec].
class _Body {
  _Body(this.s);
  final CarSpec s;

  /// Plan-view half width: full between the axles, rounded at the ends.
  double w(double x) {
    final a = s.wheelX - 0.2;
    if (x > a) {
      final t = ((x - a) / (s.noseX - a)).clamp(0.0, 1.0);
      return s.halfW - 0.1 * t * t - 0.12 * math.pow(t, 6);
    }
    if (x < -a) {
      final t = ((-a - x) / (-a - s.tailX)).clamp(0.0, 1.0);
      return s.halfW - 0.07 * t * t - 0.1 * math.pow(t, 6);
    }
    return s.halfW;
  }

  /// Bottom edge of the body skin, cut out over the wheels.
  double sill(double x) {
    final ar = s.wheelR + 0.09;
    for (final c in [s.wheelX, -s.wheelX]) {
      final d = x - c;
      if (d.abs() < ar) {
        return math.max(s.sillY, s.wheelY + math.sqrt(ar * ar - d * d));
      }
    }
    return s.sillY;
  }

  /// Height of the upper edge of the lower body (hood / belt / boot).
  double top(double x) {
    if (x >= s.cabinFront) {
      final t = ((x - s.cabinFront) / (s.noseX - s.cabinFront)).clamp(0.0, 1.0);
      // Hood falls gently, then rolls over the nose.
      return s.belt + (s.hoodNose - s.belt) * (0.55 * t + 0.45 * t * t * t);
    }
    if (x <= s.cabinRear) {
      final t = ((s.cabinRear - x) / (s.cabinRear - s.tailX)).clamp(0.0, 1.0);
      if (s.hatch) return s.belt + (s.trunkTop - s.belt) * t;
      return s.belt + (s.trunkTop - s.belt) * t - 0.1 * math.pow(t, 8);
    }
    return s.belt;
  }

  /// Height where nose / tail faces end at the bottom.
  double get bumperLow => s.floorY + 0.02;

  /// Cross-section of the body side at [x] (one side, z >= 0), from the
  /// sill up to the shoulder. Tucked under, bulging, then rolling inwards.
  List<(double, double)> side(double x) {
    final y0 = sill(x), y1 = top(x), wx = w(x);
    final h = y1 - y0;
    return [
      (y0, wx - 0.05),
      (y0 + 0.12 * h, wx - 0.005),
      (y0 + 0.45 * h, wx + 0.02),
      (y0 + 0.78 * h, wx + 0.005),
      (y1 - 0.035, wx - 0.03),
      (y1, wx - 0.08),
    ];
  }

  /// Upper surface (hood / trunk) across the car at [x]: z from the
  /// shoulder to the centre line, with a slight crown.
  double crown(double x, double z) {
    final wx = w(x) - 0.08;
    final u = (z / wx).clamp(-1.0, 1.0);
    return top(x) + 0.05 * (1 - u * u);
  }

  V3 inside(double x) => V3(x, s.belt * 0.6, 0);

  /// Body side skin between [x0]..[x1] on side [sg] (±1).
  void sideSkin(
    MeshBuilder m,
    double x0,
    double x1,
    double sg, {
    double step = 0.09,
  }) {
    final xs = MeshBuilder.steps(x0, x1, step);
    for (var i = 0; i < xs.length - 1; i++) {
      final a = side(xs[i]), b = side(xs[i + 1]);
      final c = inside((xs[i] + xs[i + 1]) / 2);
      for (var j = 0; j < a.length - 1; j++) {
        m.quad(
          V3(xs[i], a[j].$1, sg * a[j].$2),
          V3(xs[i + 1], b[j].$1, sg * b[j].$2),
          V3(xs[i + 1], b[j + 1].$1, sg * b[j + 1].$2),
          V3(xs[i], a[j + 1].$1, sg * a[j + 1].$2),
          inside: c,
        );
      }
    }
  }

  /// Crowned top panel (hood or trunk) between [x0]..[x1].
  void topSkin(MeshBuilder m, double x0, double x1, {double step = 0.1}) {
    final xs = MeshBuilder.steps(x0, x1, step);
    const cols = 8;
    for (var i = 0; i < xs.length - 1; i++) {
      final xa = xs[i], xb = xs[i + 1];
      final c = V3((xa + xb) / 2, 0, 0);
      for (var j = 0; j < cols; j++) {
        final ua = -1 + 2 * j / cols, ub = -1 + 2 * (j + 1) / cols;
        V3 p(double x, double u) {
          final z = u * (w(x) - 0.08);
          return V3(x, crown(x, z), z);
        }

        m.quad(p(xa, ua), p(xb, ua), p(xb, ub), p(xa, ub), inside: c);
      }
    }
  }

  /// Nose or tail face at [x] closing the body between sill and top,
  /// curved in plan so the corners wrap round.
  void endFace(MeshBuilder m, double x, double dir, double yLow) {
    const cols = 10;
    final yTop = top(x);
    final wx = w(x);
    for (var j = 0; j < cols; j++) {
      final ua = -1 + 2 * j / cols, ub = -1 + 2 * (j + 1) / cols;
      V3 p(double u, double y) =>
          V3(x - dir * 0.14 * u * u, y, u * (wx - 0.05));
      m.quad(
        p(ua, yLow),
        p(ub, yLow),
        p(ub, yTop),
        p(ua, yTop),
        inside: V3(x - dir * 1, yTop * 0.6, 0),
      );
    }
  }

  // ---- Greenhouse ------------------------------------------------------

  double get glassBaseW => s.halfW - 0.1;
  double get roofW => s.halfW - 0.26;

  /// Half width of the greenhouse at height fraction [t] (0 belt, 1 roof).
  double ghW(double t) => glassBaseW + (roofW - glassBaseW) * t;
  double ghY(double t) => s.belt + (s.roofY - s.belt) * t;

  /// X of the windscreen / rear-glass edge at height fraction [t].
  double frontX(double t) =>
      s.cabinFront + (s.roofFront - s.cabinFront) * (1 - math.pow(1 - t, 1.4));
  double rearX(double t) =>
      s.cabinRear + (s.roofRear - s.cabinRear) * math.pow(t, 0.8).toDouble();
}

// ---------------------------------------------------------------------------

List<Face> _wheel(CarSpec s, double x, double sg) => buildMesh((m) {
  final r = s.wheelR;
  final c = V3(x, s.wheelY, sg * s.wheelZ);
  // Tyre: tread plus rounded shoulders.
  m.mat(_tire, Finish.rubber);
  m.cylinder(c, r, 0.2, Axis3.z, segs: 28);
  m.cylinder(c, r - 0.025, 0.25, Axis3.z, segs: 28);
  m.cylinder(c + V3(0, 0, sg * 0.1), r - 0.07, 0.07, Axis3.z, segs: 28);
  // Brake disc and caliper sit behind the spokes.
  m.mat(_metal, Finish.metal);
  m.cylinder(c + V3(0, 0, sg * 0.09), r * 0.55, 0.02, Axis3.z, segs: 20);
  m.mat(_caliper, Finish.metal);
  m.box(
    x - r * 0.52,
    s.wheelY + r * 0.28,
    c.z + sg * 0.085,
    x - r * 0.28,
    s.wheelY + r * 0.5,
    c.z + sg * 0.115,
  );
  // Dark rim barrel.
  m.mat(_darkMetal, Finish.metal);
  m.cylinder(c + V3(0, 0, sg * 0.12), r * 0.72, 0.015, Axis3.z, segs: 24);
  // Ten-spoke alloy (five twin spokes).
  m.mat(_alloy, Finish.chrome);
  final z0 = c.z + sg * 0.13, z1 = c.z + sg * 0.15;
  for (var k = 0; k < 5; k++) {
    final a = k / 5 * math.pi * 2;
    m.spokeZ(c, a - 0.13, 0.07, r * 0.7, 0.028, z0, z1);
    m.spokeZ(c, a + 0.13, 0.07, r * 0.7, 0.028, z0, z1);
  }
  m.ring(c + V3(0, 0, sg * 0.14), r * 0.71, 0.014, Axis3.z, segs: 28);
  m.cylinder(c + V3(0, 0, sg * 0.15), 0.075, 0.03, Axis3.z, segs: 14);
  m.mat(_trim);
  m.cylinder(c + V3(0, 0, sg * 0.168), 0.035, 0.008, Axis3.z, segs: 10);
});

List<Face> _seat(CarSpec s, double z) => buildMesh((m) {
  final y = s.floorY + 0.12;
  m.mat(_leather);
  m.box(-0.05, y, z - 0.24, 0.45, y + 0.18, z + 0.24);
  m.hexa([
    V3(-0.12, y + 0.18, z - 0.23), V3(0.0, y + 0.18, z - 0.23), //
    V3(-0.14, y + 0.76, z - 0.21), V3(-0.26, y + 0.76, z - 0.21),
    V3(-0.12, y + 0.18, z + 0.23), V3(0.0, y + 0.18, z + 0.23),
    V3(-0.14, y + 0.76, z + 0.21), V3(-0.26, y + 0.76, z + 0.21),
  ]);
  m.mat(_leatherLight);
  m.box(-0.28, y + 0.78, z - 0.12, -0.16, y + 0.92, z + 0.12);
});

/// Builds a full modern car from [s]; part ids match the classic sedan.
List<VehiclePart> buildCar(CarSpec s) {
  final b = _Body(s);
  final parts = <VehiclePart>[];
  final lift = s.lift;
  void add(
    String id,
    String name,
    PartGroup group,
    V3 from,
    String info,
    List<String> requires,
    void Function(MeshBuilder m) build, {
    V3? pivot,
    String? kind,
  }) {
    parts.add(
      VehiclePart(
        id: id,
        name: name,
        group: group,
        from: from,
        info: info,
        requires: requires,
        faces: buildMesh(build),
        pivot: pivot,
        kind: kind,
      ),
    );
  }

  final fy = s.floorY;

  add(
    'chassis',
    'Chassis',
    PartGroup.frame,
    const V3(0, 3, 0),
    'The chassis is the car\'s skeleton. Every other part bolts onto this steel frame and floor pan.',
    [],
    (m) {
      m.mat(_chassis);
      m.box(s.tailX + 0.2, fy, -0.62, s.noseX - 0.25, fy + 0.12, 0.62);
      for (final sg in const [-1.0, 1.0]) {
        m.box(-0.95, fy, sg * 0.62, 0.95, fy + 0.12, sg * (s.halfW - 0.16));
      }
      m.mat(_frame, Finish.metal);
      for (final sg in const [-1.0, 1.0]) {
        m.box(
          s.tailX + 0.1,
          fy - 0.06,
          sg * 0.42,
          s.noseX - 0.2,
          fy + 0.02,
          sg * 0.56,
        );
      }
      m.mat(_metal, Finish.metal);
      for (final x in [s.wheelX, -s.wheelX]) {
        m.cylinder(
          V3(x, s.wheelY, 0),
          0.045,
          2 * s.wheelZ - 0.2,
          Axis3.z,
          segs: 8,
        );
        // Coil springs / struts.
        for (final sg in const [-1.0, 1.0]) {
          m.rod(
            V3(x, s.wheelY, sg * (s.wheelZ - 0.22)),
            V3(x, s.wheelY + 0.4, sg * (s.wheelZ - 0.3)),
            0.05,
            segs: 8,
          );
        }
      }
    },
  );

  add(
    'engine',
    'Engine',
    PartGroup.powertrain,
    const V3(0, 2.6, 0),
    'The engine burns fuel to make power. The gearbox behind it sends that power to the wheels.',
    ['chassis'],
    (m) {
      final y = fy + 0.06;
      m.mat(_darkMetal, Finish.metal);
      m.box(1.05, y, -0.34, 1.72, y + 0.34, 0.34);
      m.box(0.4, y, -0.16, 1.05, y + 0.2, 0.16);
      m.mat(_engineRed, Finish.metal);
      m.maxEdge = 0.08;
      m.box(1.12, y + 0.34, -0.26, 1.6, y + 0.4, 0.26);
      m.maxEdge = 0.4;
      m.mat(_chrome, Finish.chrome);
      m.cylinder(V3(1.36, y + 0.42, 0), 0.13, 0.04, Axis3.y, segs: 16);
    },
  );

  add(
    'radiator',
    'Radiator',
    PartGroup.powertrain,
    const V3(2.6, 0.8, 0),
    'The radiator cools the engine by passing hot coolant through thin metal fins in the airflow.',
    ['chassis'],
    (m) {
      final x = s.noseX - 0.36;
      m.mat(_metal, Finish.metal);
      m.box(x, fy + 0.14, -0.55, x + 0.1, fy + 0.42, 0.55);
      m.mat(_trim);
      for (var i = 0; i < 4; i++) {
        final y = fy + 0.19 + i * 0.065;
        m.box(x + 0.1, y, -0.5, x + 0.115, y + 0.025, 0.5);
      }
    },
  );

  add(
    'battery',
    'Battery',
    PartGroup.powertrain,
    const V3(0.4, 2.4, 1.4),
    'The 12-volt battery cranks the starter motor and powers the lights and electronics.',
    ['chassis'],
    (m) {
      final y = fy + 0.12;
      m.mat(const Color(0xFF1E1F22));
      m.maxEdge = 0.06;
      m.box(1.2, y, 0.38, 1.52, y + 0.22, 0.6);
      m.maxEdge = 0.4;
      m.mat(const Color(0xFFE53935), Finish.metal);
      m.cylinder(V3(1.27, y + 0.24, 0.49), 0.03, 0.05, Axis3.y, segs: 8);
      m.mat(_chrome, Finish.chrome);
      m.cylinder(V3(1.45, y + 0.24, 0.49), 0.03, 0.05, Axis3.y, segs: 8);
    },
  );

  add(
    'fuel_tank',
    'Fuel Tank',
    PartGroup.powertrain,
    const V3(-2, 2, 0),
    'The fuel tank stores petrol. A pump inside sends fuel forward to the engine.',
    ['chassis'],
    (m) {
      m.mat(const Color(0xFF3A3F47), Finish.metal);
      m.box(-1.8, fy + 0.12, -0.5, -1.15, fy + 0.32, 0.5);
    },
  );

  add(
    'exhaust',
    'Exhaust',
    PartGroup.powertrain,
    const V3(-3, 0, 0),
    'The exhaust carries burnt gases from the engine to the back of the car and muffles the noise.',
    ['engine', 'fuel_tank'],
    (m) {
      final y = fy - 0.04;
      m.mat(_metal, Finish.metal);
      m.box(s.tailX + 0.15, y - 0.03, 0.25, 1.0, y + 0.02, 0.31);
      m.box(-1.0, y - 0.06, 0.2, -0.5, y + 0.03, 0.36);
      m.mat(_chrome, Finish.chrome);
      m.cylinder(V3(s.tailX + 0.02, y, 0.42), 0.055, 0.26, Axis3.x, segs: 14);
      m.cylinder(V3(s.tailX + 0.02, y, -0.42), 0.055, 0.26, Axis3.x, segs: 14);
    },
  );

  for (final (id, name, x, sg) in [
    ('wheel_fl', 'Front Left Wheel', s.wheelX, -1.0),
    ('wheel_fr', 'Front Right Wheel', s.wheelX, 1.0),
    ('wheel_rl', 'Rear Left Wheel', -s.wheelX, -1.0),
    ('wheel_rr', 'Rear Right Wheel', -s.wheelX, 1.0),
  ]) {
    parts.add(
      VehiclePart(
        id: id,
        name: name,
        group: PartGroup.wheels,
        from: V3(0, 0.2, sg * 2.6),
        info:
            'The rubber tyre grips the road. The wheel bolts onto the hub, and the brake disc sits behind it.',
        requires: const ['chassis'],
        faces: _wheel(s, x, sg),
        pivot: V3(x, s.wheelY, sg * s.wheelZ),
        kind: 'wheel',
      ),
    );
  }

  add(
    'dashboard',
    'Dashboard',
    PartGroup.interior,
    const V3(0, 2.5, 0),
    'The dashboard holds the gauges, air vents, controls and passenger airbag.',
    ['chassis'],
    (m) {
      final y = s.belt - 0.3;
      final x = s.cabinFront - 0.4;
      m.mat(_trim);
      m.box(x, y, -(s.halfW - 0.12), x + 0.32, y + 0.28, s.halfW - 0.12);
      m.box(x - 0.25, fy + 0.12, -0.1, x + 0.15, y, 0.1);
      m.mat(_gauge, Finish.light);
      m.box(x - 0.01, y + 0.14, -0.52, x, y + 0.23, -0.24);
      m.box(x - 0.01, y + 0.08, -0.1, x, y + 0.18, 0.1);
    },
  );

  add(
    'steering',
    'Steering Wheel',
    PartGroup.interior,
    const V3(-1.8, 1.2, 0),
    'Turning the steering wheel swivels the front wheels through the steering rack.',
    ['dashboard'],
    (m) {
      final c = V3(s.cabinFront - 0.48, s.belt - 0.1, -0.38);
      m.mat(_trim);
      m.cylinder(c + const V3(0.12, 0, 0), 0.03, 0.22, Axis3.x, segs: 8);
      m.ring(c, 0.17, 0.022, Axis3.x);
      m.box(
        c.x - 0.01,
        c.y - 0.02,
        c.z - 0.16,
        c.x + 0.01,
        c.y + 0.02,
        c.z + 0.16,
      );
      m.mat(_darkMetal, Finish.metal);
      m.cylinder(c, 0.06, 0.03, Axis3.x, segs: 10);
    },
  );

  add(
    'front_seats',
    'Front Seats',
    PartGroup.interior,
    const V3(0, 2.6, 0),
    'Front seats slide on rails bolted to the floor so every driver can reach the pedals.',
    ['chassis'],
    (m) {
      m.faces
        ..addAll(_seat(s, -0.38))
        ..addAll(_seat(s, 0.38));
    },
  );

  add(
    'rear_seat',
    'Rear Seat',
    PartGroup.interior,
    const V3(0, 2.6, 0),
    'The rear bench seats up to three passengers, each with a seat belt anchor.',
    ['chassis'],
    (m) {
      final y = fy + 0.12;
      m.mat(_leather);
      m.box(-0.72, y, -0.64, -0.3, y + 0.16, 0.64);
      m.hexa([
        V3(-0.82, y + 0.16, -0.64), V3(-0.7, y + 0.16, -0.64), //
        V3(-0.84, y + 0.66, -0.6), V3(-0.96, y + 0.66, -0.6),
        V3(-0.82, y + 0.16, 0.64), V3(-0.7, y + 0.16, 0.64),
        V3(-0.84, y + 0.66, 0.6), V3(-0.96, y + 0.66, 0.6),
      ]);
      m.mat(_leatherLight);
      for (final z in const [-0.38, 0.38]) {
        m.box(-0.98, y + 0.67, z - 0.12, -0.86, y + 0.78, z + 0.12);
      }
    },
  );

  // ---- Body panels -----------------------------------------------------

  void wheelWell(MeshBuilder m, double x) {
    m.mat(_plastic);
    for (final sg in const [-1.0, 1.0]) {
      final zc = sg * (s.halfW - 0.2);
      m.arc(
        V3(x, s.wheelY, zc),
        s.wheelR + 0.07,
        s.wheelR + 0.1,
        0,
        math.pi,
        -0.17,
        0.17,
        Axis3.z,
        segs: 16,
      );
    }
    if (s.cladding) {
      m.bias = -0.05;
      // Chunky black arch trim.
      for (final sg in const [-1.0, 1.0]) {
        final zc = sg * (b.w(x) + 0.012);
        m.arc(
          V3(x, s.wheelY, zc),
          s.wheelR + 0.07,
          s.wheelR + 0.15,
          0.04,
          math.pi - 0.04,
          -0.03,
          0.03,
          Axis3.z,
          segs: 14,
        );
      }
      m.bias = 0;
    }
  }

  add(
    'front_body',
    'Front Body',
    PartGroup.body,
    const V3(2.8, 1.2, 0),
    'Front fenders and the nose panel shape the front of the car and cover the front wheels.',
    ['engine', 'radiator', 'battery'],
    (m) {
      m.paint();
      for (final sg in const [-1.0, 1.0]) {
        b.sideSkin(m, s.cabinFront - 0.02, s.noseX - 0.02, sg);
      }
      b.endFace(m, s.noseX, 1, b.bumperLow + 0.22);
      wheelWell(m, s.wheelX);
      // Grille: dark mesh with a chrome surround.
      m.bias = -0.05;
      final gx = s.noseX + 0.005;
      final gy0 = b.bumperLow + 0.26, gy1 = s.hoodNose - 0.07;
      m.mat(_trim);
      m.box(gx - 0.02, gy0, -0.3, gx + 0.01, gy1, 0.3);
      m.mat(_chrome, Finish.chrome);
      m.box(gx, gy1 - 0.015, -0.32, gx + 0.02, gy1 + 0.005, 0.32);
      m.box(gx, gy0 - 0.005, -0.32, gx + 0.02, gy0 + 0.012, 0.32);
      m.mat(_plastic);
      for (var i = 1; i < 4; i++) {
        final y = gy0 + (gy1 - gy0) * i / 4;
        m.box(gx + 0.005, y - 0.006, -0.28, gx + 0.015, y + 0.006, 0.28);
      }
    },
  );

  add(
    'rear_body',
    'Rear Body',
    PartGroup.body,
    const V3(-2.8, 1.2, 0),
    'Rear quarter panels and the tail panel form the back of the car around the rear wheels.',
    ['fuel_tank'],
    (m) {
      m.paint();
      for (final sg in const [-1.0, 1.0]) {
        b.sideSkin(m, s.tailX + 0.02, s.cabinRear + 0.02, sg);
      }
      b.endFace(m, s.tailX, -1, b.bumperLow + 0.22);
      wheelWell(m, -s.wheelX);
    },
  );

  add(
    'hood',
    'Hood',
    PartGroup.body,
    const V3(0.4, 2.4, 0),
    'The hood (bonnet) covers the engine bay and lifts up for servicing.',
    ['front_body'],
    (m) {
      m.paint();
      b.topSkin(m, s.cabinFront, s.noseX - 0.01);
      // Shut line where the hood meets the fenders.
      m.mat(_trim);
      for (final sg in const [-1.0, 1.0]) {
        for (final (x0, x1) in [(s.cabinFront, s.noseX - 0.05)]) {
          final xs = MeshBuilder.steps(x0, x1, 0.15);
          for (var i = 0; i < xs.length - 1; i++) {
            final za = sg * (b.w(xs[i]) - 0.085),
                zb = sg * (b.w(xs[i + 1]) - 0.085);
            m.quad(
              V3(xs[i], b.crown(xs[i], za) + 0.002, za),
              V3(xs[i + 1], b.crown(xs[i + 1], zb) + 0.002, zb),
              V3(xs[i + 1], b.crown(xs[i + 1], zb) + 0.002, zb - sg * 0.01),
              V3(xs[i], b.crown(xs[i], za) + 0.002, za - sg * 0.01),
              inside: V3(xs[i], 0, 0),
            );
          }
        }
      }
    },
  );

  add(
    'trunk',
    s.hatch ? 'Tailgate' : 'Trunk Lid',
    PartGroup.body,
    const V3(-0.4, 2.4, 0),
    s.hatch
        ? 'The tailgate opens upwards to load bags and shopping into the boot.'
        : 'The trunk (boot) lid closes the luggage compartment at the back.',
    ['rear_body'],
    (m) {
      m.paint();
      b.topSkin(m, s.tailX + 0.01, s.cabinRear);
    },
  );

  // ---- Greenhouse ------------------------------------------------------

  // Rear pillar width: a chunky D-pillar on hatchbacks / SUVs.
  final cW = s.hatch ? 0.34 : 0.16;

  // Rows up the greenhouse side, used by roof pillars and glass.
  const rows = 6;

  add(
    'roof',
    'Roof & Pillars',
    PartGroup.body,
    const V3(0, 3, 0),
    'The roof and its pillars form a strong safety cage that protects passengers in a rollover.',
    ['front_body', 'rear_body', 'front_seats', 'rear_seat', 'steering'],
    (m) {
      m.paint();
      // Roof panel: crowned, rolling down at the edges.
      final xs = MeshBuilder.steps(s.roofRear, s.roofFront, 0.12);
      const cols = 10;
      for (var i = 0; i < xs.length - 1; i++) {
        for (var j = 0; j < cols; j++) {
          final ua = -1 + 2 * j / cols, ub = -1 + 2 * (j + 1) / cols;
          V3 p(double x, double u) => V3(
            x,
            s.roofY + 0.05 * (1 - u * u) - 0.035 * math.pow(u.abs(), 6),
            u * (b.roofW + 0.02),
          );
          m.quad(
            p(xs[i], ua),
            p(xs[i + 1], ua),
            p(xs[i + 1], ub),
            p(xs[i], ub),
            inside: V3(xs[i], 0, 0),
          );
        }
      }
      // A and C pillars follow the glass edges; B pillar is black.
      for (final sg in const [-1.0, 1.0]) {
        for (var r = 0; r < rows; r++) {
          final t0 = r / rows, t1 = (r + 1) / rows;
          V3 g(double x, double t, [double out = 0]) =>
              V3(x, b.ghY(t), sg * (b.ghW(t) + out));
          final c = V3(0, b.ghY(t0), 0);
          // A pillar
          m.quad(
            g(b.frontX(t0), t0),
            g(b.frontX(t0) - 0.07, t0),
            g(b.frontX(t1) - 0.07, t1),
            g(b.frontX(t1), t1),
            inside: c,
          );
          // C pillar (wider)
          m.quad(
            g(b.rearX(t0) + cW, t0),
            g(b.rearX(t0), t0),
            g(b.rearX(t1), t1),
            g(b.rearX(t1) + cW, t1),
            inside: c,
          );
        }
        m.mat(_trim);
        final bx = (s.roofFront + s.roofRear) / 2 + 0.05;
        for (var r = 0; r < rows; r++) {
          final t0 = r / rows, t1 = (r + 1) / rows;
          V3 g(double x, double t) => V3(x, b.ghY(t), sg * (b.ghW(t) + 0.004));
          m.quad(
            g(bx - 0.045, t0),
            g(bx + 0.045, t0),
            g(bx + 0.045, t1),
            g(bx - 0.045, t1),
            inside: V3(0, b.ghY(t0), 0),
          );
        }
        m.paint();
      }
      if (s.roofRails) {
        m.mat(_plastic, Finish.metal);
        for (final sg in const [-1.0, 1.0]) {
          final z = sg * (b.roofW - 0.06);
          m.box(
            s.roofRear + 0.05,
            s.roofY + 0.03,
            z - 0.025,
            s.roofFront - 0.05,
            s.roofY + 0.08,
            z + 0.025,
          );
        }
      }
    },
  );

  for (final (id, name, x0, x1, sg, hx) in [
    (
      'door_fl',
      'Front Left Door',
      0.0,
      s.cabinFront - 0.02,
      -1.0,
      s.cabinFront - 0.45,
    ),
    (
      'door_fr',
      'Front Right Door',
      0.0,
      s.cabinFront - 0.02,
      1.0,
      s.cabinFront - 0.45,
    ),
    ('door_rl', 'Rear Left Door', s.cabinRear + 0.02, 0.0, -1.0, -0.35),
    ('door_rr', 'Rear Right Door', s.cabinRear + 0.02, 0.0, 1.0, -0.35),
  ]) {
    parts.add(
      VehiclePart(
        id: id,
        name: name,
        group: PartGroup.body,
        from: V3(0, 0.2, sg * 2.6),
        info:
            'Each door hides a steel side-impact beam, the lock and the motor that raises the window.',
        requires: x0 >= 0
            ? const ['front_body', 'front_seats']
            : const ['rear_body', 'rear_seat'],
        faces: buildMesh((m) {
          m.paint();
          b.sideSkin(m, x0 + 0.008, x1 - 0.008, sg, step: 0.1);
          // Flush handle.
          m.bias = -0.05;
          final hy = s.belt - 0.12;
          final hz = sg * (s.halfW + 0.012);
          m.mat(_chrome, Finish.chrome);
          m.box(hx, hy, hz - 0.012, hx + 0.16, hy + 0.035, hz + 0.012);
          // Window seal along the top of the door.
          m.mat(_trim);
          m.box(
            x0 + 0.02,
            s.belt - 0.01,
            sg * (s.halfW - 0.1),
            x1 - 0.02,
            s.belt + 0.015,
            sg * (s.halfW - 0.075),
          );
          if (s.cladding) {
            // Black lower-door strip hugging the body curve.
            m.mat(_plastic);
            final xs = MeshBuilder.steps(x0 + 0.01, x1 - 0.01, 0.1);
            for (var i = 0; i < xs.length - 1; i++) {
              V3 p(double x, double up) {
                final y = b.sill(x) + up;
                final z = b.w(x) + (up == 0 ? -0.035 : 0.014);
                return V3(x, y, sg * z);
              }

              m.quad(
                p(xs[i], 0),
                p(xs[i + 1], 0),
                p(xs[i + 1], 0.14),
                p(xs[i], 0.14),
                inside: V3(xs[i], s.belt * 0.6, 0),
              );
            }
          }
        }),
      ),
    );
  }

  add(
    'windshield',
    'Windshield',
    PartGroup.glass,
    const V3(1.8, 1.6, 0),
    'Laminated safety glass keeps out wind and debris and holds together if it cracks.',
    ['roof'],
    (m) {
      m.mat(_glass, Finish.glass);
      const cols = 8;
      for (var r = 0; r < rows; r++) {
        final t0 = r / rows, t1 = (r + 1) / rows;
        for (var j = 0; j < cols; j++) {
          final ua = -1 + 2 * j / cols, ub = -1 + 2 * (j + 1) / cols;
          V3 p(double t, double u) => V3(
            b.frontX(t) + 0.05 * (1 - u * u) * (1 - t),
            b.ghY(t),
            u * b.ghW(t),
          );
          m.quad(
            p(t0, ua),
            p(t0, ub),
            p(t1, ub),
            p(t1, ua),
            inside: V3(0, b.ghY(t0), 0),
          );
        }
      }
    },
  );

  add(
    'rear_window',
    'Rear Window',
    PartGroup.glass,
    const V3(-1.8, 1.6, 0),
    'The rear window has a heater grid printed on it to clear mist and frost.',
    ['roof'],
    (m) {
      m.mat(_glass, Finish.glass);
      const cols = 8;
      for (var r = 0; r < rows; r++) {
        final t0 = r / rows, t1 = (r + 1) / rows;
        for (var j = 0; j < cols; j++) {
          final ua = -1 + 2 * j / cols, ub = -1 + 2 * (j + 1) / cols;
          V3 p(double t, double u) => V3(
            b.rearX(t) - 0.04 * (1 - u * u) * (1 - t),
            b.ghY(t),
            u * b.ghW(t),
          );
          m.quad(
            p(t0, ua),
            p(t0, ub),
            p(t1, ub),
            p(t1, ua),
            inside: V3(0, b.ghY(t0), 0),
          );
        }
      }
    },
  );

  add(
    'side_windows',
    'Side Windows',
    PartGroup.glass,
    const V3(0, 2.4, 0),
    'Side windows slide down into the doors on rails.',
    ['roof', 'door_fl', 'door_fr', 'door_rl', 'door_rr'],
    (m) {
      m.mat(_glass, Finish.glass);
      for (final sg in const [-1.0, 1.0]) {
        for (var r = 0; r < rows; r++) {
          final t0 = r / rows, t1 = (r + 1) / rows;
          V3 g(double x, double t) => V3(x, b.ghY(t), sg * (b.ghW(t) - 0.004));
          final c = V3(0, b.ghY(t0), 0);
          m.quad(
            g(b.rearX(t0) + cW, t0),
            g(b.frontX(t0) - 0.07, t0),
            g(b.frontX(t1) - 0.07, t1),
            g(b.rearX(t1) + cW, t1),
            inside: c,
          );
        }
      }
    },
  );

  // ---- Lights ----------------------------------------------------------

  add(
    'headlights',
    'Headlights',
    PartGroup.lights,
    const V3(2.4, 0.3, 0),
    'Headlights light the road ahead. The amber lamps below are the turn signals.',
    ['front_body'],
    (m) {
      m.bias = -0.05; // draw over the body panels
      final y1 = s.hoodNose - 0.02, y0 = y1 - 0.13;
      for (final sg in const [-1.0, 1.0]) {
        // Swept cluster wrapping round the nose corner.
        final xs = MeshBuilder.steps(0.46, 0.97, 0.085);
        for (var i = 0; i < xs.length - 1; i++) {
          V3 p(double u, double y) {
            final z = sg * u * (b.w(s.noseX) - 0.05);
            final x = s.noseX - 0.14 * u * u + 0.012;
            return V3(x, y, z);
          }

          final ya = y0 + 0.06 * (xs[i] - 0.46),
              yb = y0 + 0.06 * (xs[i + 1] - 0.46);
          m.mat(_headlight, Finish.light);
          m.quad(
            p(xs[i], ya),
            p(xs[i + 1], yb),
            p(xs[i + 1], y1),
            p(xs[i], y1),
            inside: const V3(0, 0.5, 0),
          );
          m.mat(_drl, Finish.light);
          m.quad(
            p(xs[i], ya - 0.03),
            p(xs[i + 1], yb - 0.03),
            p(xs[i + 1], yb - 0.012),
            p(xs[i], ya - 0.012),
            inside: const V3(0, 0.5, 0),
          );
        }
        m.mat(_amber, Finish.light);
        final u = 0.97;
        final z = sg * u * (b.w(s.noseX) - 0.05);
        final x = s.noseX - 0.14 * u * u + 0.01;
        m.box(x - 0.08, y0, z - 0.01, x, y1 - 0.04, z + 0.01);
      }
    },
  );

  add(
    'taillights',
    'Taillights',
    PartGroup.lights,
    const V3(-2.4, 0.3, 0),
    'Taillights glow red at night and shine brighter when you press the brake.',
    ['rear_body'],
    (m) {
      m.bias = -0.05;
      final y1 = s.trunkTop - 0.05, y0 = y1 - 0.14;
      // Full-width light bar with wrap-around corners.
      final us = MeshBuilder.steps(-0.98, 0.98, 0.14);
      for (var i = 0; i < us.length - 1; i++) {
        V3 p(double u, double y) =>
            V3(s.tailX + 0.14 * u * u - 0.012, y, u * (b.w(s.tailX) - 0.05));
        final outer = us[i].abs() > 0.55 || us[i + 1].abs() > 0.55;
        m.mat(outer ? _taillight : const Color(0xFF7F0000), Finish.light);
        m.quad(
          p(us[i], outer ? y0 : y1 - 0.04),
          p(us[i + 1], outer ? y0 : y1 - 0.04),
          p(us[i + 1], y1),
          p(us[i], y1),
          inside: const V3(0, 0.5, 0),
        );
      }
    },
  );

  add(
    'front_bumper',
    'Front Bumper',
    PartGroup.body,
    const V3(2.6, 0, 0),
    'Bumpers soak up small knocks and protect the lights and radiator. The number plate mounts here.',
    ['front_body'],
    (m) {
      final y0 = b.bumperLow, y1 = b.bumperLow + 0.24;
      m.paint();
      const cols = 12;
      for (var j = 0; j < cols; j++) {
        final ua = -1 + 2 * j / cols, ub = -1 + 2 * (j + 1) / cols;
        V3 p(double u, double y, double out) =>
            V3(s.noseX + out - 0.16 * u * u, y, u * (b.w(s.noseX) - 0.03));
        m.quad(
          p(ua, y0 + 0.04, -0.03),
          p(ub, y0 + 0.04, -0.03),
          p(ub, y1, 0.03),
          p(ua, y1, 0.03),
          inside: const V3(0, 0.4, 0),
        );
        m.quad(
          p(ua, y0, -0.1),
          p(ub, y0, -0.1),
          p(ub, y0 + 0.04, -0.03),
          p(ua, y0 + 0.04, -0.03),
          inside: const V3(0, 0.4, 0),
        );
      }
      // Lower air intake, fog lights and plate.
      m.bias = -0.05;
      m.mat(_trim);
      m.box(s.noseX - 0.01, y0 + 0.06, -0.5, s.noseX + 0.035, y0 + 0.15, 0.5);
      m.mat(_headlight, Finish.light);
      for (final sg in const [-1.0, 1.0]) {
        m.box(
          s.noseX - 0.08,
          y0 + 0.07,
          sg * 0.66 - 0.06,
          s.noseX - 0.01,
          y0 + 0.13,
          sg * 0.66 + 0.06,
        );
      }
      m.mat(_plate);
      m.box(s.noseX + 0.03, y0 + 0.14, -0.2, s.noseX + 0.045, y0 + 0.23, 0.2);
    },
  );

  add(
    'rear_bumper',
    'Rear Bumper',
    PartGroup.body,
    const V3(-2.6, 0, 0),
    'The rear bumper protects the tail. Parking sensors are often built into it.',
    ['rear_body', 'exhaust'],
    (m) {
      final y0 = b.bumperLow, y1 = b.bumperLow + 0.24;
      m.paint();
      const cols = 12;
      for (var j = 0; j < cols; j++) {
        final ua = -1 + 2 * j / cols, ub = -1 + 2 * (j + 1) / cols;
        V3 p(double u, double y, double out) =>
            V3(s.tailX - out + 0.16 * u * u, y, u * (b.w(s.tailX) - 0.03));
        m.quad(
          p(ua, y0 + 0.04, -0.03),
          p(ub, y0 + 0.04, -0.03),
          p(ub, y1, 0.03),
          p(ua, y1, 0.03),
          inside: const V3(0, 0.4, 0),
        );
      }
      // Diffuser and plate.
      m.bias = -0.05;
      m.mat(_trim);
      m.box(s.tailX - 0.06, y0 - 0.02, -0.6, s.tailX + 0.05, y0 + 0.06, 0.6);
      m.mat(_plate);
      m.box(s.tailX - 0.05, y1 - 0.02, -0.2, s.tailX - 0.035, y1 + 0.08, 0.2);
    },
  );

  add(
    'mirrors',
    'Side Mirrors',
    PartGroup.body,
    const V3(0, 2, 0),
    'Side mirrors let the driver see traffic behind and beside the car.',
    ['door_fl', 'door_fr'],
    (m) {
      final x = s.cabinFront - 0.2, y = s.belt + 0.02;
      for (final sg in const [-1.0, 1.0]) {
        final z = sg * s.halfW;
        m.mat(_trim);
        m.box(x, y, z - sg * 0.1, x + 0.08, y + 0.04, z + sg * 0.02);
        m.paint();
        m.hexa([
          V3(x - 0.06, y + 0.02, z), V3(x + 0.1, y + 0.02, z), //
          V3(x + 0.08, y + 0.15, z), V3(x - 0.04, y + 0.15, z),
          V3(x - 0.02, y + 0.03, z + sg * 0.2),
          V3(x + 0.1, y + 0.03, z + sg * 0.2),
          V3(x + 0.08, y + 0.14, z + sg * 0.18),
          V3(x - 0.01, y + 0.14, z + sg * 0.18),
        ]);
        m.mat(_amber, Finish.light);
        m.box(
          x + 0.09,
          y + 0.05,
          z + sg * 0.1,
          x + 0.1,
          y + 0.07,
          z + sg * 0.18,
        );
      }
    },
  );

  add(
    'spoiler',
    s.hatch ? 'Roof Spoiler' : 'Spoiler',
    PartGroup.body,
    const V3(0, 2.5, 0),
    'A spoiler presses the rear of the car down at high speed for better grip.',
    [s.hatch ? 'roof' : 'trunk'],
    (m) {
      m.paint();
      if (s.hatch) {
        m.hexa([
          V3(s.roofRear - 0.05, s.roofY + 0.02, -b.roofW),
          V3(s.roofRear + 0.12, s.roofY + 0.04, -b.roofW), //
          V3(s.roofRear + 0.12, s.roofY + 0.06, -b.roofW),
          V3(s.roofRear - 0.06, s.roofY + 0.05, -b.roofW),
          V3(s.roofRear - 0.05, s.roofY + 0.02, b.roofW),
          V3(s.roofRear + 0.12, s.roofY + 0.04, b.roofW),
          V3(s.roofRear + 0.12, s.roofY + 0.06, b.roofW),
          V3(s.roofRear - 0.06, s.roofY + 0.05, b.roofW),
        ]);
      } else {
        // Subtle ducktail lip that follows the boot's crown.
        final x0 = s.tailX + 0.03, x1 = s.tailX + 0.2;
        const cols = 8;
        for (var j = 0; j < cols; j++) {
          final ua = -0.9 + 1.8 * j / cols, ub = -0.9 + 1.8 * (j + 1) / cols;
          V3 p(double x, double u, double up) {
            final z = u * (b.w(x) - 0.08);
            return V3(x, b.crown(x, z) + up, z);
          }

          const c = V3(0, 0, 0);
          m.quad(
            p(x0, ua, 0.045),
            p(x1, ua, 0.006),
            p(x1, ub, 0.006),
            p(x0, ub, 0.045),
            inside: c,
          );
          m.quad(
            p(x0, ua, 0.0),
            p(x0, ua, 0.045),
            p(x0, ub, 0.045),
            p(x0, ub, 0.0),
            inside: const V3(10, 0, 0),
          );
        }
      }
    },
  );

  assert(lift >= 0);
  return parts;
}

List<VehiclePart> buildModernSedan() => buildCar(sedanSpec);
List<VehiclePart> buildSuv() => buildCar(suvSpec);
