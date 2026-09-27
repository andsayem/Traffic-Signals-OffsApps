import 'dart:ui' show Color;

import '../engine/mesh.dart';
import '../engine/vec3.dart';

enum PartGroup {
  frame,
  powertrain,
  wheels,
  interior,
  controls,
  body,
  glass,
  lights,
}

extension PartGroupLabel on PartGroup {
  String get label => switch (this) {
    PartGroup.frame => 'Frame',
    PartGroup.powertrain => 'Powertrain',
    PartGroup.wheels => 'Wheels',
    PartGroup.interior => 'Interior',
    PartGroup.controls => 'Controls',
    PartGroup.body => 'Body',
    PartGroup.glass => 'Glass',
    PartGroup.lights => 'Lights',
  };

  Color get color => switch (this) {
    PartGroup.frame => const Color(0xFF90A4AE),
    PartGroup.powertrain => const Color(0xFFEF5350),
    PartGroup.wheels => const Color(0xFF78909C),
    PartGroup.interior => const Color(0xFFA1887F),
    PartGroup.controls => const Color(0xFF66BB6A),
    PartGroup.body => const Color(0xFFFFA726),
    PartGroup.glass => const Color(0xFF4FC3F7),
    PartGroup.lights => const Color(0xFFFFEE58),
  };
}

class VehiclePart {
  VehiclePart({
    required this.id,
    required this.name,
    required this.info,
    required this.group,
    required List<Face> faces,
    required this.from,
    this.requires = const [],
    this.pivot,
    this.spinRatio = 1,
    this.kind,
  }) : faces = smoothFaces(faces),
       bounds = Bounds.of(faces.expand((f) => f.pts));

  final String id, name, info;
  final PartGroup group;
  final List<Face> faces;

  /// Parts with the same kind are interchangeable (a car's four wheels):
  /// dropping one on another's free slot fits that slot.
  final String? kind;

  /// Offset the part flies in from before snapping into place.
  final V3 from;
  final List<String> requires;

  /// Centre of rotation (around Z) for parts that turn while driving.
  final V3? pivot;

  /// Turn speed relative to the wheels (bicycle cranks turn slower).
  final double spinRatio;
  final Bounds bounds;
}

List<Face> buildMesh(void Function(MeshBuilder m) build) {
  final m = MeshBuilder();
  build(m);
  return m.faces;
}

/// Collects parts for a vehicle blueprint.
class PartList {
  final parts = <VehiclePart>[];

  void add(
    String id,
    String name,
    PartGroup group,
    V3 from,
    String info,
    List<String> requires,
    void Function(MeshBuilder m) build, {
    V3? pivot,
    double spinRatio = 1,
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
        spinRatio: spinRatio,
      ),
    );
  }
}
