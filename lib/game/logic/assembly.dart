import 'dart:math' as math;
import 'dart:ui' show Color, Offset, Size;

import 'package:flutter/foundation.dart';

import '../data/levels.dart';
import '../data/part.dart';
import '../data/rider.dart';
import '../data/road_signs.dart';
import '../data/vehicles.dart';
import '../engine/mesh.dart';
import '../engine/renderer.dart';
import '../engine/vec3.dart';

const paintColors = [
  Color(0xFFD32F2F),
  Color(0xFF1E6FD9),
  Color(0xFFFFB300),
  Color(0xFF2E7D32),
  Color(0xFFF5F5F5),
  Color(0xFF212121),
  Color(0xFFEF6C00),
  Color(0xFF7B1FA2),
];

enum DropResult { placed, wrongPlace, locked }

class _Anim {
  _Anim(this.removing, this.from, this.duration);
  final bool removing;
  final V3 from;
  final double duration;
  double t = 0;
}

/// Game state for building one vehicle at one level: which parts are
/// fitted, score, timer and the animations shown in the 3D view.
class AssemblyController extends ChangeNotifier {
  AssemblyController({this.vehicle = car, Level? level, Color? paint})
    : level = level ?? levels.first,
      parts = vehicle.build(),
      paintColor = paint ?? vehicle.defaultPaint {
    showHint = this.level.hint == HintMode.always;
    _trayOrder = [for (final p in parts) p.id];
    if (this.level.shuffle) _trayOrder.shuffle(math.Random());
  }

  static const pointsRight = 10;
  static const pointsWrong = -5;
  static const pointsLocked = -3;
  static const flyTime = 0.7;
  static const snapTime = 0.35;
  static const flashTime = 0.45;

  final Vehicle vehicle;
  final Level level;
  final List<VehiclePart> parts;
  late final Map<String, VehiclePart> _byId = {for (final p in parts) p.id: p};
  late final List<String> _trayOrder;
  late final V3 _center = Bounds.of(
    parts.expand((p) => [p.bounds.min, p.bounds.max]),
  ).center;

  final List<String> _installed = [];
  final Map<String, _Anim> _anims = {};
  List<String?> _itemIds = const [];

  Color paintColor;
  late bool showHint;
  bool driving = false;
  int score = 0;
  int timeBonus = 0;
  int mistakes = 0;
  bool failed = false;
  VehiclePart? lastInstalled;

  /// Part being dragged from the tray, and whether it is over its target.
  VehiclePart? dragging;
  bool dragHover = false;

  /// Learn mode: highlighted part and how far apart parts are pulled.
  String? focusId;
  double explode = 0;

  // Rider mesh (legs rebuilt each frame when pedalling) and how far they
  // have climbed on: 0 = away, 1 = seated.
  late final List<Face>? _riderUpper = vehicle.rider == null
      ? null
      : buildRiderUpper(vehicle.rider!);
  late final List<Face>? _riderLegs =
      vehicle.rider == null || vehicle.rider!.pedals != null
      ? null
      : buildRiderLegs(vehicle.rider!);
  double _riderT = 0;

  final Stopwatch _clock = Stopwatch();
  double _time = 0, _wheelAngle = 0, _road = 0;

  VehiclePart byId(String id) => _byId[id]!;

  bool isInstalled(String id) =>
      _installed.contains(id) && !(_anims[id]?.removing ?? false);

  int get installedCount => _installed.where(isInstalled).length;
  bool get isComplete => installedCount == parts.length && _anims.isEmpty;
  Duration get elapsed => _clock.elapsed;
  Duration? get timeLimit => level.timeLimit(parts.length);

