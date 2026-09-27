import 'dart:math' as math;

/// Minimal immutable 3D vector used by the software renderer.
///
/// World axes: +X is the car's front, +Y is up, +Z is the car's right side.
class V3 {
  const V3(this.x, this.y, this.z);

  final double x, y, z;

  static const zero = V3(0, 0, 0);

  V3 operator +(V3 o) => V3(x + o.x, y + o.y, z + o.z);
  V3 operator -(V3 o) => V3(x - o.x, y - o.y, z - o.z);
  V3 operator *(double s) => V3(x * s, y * s, z * s);
  V3 operator -() => V3(-x, -y, -z);

  double dot(V3 o) => x * o.x + y * o.y + z * o.z;
  V3 cross(V3 o) => V3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);

  double get length => math.sqrt(x * x + y * y + z * z);

  V3 get normalized {
    final l = length;
    return l == 0 ? this : this * (1 / l);
  }

  static V3 lerp(V3 a, V3 b, double t) =>
      V3(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t);

  @override
  String toString() => 'V3($x, $y, $z)';
}

/// Axis-aligned bounding box.
class Bounds {
  Bounds(this.min, this.max);

  factory Bounds.of(Iterable<V3> points) {
    var minX = double.infinity, minY = double.infinity, minZ = double.infinity;
    var maxX = -double.infinity,
        maxY = -double.infinity,
        maxZ = -double.infinity;
    for (final p in points) {
      minX = math.min(minX, p.x);
      minY = math.min(minY, p.y);
      minZ = math.min(minZ, p.z);
      maxX = math.max(maxX, p.x);
      maxY = math.max(maxY, p.y);
      maxZ = math.max(maxZ, p.z);
    }
    return Bounds(V3(minX, minY, minZ), V3(maxX, maxY, maxZ));
  }

  final V3 min, max;

  V3 get center => (min + max) * 0.5;
  double get radius => (max - min).length * 0.5;
}
