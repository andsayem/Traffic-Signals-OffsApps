import 'dart:math' as math;
import 'dart:ui' show Color;

import '../engine/mesh.dart';
import '../engine/vec3.dart';
import 'part.dart';

// A standard air-cooled street bike (commuter / naked style).

// Materials
const _tire = Color(0xFF1A1B1E);
const _chrome = Color(0xFFD8DDE3);
const _alloy = Color(0xFFA9B0B8); // cast aluminium
const _frameBlack = Color(0xFF1F2226);
const _black = Color(0xFF16181B);
const _seat = Color(0xFF1C1918);
const _brakeDisc = Color(0xFFB8BEC6);
const _springRed = Color(0xFFC62828);
const _amber = Color(0xFFFFA726);
const _tailRed = Color(0xFFE53935);
const _lens = Color(0xFFFFF6D5);
const _gauge = Color(0xFFE0F7FA);

// Geometry (metres). X forward, Y up, Z right.
const _wheelR = 0.31;
const _front = V3(0.70, _wheelR, 0); // front axle
const _rear = V3(-0.66, _wheelR, 0); // rear axle
const _headTop = V3(0.47, 0.97, 0);
const _headBottom = V3(0.527, 0.80, 0);
const _pivot = V3(-0.22, 0.40, 0); // swingarm pivot
const _chainZ = -0.12;
const _forkZ = 0.085;

/// Point on the fork line, [t] metres up from the front axle.
V3 _forkAt(double t) {
  const d = V3(-0.333, 0.943, 0); // steering axis direction (upwards)
  return _front + d * t;
}

List<Face> _wheel(V3 c, {required bool front}) => buildMesh((m) {
  m.mat(_tire, Finish.rubber);
  m.torus(c, 0.245, 0.065, Axis3.z, major: 32, minor: 10);
  m.mat(_alloy, Finish.metal);
  m.arc(c, 0.198, 0.214, 0, math.pi * 2, -0.052, 0.052, Axis3.z, segs: 32);
  // Six twin spokes of the cast wheel.
  for (var k = 0; k < 6; k++) {
    final a = k / 6 * math.pi * 2;
    for (final off in const [-0.09, 0.09]) {
      m.spokeZ(c, a + off, 0.05, 0.2, 0.009, c.z - 0.012, c.z + 0.012);
    }
  }
  m.cylinder(c, 0.048, 0.15, Axis3.z, segs: 14);
  if (front) {
    m.mat(_brakeDisc, Finish.chrome);
    m.cylinder(c + const V3(0, 0, 0.07), 0.125, 0.006, Axis3.z, segs: 28);
    m.mat(_alloy, Finish.metal);
    m.cylinder(c + const V3(0, 0, 0.074), 0.06, 0.006, Axis3.z, segs: 14);
  } else {
    // Drum brake on the right, sprocket with teeth on the left.
    m.mat(_alloy, Finish.metal);
    m.cylinder(c + const V3(0, 0, 0.075), 0.095, 0.05, Axis3.z, segs: 20);
    m.mat(const Color(0xFF3A3D42), Finish.metal);
    final s = c + const V3(0, 0, _chainZ);
    m.cylinder(s, 0.1, 0.008, Axis3.z, segs: 28);
    for (var k = 0; k < 28; k++) {
      m.spokeZ(
        s,
        k / 28 * math.pi * 2,
        0.098,
        0.113,
        0.005,
        s.z - 0.004,
        s.z + 0.004,
      );
    }
  }
});

