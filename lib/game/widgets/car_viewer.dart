import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../engine/renderer.dart';
import '../engine/vec3.dart';

/// Camera state shared between the viewer and the screen's toolbar.
class ViewController extends ChangeNotifier {
  ViewController({V3 target = const V3(0, 0.75, 0), double distance = 9})
    : camera = OrbitCamera(target: target, distance: distance);

  final OrbitCamera camera;
  bool autoRotate = false;

  /// Points the camera at a different subject (e.g. another vehicle).
  void frame(V3 target, double distance) {
    camera
      ..target = target
      ..distance = distance;
    notifyListeners();
  }

  double? _toYaw, _toPitch, _toZoom;

  void toggleAutoRotate() {
    autoRotate = !autoRotate;
    notifyListeners();
  }

  /// Smoothly returns to the default view.
  void reset() {
    // Take the short way round from the current yaw.
    const full = math.pi * 2;
    final y = camera.yaw;
    _toYaw =
        OrbitCamera.homeYaw +
        ((y - OrbitCamera.homeYaw) / full).roundToDouble() * full;
    _toPitch = OrbitCamera.homePitch;
    _toZoom = 1;
    notifyListeners();
  }

  bool _stepReset(double dt) {
    if (_toYaw == null) return false;
    final k = 1 - math.exp(-8 * dt);
    final c = camera;
    c.yaw += (_toYaw! - c.yaw) * k;
    c.pitch += (_toPitch! - c.pitch) * k;
    c.zoom += (_toZoom! - c.zoom) * k;
    if ((c.yaw - _toYaw!).abs() < 0.002 &&
        (c.pitch - _toPitch!).abs() < 0.002 &&
        (c.zoom - _toZoom!).abs() < 0.002) {
      _toYaw = _toPitch = _toZoom = null;
    }
    return true;
  }

  void _cancelReset() => _toYaw = _toPitch = _toZoom = null;
}

/// Interactive 360° view: drag to orbit, pinch or scroll to zoom,
/// tap to pick a part.
class CarViewer extends StatefulWidget {
  const CarViewer({
    super.key,
    required this.view,
    required this.items,
    required this.style,
    this.onTick,
    this.repaint,
    this.onTapItem,
    this.overlay,
  });

  final ViewController view;
  final List<RenderItem> Function() items;
  final SceneStyle Function() style;

  /// Advances scene animation; return true when a repaint is needed.
  final bool Function(double dt)? onTick;
  final Listenable? repaint;

  /// Called with the index (into [items]) of the tapped item, or null.
  final void Function(int? index)? onTapItem;

  /// Extra drawing on top of the scene (name labels).
  final void Function(Canvas canvas, Size size, OrbitCamera camera)? overlay;

  @override
  State<CarViewer> createState() => _CarViewerState();
}

class _CarViewerState extends State<CarViewer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _frame = ValueNotifier<int>(0);
  Duration _last = Duration.zero;
  double _yawVel = 0;
  bool _dragging = false;
  double _startZoom = 1;
  double _idle = 0;
  ScenePick? _pick;

  OrbitCamera get _cam => widget.view.camera;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    var changed = widget.view._stepReset(dt);
    if (!_dragging) {
      _idle += dt;
      if (_yawVel.abs() > 0.01) {
        _cam.yaw += _yawVel * dt;
        _yawVel *= math.exp(-3.2 * dt);
        changed = true;
      } else if (widget.view.autoRotate && _idle > 1.2) {
        _cam.yaw += 0.4 * dt;
        changed = true;
      }
    }
    if (widget.onTick?.call(dt) ?? false) changed = true;
    if (changed) _frame.value++;
  }

  void _setZoom(double z) {
    _cam.zoom = z.clamp(0.55, 2.6);
    _frame.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) {
          widget.view._cancelReset();
          _setZoom(_cam.zoom * math.exp(-e.scrollDelta.dy / 600));
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: widget.onTapItem == null
            ? null
            : (d) => widget.onTapItem!(_pick?.hit(d.localPosition)),
        onScaleStart: (d) {
          _dragging = true;
          _yawVel = 0;
          _startZoom = _cam.zoom;
          widget.view._cancelReset();
        },
        onScaleUpdate: (d) {
          final delta = d.focalPointDelta;
          _cam.yaw -= delta.dx * 0.009;
          _cam.pitch = (_cam.pitch + delta.dy * 0.007).clamp(
            OrbitCamera.minPitch,
            OrbitCamera.maxPitch,
          );
          if (d.pointerCount > 1) {
            _cam.zoom = (_startZoom * d.scale).clamp(0.55, 2.6);
          }
          _frame.value++;
        },
        onScaleEnd: (d) {
          _dragging = false;
          _idle = 0;
          if (d.pointerCount == 0) {
            _yawVel = -d.velocity.pixelsPerSecond.dx * 0.009;
          }
        },
        child: CustomPaint(
          size: Size.infinite,
          painter: _ScenePainter(
            this,
            Listenable.merge([
              _frame,
              widget.view,
              if (widget.repaint != null) widget.repaint,
            ]),
          ),
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.state, Listenable repaint) : super(repaint: repaint);

  final _CarViewerState state;

  @override
  void paint(Canvas canvas, Size size) {
    final w = state.widget;
    state._pick = drawScene(canvas, size, w.view.camera, w.items(), w.style());
    w.overlay?.call(canvas, size, w.view.camera);
  }

  @override
  bool shouldRepaint(_ScenePainter old) => true;
}
