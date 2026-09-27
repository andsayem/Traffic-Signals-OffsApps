import 'dart:math' as math;
import 'dart:ui' show Color;

import '../engine/mesh.dart';
import '../engine/vec3.dart';
import 'part.dart';

// Materials
const _tire = Color(0xFF1C1D20);
const _chrome = Color(0xFFD5DAE0);
const _metal = Color(0xFF8C939C);
const _dark = Color(0xFF2A2D33);
const _saddle = Color(0xFF26211F);
const _grip = Color(0xFF3A2E2A);
const _bottle = Color(0xFF29B6F6);

// Frame geometry (metres). X forward, Y up, Z right.
const _wheelR = 0.34;
const _rearAxle = V3(-0.52, _wheelR, 0);
const _frontAxle = V3(0.54, _wheelR, 0);
const _bb = V3(0, 0.28, 0); // bottom bracket
const _seatTop = V3(-0.15, 0.84, 0);
const _headTop = V3(0.39, 0.84, 0);
const _headBottom = V3(0.44, 0.68, 0);
const _chainZ = 0.075;

List<Face> _wheel(V3 c) => buildMesh((m) {
  m.mat(_tire, Finish.rubber);
  m.ring(c, 0.32, 0.024, Axis3.z, segs: 32);
  m.mat(_chrome, Finish.chrome);
  m.ring(c, 0.285, 0.012, Axis3.z, segs: 32);
  m.cylinder(c, 0.028, 0.11, Axis3.z, segs: 10);
  m.mat(_metal, Finish.metal);
  for (var k = 0; k < 16; k++) {
    final z = k.isEven ? 0.02 : -0.02;
    m.spokeZ(
      c,
      k / 16 * math.pi * 2,
      0.025,
      0.28,
      0.0035,
      z - 0.003,
      z + 0.003,
    );
  }
});