  Duration? get remaining {
    final limit = timeLimit;
    if (limit == null) return null;
    final left = limit - _clock.elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  /// Highest possible score without the time bonus.
  int get maxScore => parts.length * pointsRight;

  int get stars {
    if (!isComplete) return 0;
    final ratio = (score - timeBonus) / maxScore;
    return ratio >= 0.9 ? 3 : (ratio >= 0.7 ? 2 : 1);
  }

  bool canInstall(VehiclePart p) =>
      !_installed.contains(p.id) && p.requires.every(isInstalled);

  List<VehiclePart> missingFor(VehiclePart p) => [
    for (final id in p.requires)
      if (!isInstalled(id)) byId(id),
  ];

  /// First part (in blueprint order) that can be fitted right now.
  VehiclePart? get nextHint {
    for (final p in parts) {
      if (canInstall(p)) return p;
    }
    return null;
  }

  /// Parts not yet fitted, in the order the tray shows them.
  List<VehiclePart> get tray {
    final left = [
      for (final id in _trayOrder)
        if (!_installed.contains(id)) byId(id),
    ];
    if (level.shuffle) return left;
    return [...left.where(canInstall), ...left.where((p) => !canInstall(p))];
  }

  void _started() {
    if (!_clock.isRunning && installedCount < parts.length && !failed) {
      _clock.start();
    }
  }

  void _add(VehiclePart p, _Anim anim) {
    _started();
    _installed.add(p.id);
    _anims[p.id] = anim;
    lastInstalled = p;
    if (installedCount == parts.length) _finish();
    notifyListeners();
  }

  void _finish() {
    _clock.stop();
    final left = remaining;
    if (left != null) {
      timeBonus = left.inSeconds;
      score += timeBonus;
    }
  }

  /// Fits [p] with a fly-in animation and no scoring (demos and tests).
  bool install(VehiclePart p) {
    if (!canInstall(p)) {
      mistakes++;
      notifyListeners();
      return false;
    }
    _add(p, _Anim(false, p.from, flyTime));
    return true;
  }

  bool _onTarget(VehiclePart slot, Offset local, OrbitCamera cam) {
    final c = slot.bounds.center;
    final screen = cam.toScreen(c);
    final radius = math.max(
      36.0,
      slot.bounds.radius * cam.scaleAt(c) * 0.55 * level.tolerance,
    );
    return (local - screen).distance <= radius;
  }

  /// Free slots [p] may fill: itself plus interchangeable parts.
  Iterable<VehiclePart> _slotsFor(VehiclePart p) => [
    p,
    if (p.kind != null)
      ...parts.where((q) => q != p && q.kind == p.kind && canInstall(q)),
  ];

  /// Screen position (viewer coordinates) of [p]'s slot, for tests and
  /// tutorials.
  Offset targetOf(VehiclePart p, Size size, OrbitCamera cam) {
    cam.prepare(size);
    return cam.toScreen(p.bounds.center);
  }

  /// Whether dropping [p] at [local] (viewer coordinates) would fit it.
  bool isOnTarget(VehiclePart p, Offset local, Size size, OrbitCamera cam) {
    if (!canInstall(p)) return false;
    cam.prepare(size);
    return _slotsFor(p).any((s) => _onTarget(s, local, cam));
  }

  /// Handles a part dropped on the 3D view and updates the score.
  DropResult drop(VehiclePart p, Offset local, Size size, OrbitCamera cam) {
    dragging = null;
    dragHover = false;
    if (failed || installedCount == parts.length) return DropResult.wrongPlace;
    _started();
    if (!canInstall(p)) {
      score += pointsLocked;
      mistakes++;
      notifyListeners();
      return DropResult.locked;
    }
    cam.prepare(size);
    for (final slot in _slotsFor(p)) {
      if (!_onTarget(slot, local, cam)) continue;
      final c = slot.bounds.center;
      final (_, _, depth) = cam.project(c);
      final start = cam.unproject(local, depth) - c;
      score += pointsRight;
      _add(slot, _Anim(false, start, snapTime));
      return DropResult.placed;
    }
    score += pointsWrong;
    mistakes++;
    notifyListeners();
    return DropResult.wrongPlace;
  }

  void startDrag(VehiclePart p) {
    dragging = p;
    dragHover = false;
    notifyListeners();
  }

  void setHover(bool hover) {
    if (hover == dragHover) return;
    dragHover = hover;
    notifyListeners();
  }

  void endDrag() {
    if (dragging == null) return;
    dragging = null;
    dragHover = false;
    notifyListeners();
  }

  /// Removes the most recently fitted part.
  void undo() {
    for (final id in _installed.reversed) {
      if (_anims[id]?.removing ?? false) continue;
      _anims[id] = _Anim(true, byId(id).from, flyTime);
      driving = false;
      lastInstalled = null;
      notifyListeners();
      return;
    }
  }

  /// Fits every part instantly (showroom and learn mode).
  void installAll() {
    _installed
      ..clear()
      ..addAll(parts.map((p) => p.id));
    _anims.clear();
    notifyListeners();
  }

  void setPaint(Color c) {
    paintColor = c;
    notifyListeners();
  }

  void toggleDrive() {
    driving = !driving;
    notifyListeners();
  }

  void setFocus(String? id) {
    focusId = id;
    notifyListeners();
  }

  void setExplode(double v) {
    explode = v;
    notifyListeners();
  }

  /// Part drawn as item [index] of the last [renderItems] call.
  VehiclePart? partAtItem(int index) {
    if (index < 0 || index >= _itemIds.length) return null;
    final id = _itemIds[index];
    return id == null ? null : byId(id);
  }

  /// Where a part's name label points, including exploded offset.
  V3 anchorOf(VehiclePart p) => p.bounds.center + _explodeOffset(p);

  V3 _explodeOffset(VehiclePart p) =>
      explode == 0 ? V3.zero : (p.bounds.center - _center) * (explode * 0.9);

  /// Advances animations. Returns true while the scene needs repainting.
  bool tick(double dt) {
    _time += dt;
    var structural = false;
    final done = <String>[];
    _anims.forEach((id, a) {
      a.t += dt;
      final end = a.removing ? a.duration : a.duration + flashTime;
      if (a.t >= end) done.add(id);
    });
    for (final id in done) {
      if (_anims.remove(id)!.removing) _installed.remove(id);
      structural = true;
    }
    final limit = timeLimit;
    if (!failed &&
        limit != null &&
        _clock.isRunning &&
        _clock.elapsed >= limit &&
        installedCount < parts.length) {
      failed = true;
      _clock.stop();
      structural = true;
    }
    final riderTarget = driving ? 1.0 : 0.0;
    final riderMoving = _riderT != riderTarget;
    if (riderMoving) {
      _riderT = riderTarget > _riderT
          ? math.min(1.0, _riderT + dt / 0.7)
          : math.max(0.0, _riderT - dt / 0.5);
    }
    if (driving) {
      final speed = 3.2 * vehicle.groundScale;
      _road += dt * speed;
      _wheelAngle += dt * speed / vehicle.wheelRadius;
    }
    if (structural) notifyListeners();
    return _anims.isNotEmpty ||
        driving ||
        riderMoving ||
        done.isNotEmpty ||
        dragging != null ||
        focusId != null ||
        (showHint && nextHint != null);
  }

  SceneStyle get style => SceneStyle(
    paintColor: paintColor,
    shadow: _installed.isNotEmpty,
    groundScale: vehicle.groundScale,
    shadowSize: vehicle.shadowSize,
    roadScroll: driving ? -_road : null,
    contacts: [
      for (final id in _installed)
        if (byId(id).group == PartGroup.wheels && !_anims.containsKey(id))
          _contact(byId(id)),
    ],
  );

  (V3, double, double) _contact(VehiclePart p) {
    final b = p.bounds;
    final c = b.center + _explodeOffset(p);
    return (
      V3(c.x, 0.004, c.z),
      (b.max.x - b.min.x) * 0.32,
      (b.max.z - b.min.z) * 0.7 + 0.03,
    );
  }

  List<RenderItem> renderItems() {
    final out = <RenderItem>[];
    final ids = <String?>[];
    final bounce = driving ? math.sin(_time * 26) * 0.008 : 0.0;
    final pulse = 0.5 + 0.5 * math.sin(_time * 4);
    for (final id in _installed) {
      final p = byId(id);
      final a = _anims[id];
      var offset = _explodeOffset(p);
      var alpha = 1.0, glow = 0.0;
      if (a != null) {
        final t = (a.t / a.duration).clamp(0.0, 1.0);
        if (a.removing) {
          offset = offset + a.from * (t * t * t);
          alpha = 1 - t;
        } else {
          offset = offset + a.from * math.pow(1 - t, 3).toDouble();
          if (a.t > a.duration) glow = 1 - (a.t - a.duration) / flashTime;
        }
      }
      if (focusId != null) {
        if (id == focusId) {
          glow = 0.15 + 0.25 * pulse;
        } else {
          alpha *= 0.14;
        }
      }
      if (p.pivot == null) offset = offset + V3(0, bounce, 0);
      out.add(
        RenderItem(
          p.faces,
          offset: offset,
          alpha: alpha,
          glow: glow,
          pivot: p.pivot,
          spin: p.pivot != null ? -_wheelAngle * p.spinRatio : 0,
        ),
      );
      ids.add(id);
    }

    _addRoadSigns(out, ids);
    _addRider(out, ids, bounce);

    final drag = dragging;
    if (drag != null && level.hint != HintMode.none) {
      for (final slot in _slotsFor(drag)) {
        if (!canInstall(slot)) continue;
        out.add(
          RenderItem(
            slot.faces,
            ghost: true,
            alpha: dragHover ? 0.55 : 0.2 + 0.15 * pulse,
            ghostColor: dragHover ? const Color(0xFF66BB6A) : null,
          ),
        );
        ids.add(null);
      }
    } else if (drag == null && showHint) {
      final hint = nextHint;
      if (hint != null) {
        out.add(
          RenderItem(hint.faces, ghost: true, alpha: 0.18 + 0.16 * pulse),
        );
        ids.add(null);
      }
    }
    _itemIds = ids;
    return out;
  }

  /// Traffic signs along the far roadside, scrolling with the road while
  /// driving so the vehicle seems to pass them.
  void _addRoadSigns(List<RenderItem> out, List<String?> ids) {
    if (!driving) return;
    final s = vehicle.groundScale;
    final r = 3.4 * s; // turntable radius (see the renderer)
    final z = -2.25 * s; // beyond the far road stripe
    final lim = math.sqrt(r * r - z * z) - 0.15 * s;
    const kinds = RoadSignKind.values;
    final spacing = 2.6 * s;
    final loop = spacing * kinds.length;
    for (var i = 0; i < kinds.length; i++) {
      // Wrap into [-loop/2, loop/2) and move backwards as the road scrolls.
      final x = ((i * spacing - _road) % loop + loop) % loop - loop / 2;
      if (x.abs() > lim) continue;
      // Fade in/out near the turntable edge instead of popping.
      final edge = ((lim - x.abs()) / (0.5 * s)).clamp(0.0, 1.0);
      out.add(
        RenderItem(roadSign(kinds[i], s), offset: V3(x, 0, z), alpha: edge),
      );
      ids.add(null);
    }
  }

  void _addRider(List<RenderItem> out, List<String?> ids, double bounce) {
    final pose = vehicle.rider, upper = _riderUpper;
    if (pose == null || upper == null || _riderT <= 0) return;
    // Climbs on from the left side.
    final ease = 1 - math.pow(1 - _riderT, 3).toDouble();
    final offset = V3(0, bounce, -1.3 * vehicle.groundScale * (1 - ease));
    final alpha = math.min(1.0, _riderT * 2);
    final pedals = pose.pedals;
    final legs = pedals == null
        ? _riderLegs!
        : buildRiderLegs(pose, spin: -_wheelAngle * pedals.spinRatio);
    for (final faces in [upper, legs]) {
      out.add(RenderItem(faces, offset: offset, alpha: alpha));
      ids.add(null);
    }
  }
}