List<VehiclePart> buildMotorbike() {
  final l = PartList();

  l.add(
    'frame',
    'Frame',
    PartGroup.frame,
    const V3(0, 2, 0),
    'The steel frame links the steering head to the swingarm pivot and carries the engine.',
    [],
    (m) {
      m.mat(_frameBlack, Finish.metal);
      m.rod(
        _headTop + const V3(-0.008, 0.03, 0),
        _headBottom + const V3(0.006, -0.03, 0),
        0.032,
        segs: 12,
      );
      // Backbone under the tank, splitting into twin rails to the pivot.
      m.rods(
        [
          _headTop + const V3(0, -0.02, 0),
          const V3(0.2, 0.84, 0),
          const V3(-0.1, 0.78, 0),
        ],
        0.026,
        segs: 10,
      );
      for (final s in const [-1.0, 1.0]) {
        final z = V3(0, 0, s * 0.07);
        m.rods(
          [
            const V3(-0.1, 0.78, 0),
            const V3(-0.2, 0.7, 0) + z,
            _pivot + const V3(0, 0.04, 0) + z,
          ],
          0.022,
          segs: 10,
        );
        // Double cradle under the engine.
        final w = V3(0, 0, s * 0.06);
        m.rods(
          [
            _headBottom + w * 0.4,
            const V3(0.36, 0.45, 0) + w,
            const V3(0.26, 0.17, 0) + w,
            const V3(-0.12, 0.17, 0) + w,
            _pivot + const V3(0, -0.03, 0) + z,
          ],
          0.019,
          segs: 10,
        );
        // Rear subframe.
        final r = V3(0, 0, s * 0.09);
        m.rod(
          const V3(-0.14, 0.77, 0) + r,
          const V3(-0.8, 0.85, 0) + r,
          0.014,
          segs: 8,
        );
        m.rod(
          _pivot + const V3(-0.02, 0.1, 0) + r * 0.9,
          const V3(-0.58, 0.83, 0) + r,
          0.013,
          segs: 8,
        );
      }
      m.rod(
        const V3(-0.8, 0.85, -0.09),
        const V3(-0.8, 0.85, 0.09),
        0.013,
        segs: 8,
      );
    },
  );

  l.add(
    'engine',
    'Engine',
    PartGroup.powertrain,
    const V3(0, 1.8, 0),
    'An air-cooled single-cylinder engine. The fins on the cylinder shed heat into the passing air.',
    ['frame'],
    (m) {
      // Crankcase.
      m.mat(_alloy, Finish.metal);
      m.loft([
        MeshBuilder.section(-0.15, 0.32, 0.09, 0.09, p: 3.5),
        MeshBuilder.section(-0.11, 0.32, 0.13, 0.115, p: 3.5),
        MeshBuilder.section(0.22, 0.32, 0.13, 0.115, p: 3.5),
        MeshBuilder.section(0.29, 0.33, 0.1, 0.09, p: 3.5),
      ]);
      m.mat(_chrome, Finish.chrome);
      m.cylinder(const V3(0.13, 0.31, 0.13), 0.105, 0.04, Axis3.z, segs: 24);
      m.mat(_alloy, Finish.metal);
      m.cylinder(const V3(-0.02, 0.33, -0.13), 0.095, 0.04, Axis3.z, segs: 24);
      m.mat(const Color(0xFF3A3D42), Finish.metal);
      m.cylinder(
        const V3(0.02, 0.3, _chainZ - 0.03),
        0.045,
        0.01,
        Axis3.z,
        segs: 14,
      );
      // Finned cylinder, tilted forward.
      const b0 = V3(0.2, 0.44, 0), b1 = V3(0.3, 0.71, 0);
      final d = (b1 - b0).normalized;
      m.mat(_black, Finish.metal);
      m.rod(b0, b1, 0.06, segs: 14);
      m.mat(_alloy, Finish.metal);
      for (var k = 0; k < 8; k++) {
        final c = V3.lerp(b0, b1, (k + 0.5) / 8 * 0.8);
        m.rod(c - d * 0.006, c + d * 0.006, 0.098, segs: 16);
      }
      m.rod(b1 - d * 0.06, b1 + d * 0.01, 0.085, segs: 16);
      m.mat(_black, Finish.metal);
      m.rod(b1 + d * 0.01, b1 + d * 0.04, 0.06, segs: 14);
      // Carburettor and intake.
      m.mat(_alloy, Finish.metal);
      m.rod(const V3(0.22, 0.62, 0), const V3(0.04, 0.62, 0), 0.028, segs: 10);
      m.mat(_black);
      m.rod(const V3(0.04, 0.62, 0), const V3(-0.06, 0.6, 0), 0.04, segs: 10);
    },
  );

  l.add(
    'fork',
    'Front Forks',
    PartGroup.frame,
    const V3(1.4, 0.6, 0),
    'Telescopic forks hold the front wheel. Springs and oil inside soak up bumps.',
    ['frame'],
    (m) {
      final top = _forkAt(0.72), mid = _forkAt(0.37);
      for (final s in const [-1.0, 1.0]) {
        final z = V3(0, 0, s * _forkZ);
        m.mat(_chrome, Finish.chrome);
        m.rod(top + z, mid + z, 0.019, segs: 12);
        m.mat(_alloy, Finish.metal);
        m.rod(mid + z, _front + const V3(0.005, 0.03, 0) + z, 0.029, segs: 12);
        m.rod(mid + z, mid + z - const V3(-0.013, 0.037, 0), 0.031, segs: 12);
      }
      // Triple clamps and axle.
      m.mat(_alloy, Finish.metal);
      for (final t in [0.7, 0.52]) {
        final c = _forkAt(t);
        m.loft([
          MeshBuilder.section(c.x - 0.04, c.y, 0.016, 0.11, p: 4),
          MeshBuilder.section(c.x + 0.03, c.y, 0.016, 0.11, p: 4),
        ]);
      }
      m.mat(_chrome, Finish.chrome);
      m.cylinder(_front, 0.014, 0.24, Axis3.z, segs: 8);
      // Brake caliper gripping the disc.
      m.mat(const Color(0xFF4A4F57), Finish.metal);
      final cal = _front + const V3(-0.075, 0.09, 0.075);
      m.box(
        cal.x - 0.03,
        cal.y - 0.045,
        cal.z - 0.018,
        cal.x + 0.03,
        cal.y + 0.045,
        cal.z + 0.018,
      );
    },
  );

  l.add(
    'swingarm',
    'Swingarm',
    PartGroup.frame,
    const V3(-1.4, 0.4, 0),
    'The swingarm pivots up and down so the rear wheel can follow the road.',
    ['frame'],
    (m) {
      m.mat(_frameBlack, Finish.metal);
      for (final s in const [-1.0, 1.0]) {
        m.rod(
          _pivot + V3(0, 0, s * 0.1),
          _rear + V3(0.03, 0, s * 0.1),
          0.022,
          segs: 10,
        );
      }
      m.rod(
        _pivot + const V3(0, 0, -0.11),
        _pivot + const V3(0, 0, 0.11),
        0.026,
        segs: 10,
      );
      m.rod(
        const V3(-0.4, 0.37, -0.1),
        const V3(-0.4, 0.37, 0.1),
        0.016,
        segs: 8,
      );
      m.mat(_chrome, Finish.chrome);
      m.cylinder(_rear, 0.014, 0.26, Axis3.z, segs: 8);
    },
  );

  l.add(
    'shocks',
    'Rear Shocks',
    PartGroup.frame,
    const V3(-0.8, 1.2, 0),
    'Twin shock absorbers: a coil spring carries the weight and an oil damper stops bouncing.',
    ['swingarm'],
    (m) {
      for (final s in const [-1.0, 1.0]) {
        final b = V3(-0.57, 0.36, s * 0.125), t = V3(-0.45, 0.82, s * 0.105);
        final d = (t - b).normalized;
        m.mat(_black, Finish.metal);
        m.rod(b, t, 0.015, segs: 10);
        m.cylinder(b, 0.02, 0.04, Axis3.z, segs: 10);
        m.cylinder(t, 0.02, 0.04, Axis3.z, segs: 10);
        m.mat(_chrome, Finish.chrome);
        m.rod(t - d * 0.12, t - d * 0.02, 0.028, segs: 12);
        m.rod(b + d * 0.03, b + d * 0.1, 0.022, segs: 12);
        m.mat(_springRed, Finish.metal);
        m.helix(b + d * 0.1, t - d * 0.13, 0.03, 7, 0.0065);
      }
    },
  );

  l.add(
    'wheel_front',
    'Front Wheel',
    PartGroup.wheels,
    const V3(0, 0.1, 1.6),
    'Cast alloy wheel with a tubeless tyre and a disc brake for strong stopping.',
    ['fork'],
    (m) => m.faces.addAll(_wheel(_front, front: true)),
    pivot: _front,
  );

  l.add(
    'wheel_rear',
    'Rear Wheel',
    PartGroup.wheels,
    const V3(0, 0.1, -1.6),
    'The rear wheel carries the big sprocket that the chain pulls on, and a drum brake.',
    ['swingarm'],
    (m) => m.faces.addAll(_wheel(_rear, front: false)),
    pivot: _rear,
  );

  l.add(
    'chain',
    'Drive Chain',
    PartGroup.powertrain,
    const V3(0, 0.3, -1.2),
    'The chain links the engine sprocket to the rear wheel sprocket. The guard keeps clothes out of it.',
    ['engine', 'wheel_rear'],
    (m) {
      m.mat(const Color(0xFF5A5E64), Finish.metal);
      const z = V3(0, 0, _chainZ - 0.03);
      const zr = V3(0, 0, _chainZ);
      m.rod(
        const V3(0.02, 0.345, 0) + z,
        _rear + const V3(0, 0.105, 0) + zr,
        0.008,
        segs: 6,
      );
      m.rod(
        const V3(0.02, 0.255, 0) + z,
        _rear + const V3(0, -0.105, 0) + zr,
        0.008,
        segs: 6,
      );
      m.mat(_black, Finish.metal);
      m.hexa([
        const V3(-0.56, 0.44, -0.145),
        const V3(0.0, 0.38, -0.145),
        const V3(0.0, 0.41, -0.145),
        const V3(-0.56, 0.475, -0.145),
        const V3(-0.56, 0.44, -0.132),
        const V3(0.0, 0.38, -0.132),
        const V3(0.0, 0.41, -0.132),
        const V3(-0.56, 0.475, -0.132),
      ]);
    },
  );

  l.add(
    'exhaust',
    'Exhaust',
    PartGroup.powertrain,
    const V3(-1.2, 0, 0.8),
    'Hot gases leave through the header pipe and are quietened in the muffler.',
    ['engine'],
    (m) {
      m.mat(_chrome, Finish.chrome);
      m.rods(
        [
          const V3(0.33, 0.65, 0.03),
          const V3(0.4, 0.55, 0.07),
          const V3(0.385, 0.32, 0.11),
          const V3(0.26, 0.17, 0.14),
          const V3(-0.08, 0.17, 0.17),
          const V3(-0.2, 0.22, 0.2),
        ],
        0.021,
        segs: 10,
      );
      m.rod(
        const V3(-0.2, 0.22, 0.21),
        const V3(-0.82, 0.37, 0.21),
        0.056,
        endRadius: 0.046,
        segs: 18,
      );
      m.mat(_black, Finish.metal);
      m.rod(
        const V3(-0.82, 0.37, 0.21),
        const V3(-0.85, 0.378, 0.21),
        0.04,
        segs: 14,
      );
      // Heat shield.
      m.loft([
        MeshBuilder.section(-0.3, 0.27, 0.05, 0.03, cz: 0.245, p: 3),
        MeshBuilder.section(-0.55, 0.33, 0.045, 0.03, cz: 0.245, p: 3),
      ]);
    },
  );

  l.add(
    'fuel_tank',
    'Fuel Tank',
    PartGroup.body,
    const V3(0, 1.6, 0),
    'The teardrop fuel tank sits above the engine. Riders grip it with their knees in corners.',
    ['engine'],
    (m) {
      m.paint();
      m.loft([
        for (final (x, y, ry, rz) in const [
          (-0.1, 0.86, 0.045, 0.09),
          (-0.04, 0.885, 0.08, 0.14),
          (0.06, 0.912, 0.108, 0.168),
          (0.2, 0.925, 0.116, 0.174),
          (0.33, 0.922, 0.108, 0.162),
          (0.43, 0.908, 0.088, 0.13),
          (0.49, 0.892, 0.058, 0.088),
          (0.51, 0.886, 0.03, 0.05),
        ])
          MeshBuilder.section(x, y, ry, rz, p: 2.3),
      ]);
      m.mat(_chrome, Finish.chrome);
      m.cylinder(const V3(0.2, 1.042, 0), 0.034, 0.012, Axis3.y, segs: 14);
      // Chrome tank badges.
      for (final s in const [-1.0, 1.0]) {
        m.loft([
          MeshBuilder.section(0.14, 0.93, 0.022, 0.005, cz: s * 0.176, p: 3),
          MeshBuilder.section(0.28, 0.93, 0.022, 0.005, cz: s * 0.168, p: 3),
        ]);
      }
    },
  );

  l.add(
    'side_covers',
    'Side Panels',
    PartGroup.body,
    const V3(0, 0.4, 1.4),
    'Side panels hide the air filter and battery under the seat.',
    ['frame'],
    (m) {
      m.mat(_black);
      m.box(-0.36, 0.56, -0.085, -0.12, 0.78, 0.085);
      m.paint();
      for (final s in const [-1.0, 1.0]) {
        m.hexa([
          V3(-0.4, 0.6, s * 0.1), V3(-0.12, 0.56, s * 0.1), //
          V3(-0.08, 0.8, s * 0.1), V3(-0.47, 0.83, s * 0.1),
          V3(-0.4, 0.6, s * 0.122), V3(-0.12, 0.56, s * 0.125),
          V3(-0.08, 0.8, s * 0.118), V3(-0.47, 0.83, s * 0.112),
        ]);
      }
    },
  );

  l.add(
    'seat',
    'Seat',
    PartGroup.controls,
    const V3(-0.4, 1.4, 0),
    'A stepped two-level seat: the rider sits low near the tank, the passenger slightly higher.',
    ['fuel_tank', 'side_covers'],
    (m) {
      m.mat(_seat, Finish.metal);
      m.loft([
        for (final (x, y, ry, rz) in const [
          (-0.08, 0.86, 0.028, 0.085),
          (-0.15, 0.878, 0.045, 0.135),
          (-0.34, 0.888, 0.05, 0.15),
          (-0.44, 0.9, 0.052, 0.145),
          (-0.5, 0.92, 0.05, 0.138),
          (-0.66, 0.93, 0.045, 0.128),
          (-0.77, 0.928, 0.028, 0.095),
        ])
          MeshBuilder.section(x, y, ry, rz, p: 3),
      ]);
    },
  );

  l.add(
    'handlebar',
    'Handlebar & Mirrors',
    PartGroup.controls,
    const V3(0.4, 1.4, 0),
    'The right grip is the throttle. Levers work the front brake and clutch.',
    ['fork'],
    (m) {
      m.mat(_chrome, Finish.chrome);
      final bar = [
        for (final s in const [-1.0, 1.0])
          for (final (x, y, z)
              in s < 0
                  ? const [
                      (0.41, 1.05, 0.35),
                      (0.44, 1.05, 0.22),
                      (0.47, 1.025, 0.1),
                    ]
                  : const [
                      (0.47, 1.025, 0.1),
                      (0.44, 1.05, 0.22),
                      (0.41, 1.05, 0.35),
                    ])
            V3(x, y, s * z),
      ];
      m.rods(bar, 0.012, segs: 10);
      m.mat(_alloy, Finish.metal);
      m.box(0.44, 0.99, -0.05, 0.5, 1.035, 0.05); // bar clamp
      for (final s in const [-1.0, 1.0]) {
        m.mat(_black, Finish.rubber);
        m.rod(
          V3(0.425, 1.05, s * 0.26),
          V3(0.405, 1.05, s * 0.37),
          0.018,
          segs: 10,
        );
        m.mat(_black);
        m.loft([
          MeshBuilder.section(0.43, 1.05, 0.026, 0.022, cz: s * 0.215),
          MeshBuilder.section(0.46, 1.05, 0.026, 0.022, cz: s * 0.215),
        ]);
        m.mat(_alloy, Finish.metal);
        m.rod(
          V3(0.455, 1.055, s * 0.225),
          V3(0.48, 1.05, s * 0.34),
          0.006,
          segs: 5,
        );
        // Mirror on a chrome stalk.
        m.mat(_chrome, Finish.chrome);
        m.rods(
          [
            V3(0.445, 1.07, s * 0.2),
            V3(0.44, 1.2, s * 0.24),
            V3(0.425, 1.25, s * 0.27),
          ],
          0.006,
          segs: 6,
        );
        m.mat(_black, Finish.metal);
        m.cylinder(V3(0.42, 1.28, s * 0.285), 0.05, 0.022, Axis3.x, segs: 18);
        m.mat(_chrome, Finish.chrome);
        m.cylinder(V3(0.407, 1.28, s * 0.285), 0.044, 0.004, Axis3.x, segs: 18);
      }
    },
  );

  l.add(
    'meter',
    'Speedometer',
    PartGroup.controls,
    const V3(1.2, 1, 0),
    'The speedometer shows speed, fuel level and distance travelled.',
    ['handlebar'],
    (m) {
      final c = V3(0.52, 1.05, 0);
      const up = V3(0.35, 0.94, 0);
      m.mat(_black, Finish.metal);
      m.rod(c - up * 0.03, c + up * 0.02, 0.058, segs: 20);
      m.mat(_gauge, Finish.light);
      m.rod(c + up * 0.02, c + up * 0.024, 0.05, segs: 20);
      m.mat(_tailRed, Finish.light);
      m.rod(
        c + up * 0.02 + const V3(-0.025, 0, 0),
        c + up * 0.026 + const V3(-0.025, 0, 0),
        0.004,
        segs: 4,
      );
    },
  );

  l.add(
    'headlight',
    'Headlight',
    PartGroup.lights,
    const V3(1.2, 0.2, 0),
    'The round headlight has a low beam and a high beam. Amber indicators flash to signal turns.',
    ['fork'],
    (m) {
      const cy = 0.9;
      m.mat(_black, Finish.metal);
      m.loft([
        MeshBuilder.section(0.54, cy, 0.04, 0.04, p: 2, n: 22),
        MeshBuilder.section(0.57, cy, 0.07, 0.07, p: 2, n: 22),
        MeshBuilder.section(0.605, cy, 0.086, 0.086, p: 2, n: 22),
        MeshBuilder.section(0.63, cy, 0.088, 0.088, p: 2, n: 22),
      ]);
      m.mat(_chrome, Finish.chrome);
      m.ring(const V3(0.633, cy, 0), 0.082, 0.008, Axis3.x, segs: 24);
      m.mat(_lens, Finish.light);
      m.cylinder(const V3(0.634, cy, 0), 0.075, 0.004, Axis3.x, segs: 24);
      // Brackets to the forks and turn signals.
      for (final s in const [-1.0, 1.0]) {
        m.mat(_chrome, Finish.chrome);
        m.rod(
          V3(0.58, cy, s * 0.07),
          V3(0.55, cy + 0.02, s * _forkZ),
          0.008,
          segs: 6,
        );
        m.mat(_black, Finish.metal);
        m.rod(
          V3(0.56, 0.93, s * 0.1),
          V3(0.58, 0.93, s * 0.19),
          0.008,
          segs: 6,
        );
        m.mat(_amber, Finish.light);
        m.rod(
          V3(0.57, 0.93, s * 0.2),
          V3(0.615, 0.93, s * 0.2),
          0.02,
          endRadius: 0.014,
          segs: 12,
        );
      }
    },
  );

  l.add(
    'mudguard',
    'Front Mudguard',
    PartGroup.body,
    const V3(0, 1.2, 0),
    'The mudguard stops the front tyre throwing water and stones at the engine and rider.',
    ['wheel_front'],
    (m) {
      m.paint();
      m.arc(_front, 0.34, 0.35, 0.35, 2.35, -0.058, 0.058, Axis3.z, segs: 20);
    },
  );

  l.add(
    'tail',
    'Tail, Grab Rail & Taillight',
    PartGroup.lights,
    const V3(-1.2, 0.6, 0),
    'The tail holds the brake light, indicators and number plate. The chrome grab rail is for the passenger.',
    ['seat', 'wheel_rear'],
    (m) {
      m.paint();
      m.loft([
        for (final (x, y, ry, rz) in const [
          (-0.5, 0.855, 0.04, 0.125),
          (-0.7, 0.87, 0.045, 0.112),
          (-0.86, 0.885, 0.035, 0.08),
          (-0.93, 0.89, 0.022, 0.05),
        ])
          MeshBuilder.section(x, y, ry, rz, p: 2.6),
      ]);
      m.mat(_tailRed, Finish.light);
      m.loft([
        MeshBuilder.section(-0.905, 0.885, 0.025, 0.055, p: 3),
        MeshBuilder.section(-0.945, 0.885, 0.018, 0.04, p: 3),
      ]);
      // Rear mudguard and number plate.
      m.mat(_black, Finish.metal);
      m.arc(_rear, 0.345, 0.355, 1.3, 2.6, -0.055, 0.055, Axis3.z, segs: 14);
      m.rod(const V3(-0.86, 0.84, 0), const V3(-0.97, 0.66, 0), 0.012, segs: 6);
      m.mat(const Color(0xFFF1F1F1));
      m.box(-0.985, 0.58, -0.1, -0.972, 0.7, 0.1);
      for (final s in const [-1.0, 1.0]) {
        m.mat(_black, Finish.metal);
        m.rod(
          V3(-0.88, 0.8, s * 0.04),
          V3(-0.88, 0.8, s * 0.15),
          0.007,
          segs: 6,
        );
        m.mat(_amber, Finish.light);
        m.rod(
          V3(-0.87, 0.8, s * 0.16),
          V3(-0.915, 0.8, s * 0.16),
          0.018,
          endRadius: 0.013,
          segs: 12,
        );
        // Passenger grab rail.
        m.mat(_chrome, Finish.chrome);
        m.rods(
          [
            V3(-0.46, 0.87, s * 0.135),
            V3(-0.66, 0.9, s * 0.13),
            V3(-0.78, 0.905, s * 0.1),
            V3(-0.8, 0.905, 0),
          ],
          0.011,
          segs: 8,
        );
      }
    },
  );

  l.add(
    'footrests',
    'Footrests & Pedals',
    PartGroup.controls,
    const V3(0, -0.4, 1.2),
    'Footrests for rider and passenger. The right pedal works the rear brake, the left one changes gear.',
    ['engine'],
    (m) {
      for (final s in const [-1.0, 1.0]) {
        m.mat(_black, Finish.rubber);
        m.rod(
          V3(-0.03, 0.27, s * 0.12),
          V3(-0.03, 0.27, s * 0.25),
          0.016,
          segs: 10,
        );
        m.rod(
          V3(-0.47, 0.42, s * 0.12),
          V3(-0.47, 0.42, s * 0.22),
          0.013,
          segs: 10,
        );
        m.mat(_alloy, Finish.metal);
        m.rod(
          V3(-0.36, 0.38, s * 0.115),
          V3(-0.47, 0.42, s * 0.12),
          0.01,
          segs: 6,
        );
      }
      m.mat(_alloy, Finish.metal);
      m.rods(
        [
          const V3(-0.02, 0.29, 0.14),
          const V3(0.08, 0.27, 0.16),
          const V3(0.15, 0.25, 0.17),
        ],
        0.008,
        segs: 6,
      );
      m.rods(
        [
          const V3(0.03, 0.3, -0.15),
          const V3(0.1, 0.33, -0.17),
          const V3(0.16, 0.33, -0.18),
        ],
        0.008,
        segs: 6,
      );
    },
  );

  l.add(
    'kickstand',
    'Side Stand',
    PartGroup.frame,
    const V3(0, -0.6, -1),
    'The side stand swings down on the left so the bike can lean safely when parked.',
    ['frame'],
    (m) {
      m.mat(_frameBlack, Finish.metal);
      m.rod(
        const V3(-0.06, 0.2, -0.09),
        const V3(-0.22, 0.02, -0.26),
        0.014,
        segs: 8,
      );
      m.box(-0.25, 0.0, -0.29, -0.19, 0.02, -0.23);
    },
  );

  return l.parts;
}