List<VehiclePart> buildBicycle() {
  final l = PartList();

  l.add(
    'frame',
    'Frame',
    PartGroup.frame,
    const V3(0, 1.6, 0),
    'The diamond frame is two triangles of steel tube - light, stiff and strong.',
    [],
    (m) {
      m.paint();
      m.rod(
        _headTop + const V3(0, -0.03, 0),
        _seatTop + const V3(0, -0.03, 0),
        0.02,
      );
      m.rod(_headBottom, _bb, 0.024);
      m.rod(_bb, _seatTop, 0.02);
      m.rod(
        _headTop + const V3(0.01, 0.02, 0),
        _headBottom + const V3(0, -0.02, 0),
        0.026,
      );
      for (final s in const [-1.0, 1.0]) {
        final drop = _rearAxle + V3(0, 0, s * 0.055);
        m.rod(_bb + V3(0, 0, s * 0.03), drop, 0.012);
        m.rod(_seatTop + V3(0, -0.04, s * 0.02), drop, 0.011);
      }
      m.mat(_dark, Finish.metal);
      m.cylinder(_bb, 0.03, 0.09, Axis3.z, segs: 10);
    },
  );

  l.add(
    'fork',
    'Front Fork',
    PartGroup.frame,
    const V3(1.2, 0.6, 0),
    'The fork holds the front wheel and turns inside the head tube when you steer.',
    ['frame'],
    (m) {
      m.mat(_chrome, Finish.chrome);
      final crown = _headBottom + const V3(0.005, -0.03, 0);
      m.box(
        crown.x - 0.03,
        crown.y - 0.02,
        -0.06,
        crown.x + 0.03,
        crown.y + 0.015,
        0.06,
      );
      for (final s in const [-1.0, 1.0]) {
        m.rod(
          crown + V3(0, 0, s * 0.05),
          _frontAxle + V3(0, 0, s * 0.05),
          0.012,
        );
      }
    },
  );

  l.add(
    'wheel_front',
    'Front Wheel',
    PartGroup.wheels,
    const V3(0, 0.1, 1.4),
    'Thin steel spokes pulled tight hold the rim perfectly round around the hub.',
    ['fork'],
    (m) => m.faces.addAll(_wheel(_frontAxle)),
    pivot: _frontAxle,
  );

  l.add(
    'wheel_rear',
    'Rear Wheel',
    PartGroup.wheels,
    const V3(0, 0.1, -1.4),
    'The rear wheel is driven by the chain. Its gear cogs sit on the right side of the hub.',
    ['frame'],
    (m) {
      m.faces.addAll(_wheel(_rearAxle));
      m.mat(_metal, Finish.metal);
      m.cylinder(
        _rearAxle + const V3(0, 0, _chainZ),
        0.045,
        0.012,
        Axis3.z,
        segs: 14,
      );
    },
    pivot: _rearAxle,
  );

  l.add(
    'crankset',
    'Crank & Pedals',
    PartGroup.powertrain,
    const V3(0, -0.2, 1.3),
    'Pushing the pedals turns the cranks and the big chainring - your legs are the engine!',
    ['frame'],
    (m) {
      m.mat(_metal, Finish.metal);
      m.cylinder(_bb + const V3(0, 0, _chainZ), 0.1, 0.01, Axis3.z, segs: 24);
      m.mat(_dark, Finish.metal);
      m.cylinder(_bb, 0.015, 0.2, Axis3.z, segs: 8);
      for (final s in const [-1.0, 1.0]) {
        final end = _bb + V3(0, s * 0.16, s * 0.095);
        m.rod(_bb + V3(0, 0, s * 0.095), end, 0.012);
        m.mat(_dark);
        m.box(
          end.x - 0.045,
          end.y - 0.012,
          end.z,
          end.x + 0.045,
          end.y + 0.012,
          end.z + s * 0.09,
        );
        m.mat(_dark, Finish.metal);
      }
    },
    pivot: _bb,
    spinRatio: 0.45,
  );

  l.add(
    'chain',
    'Chain',
    PartGroup.powertrain,
    const V3(-0.8, 0.8, 0),
    'The chain carries your pedalling power from the chainring to the rear wheel cog.',
    ['crankset', 'wheel_rear'],
    (m) {
      m.mat(const Color(0xFF55595F), Finish.metal);
      const z = V3(0, 0, _chainZ + 0.008);
      m.rod(
        _bb + const V3(0, 0.1, 0) + z,
        _rearAxle + const V3(0, 0.045, 0) + z,
        0.006,
        segs: 5,
      );
      m.rod(
        _bb + const V3(0, -0.1, 0) + z,
        _rearAxle + const V3(0, -0.045, 0) + z,
        0.006,
        segs: 5,
      );
    },
  );

  l.add(
    'handlebar',
    'Handlebar',
    PartGroup.controls,
    const V3(0.3, 1.2, 0),
    'The handlebar steers the front wheel and carries the brake levers and bell.',
    ['fork'],
    (m) {
      m.mat(_chrome, Finish.chrome);
      const bar = V3(0.36, 0.96, 0);
      m.rod(_headTop, bar, 0.014);
      m.cylinder(bar, 0.012, 0.52, Axis3.z, segs: 8);
      m.mat(_grip, Finish.rubber);
      for (final s in const [-1.0, 1.0]) {
        m.cylinder(bar + V3(0, 0, s * 0.23), 0.017, 0.1, Axis3.z, segs: 8);
      }
      m.mat(_dark);
      for (final s in const [-1.0, 1.0]) {
        m.rod(
          bar + V3(0.01, 0, s * 0.17),
          bar + V3(0.09, -0.03, s * 0.2),
          0.006,
          segs: 5,
        );
      }
      m.mat(_chrome, Finish.chrome);
      m.cylinder(
        bar + const V3(0, 0.025, -0.1),
        0.022,
        0.02,
        Axis3.y,
        segs: 10,
      );
    },
  );

  l.add(
    'saddle',
    'Saddle',
    PartGroup.controls,
    const V3(-0.3, 1.2, 0),
    'The saddle slides up and down on the seat post so the rider\'s legs can stretch fully.',
    ['frame'],
    (m) {
      m.mat(_chrome, Finish.chrome);
      const top = V3(-0.19, 0.97, 0);
      m.rod(_seatTop, top, 0.013);
      m.mat(_saddle);
      m.hexa([
        const V3(-0.3, 0.97, -0.08),
        const V3(-0.02, 0.975, -0.025),
        const V3(-0.02, 1.0, -0.025),
        const V3(-0.3, 1.02, -0.08),
        const V3(-0.3, 0.97, 0.08),
        const V3(-0.02, 0.975, 0.025),
        const V3(-0.02, 1.0, 0.025),
        const V3(-0.3, 1.02, 0.08),
      ]);
    },
  );

  l.add(
    'brakes',
    'Brakes',
    PartGroup.controls,
    const V3(0, 1.2, 0),
    'Squeezing a lever pulls a cable that presses rubber pads against the wheel rim.',
    ['wheel_front', 'wheel_rear', 'handlebar'],
    (m) {
      m.mat(_dark);
      for (final c in [
        _headBottom + const V3(0.02, -0.07, 0),
        _rearAxle + const V3(0.05, 0.3, 0),
      ]) {
        m.box(c.x - 0.02, c.y - 0.04, -0.045, c.x + 0.02, c.y + 0.02, 0.045);
      }
      m.rod(
        const V3(0.42, 0.93, 0.18),
        _headBottom + const V3(0.03, -0.05, 0),
        0.004,
        segs: 4,
      );
      m.rod(
        const V3(0.42, 0.93, -0.18),
        const V3(0.2, 0.78, 0.02),
        0.004,
        segs: 4,
      );
      m.rod(
        const V3(0.2, 0.78, 0.02),
        _rearAxle + const V3(0.06, 0.31, 0.03),
        0.004,
        segs: 4,
      );
    },
  );

  l.add(
    'mudguards',
    'Mudguards',
    PartGroup.body,
    const V3(0, 1.4, 0),
    'Mudguards stop water and mud from spraying up onto the rider.',
    ['wheel_front', 'wheel_rear'],
    (m) {
      m.paint();
      m.arc(_frontAxle, 0.365, 0.375, 0.35, 2.3, -0.035, 0.035, Axis3.z);
      m.arc(_rearAxle, 0.365, 0.375, 0.9, 3.1, -0.035, 0.035, Axis3.z);
    },
  );

  l.add(
    'bottle',
    'Water Bottle',
    PartGroup.body,
    const V3(0.3, 1.2, 0.6),
    'A bottle cage on the down tube keeps water within reach on long rides.',
    ['frame'],
    (m) {
      final d = (_bb - _headBottom).normalized;
      final n = V3(d.y, -d.x, 0); // perpendicular, pointing up/back
      final c = (_bb + _headBottom) * 0.5 + n * 0.055;
      m.mat(_bottle);
      m.rod(c - d * 0.1, c + d * 0.1, 0.034, segs: 10);
      m.mat(_dark);
      m.rod(c - d * 0.1, c - d * 0.125, 0.018, segs: 8);
    },
  );

  l.add(
    'kickstand',
    'Kickstand',
    PartGroup.frame,
    const V3(0, -0.5, -1),
    'The kickstand flips down so the bike can stand on its own when parked.',
    ['frame'],
    (m) {
      m.mat(_dark, Finish.metal);
      m.rod(const V3(-0.1, 0.28, -0.05), const V3(-0.24, 0.01, -0.16), 0.012);
    },
  );

  l.add(
    'lights',
    'Lights & Bell',
    PartGroup.lights,
    const V3(1, 0.8, 0),
    'A white front lamp and red rear reflector help others see you at night.',
    ['handlebar', 'saddle'],
    (m) {
      m.mat(_dark);
      m.cylinder(const V3(0.44, 0.9, 0), 0.035, 0.06, Axis3.x, segs: 12);
      m.mat(const Color(0xFFFFF6D5), Finish.light);
      m.cylinder(const V3(0.475, 0.9, 0), 0.03, 0.01, Axis3.x, segs: 12);
      m.mat(const Color(0xFFE53935), Finish.light);
      m.box(-0.2, 0.86, -0.025, -0.185, 0.9, 0.025);
    },
  );

  return l.parts;
}
