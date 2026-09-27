import 'dart:async';

import 'package:flutter/material.dart';

import '../../ads/ad_service.dart';

import '../data/levels.dart';
import '../data/part.dart';
import '../data/vehicles.dart';
import '../engine/renderer.dart';
import '../l10n/strings.dart';
import '../logic/assembly.dart';
import '../settings.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/car_viewer.dart';
import '../widgets/common.dart';
import '../widgets/labels.dart';
import '../widgets/part_thumbnail.dart';

enum _ToastKind { info, placed, wrong, locked, tapped }

class _Toast {
  const _Toast(this.kind, this.part, [this.missing = const []]);
  final _ToastKind kind;
  final VehiclePart part;
  final List<VehiclePart> missing;
}

class _Popup {
  _Popup(this.id, this.at, this.text, this.color);
  final int id;
  final Offset at;
  final String text;
  final Color color;
}

/// Build a vehicle by dragging parts from the tray onto the 3D model.
class AssemblyScreen extends StatefulWidget {
  const AssemblyScreen({super.key, this.vehicle = car, this.level, this.paint});

  final Vehicle vehicle;
  final Level? level;
  final Color? paint;

  @override
  State<AssemblyScreen> createState() => _AssemblyScreenState();
}

class _AssemblyScreenState extends State<AssemblyScreen> {
  late final _car = AssemblyController(
    vehicle: widget.vehicle,
    level: widget.level,
    paint: widget.paint,
  );
  late final _view = ViewController(
    target: widget.vehicle.cameraTarget,
    distance: widget.vehicle.cameraDistance,
  );
  final _viewerKey = GlobalKey();

  _Toast? _toast;
  Timer? _toastTimer;
  final _popups = <_Popup>[];
  var _popupId = 0;
  bool _recorded = false;
  bool _newBest = false;

  Vehicle get _v => widget.vehicle;
  Level get _level => _car.level;

  @override
  void initState() {
    super.initState();
    _car.addListener(_onCarChanged);
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _car.removeListener(_onCarChanged);
    _car.dispose();
    _view.dispose();
    super.dispose();
  }

  Future<void> _onCarChanged() async {
    if (_car.isComplete && !_recorded) {
      _recorded = true;
      buzz(heavy: true);
      final best = await Progress.record(
        _v.id,
        _level.number,
        _car.stars,
        _car.score,
      );
      if (mounted) setState(() => _newBest = best);
      // Let the finish celebration show first, then an interstitial.
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (mounted) AdService.instance.showInterstitial();
    }
  }

  String _name(VehiclePart p) =>
      _level.showNames || _car.isInstalled(p.id) ? partName(_v, p) : '?';

  void _show(_Toast t) {
    _toastTimer?.cancel();
    setState(() => _toast = t);
    _toastTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _popup(Offset at, int points) {
    final p = _Popup(
      _popupId++,
      at,
      points > 0 ? '+$points' : '$points',
      points > 0 ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
    );
    setState(() => _popups.add(p));
  }

  RenderBox get _box =>
      _viewerKey.currentContext!.findRenderObject()! as RenderBox;

  void _onMove(DragTargetDetails<VehiclePart> d) {
    final local = _box.globalToLocal(d.offset);
    _car.setHover(_car.isOnTarget(d.data, local, _box.size, _view.camera));
  }

  void _onDrop(DragTargetDetails<VehiclePart> d) {
    final local = _box.globalToLocal(d.offset);
    final p = d.data;
    switch (_car.drop(p, local, _box.size, _view.camera)) {
      case DropResult.placed:
        buzz();
        _popup(local, AssemblyController.pointsRight);
        _show(_Toast(_ToastKind.placed, _car.lastInstalled!));
      case DropResult.wrongPlace:
        buzz(heavy: true);
        _popup(local, AssemblyController.pointsWrong);
        _show(_Toast(_ToastKind.wrong, p));
      case DropResult.locked:
        buzz(heavy: true);
        _popup(local, AssemblyController.pointsLocked);
        _show(_Toast(_ToastKind.locked, p, _car.missingFor(p)));
    }
  }

  void _onTapItem(int? i) {
    final p = i == null ? null : _car.partAtItem(i);
    if (p == null) {
      setState(() => _toast = null);
      return;
    }
    _show(_Toast(_ToastKind.tapped, p));
  }

  void _paintLabel(Canvas canvas, Size size, OrbitCamera cam) {
    final t = _toast;
    if (!settings.labels || t == null) return;
    if (t.kind != _ToastKind.placed && t.kind != _ToastKind.tapped) return;
    if (!_car.isInstalled(t.part.id)) return;
    paintLabels(canvas, cam, [
      Label3D(
        _car.anchorOf(t.part),
        partName(_v, t.part),
        t.part.group.color,
        strong: true,
      ),
    ]);
  }

  void _replay(Level level) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            AssemblyScreen(vehicle: _v, level: level, paint: _car.paintColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: garageGradient,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _car,
            builder: (context, _) => Column(
              children: [
                _TopBar(car: _car, view: _view),
                Expanded(child: _buildStage()),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _car.isComplete
                      ? _CompletePanel(
                          car: _car,
                          newBest: _newBest,
                          onRetry: () => _replay(_level),
                          onNext: _level.number < levels.length
                              ? () => _replay(levels[_level.number])
                              : null,
                        )
                      : _car.failed
                      ? _FailedPanel(car: _car, onRetry: () => _replay(_level))
                      : _PartsTray(
                          car: _car,
                          name: _name,
                          onTap: (p) => _show(_Toast(_ToastKind.info, p)),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStage() {
    final t = _toast;
    return DragTarget<VehiclePart>(
      onMove: _onMove,
      onLeave: (_) => _car.setHover(false),
      onAcceptWithDetails: _onDrop,
      builder: (context, candidates, _) => Stack(
        children: [
          Positioned.fill(
            child: CarViewer(
              key: _viewerKey,
              view: _view,
              items: _car.renderItems,
              style: () => _car.style,
              onTick: _car.tick,
              repaint: _car,
              overlay: _paintLabel,
              onTapItem: _onTapItem,
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 8,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: t == null || _car.isComplete
                    ? const SizedBox.shrink()
                    : _InfoCard(
                        key: ValueKey('${t.part.id}${t.kind}$_popupId'),
                        toast: t,
                        vehicle: _v,
                        showNames: _level.showNames,
                        lockHints: _level.lockIcons,
                      ),
              ),
            ),
          ),
          if (_car.installedCount == 0 && t == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: IgnorePointer(
                child: Text(
                  tr('drag_hint'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
              ),
            ),
          for (final p in _popups)
            Positioned(
              key: ValueKey(p.id),
              left: p.at.dx - 40,
              top: p.at.dy - 30,
              width: 80,
              child: IgnorePointer(
                child: _ScorePopup(
                  popup: p,
                  onDone: () => setState(() => _popups.remove(p)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScorePopup extends StatelessWidget {
  const _ScorePopup({required this.popup, required this.onDone});

  final _Popup popup;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      onEnd: onDone,
      builder: (context, t, _) => Transform.translate(
        offset: Offset(0, -50 * t),
        child: Opacity(
          opacity: (1 - t * t).clamp(0, 1),
          child: Text(
            popup.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: popup.color,
              fontSize: 26 + 6 * (1 - t),
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(blurRadius: 6, color: Colors.black)],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.car, required this.view});

  final AssemblyController car;
  final ViewController view;

  @override
  Widget build(BuildContext context) {
    final total = car.parts.length;
    final done = car.installedCount;
    return Column(
      children: [
        ScreenBar(
          title:
              '${vehicleName(car.vehicle)} · ${tr('level_n', {'n': car.level.number})}',
          subtitle: tr('parts_progress', {'d': done, 'n': total}),
          actions: [
            _ScoreChip(score: car.score),
            const SizedBox(width: 6),
            _TimeChip(car: car),
            ListenableBuilder(
              listenable: view,
              builder: (context, _) => IconButton(
                tooltip: tr('auto_rotate'),
                onPressed: view.toggleAutoRotate,
                icon: const Icon(Icons.threesixty_rounded),
                color: view.autoRotate ? AppColors.accent : null,
              ),
            ),
            IconButton(
              tooltip: tr('reset_view'),
              onPressed: view.reset,
              icon: const Icon(Icons.center_focus_strong_rounded),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: done / total),
              duration: const Duration(milliseconds: 400),
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: AppColors.card,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 16, color: AppColors.accent),
          TweenAnimationBuilder<double>(
            tween: Tween(end: score.toDouble()),
            duration: const Duration(milliseconds: 350),
            builder: (context, v, _) => Text(
              '${v.round()}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Elapsed time, or a countdown on timed levels.
class _TimeChip extends StatefulWidget {
  const _TimeChip({required this.car});

  final AssemblyController car;

  @override
  State<_TimeChip> createState() => _TimeChipState();
}

class _TimeChipState extends State<_TimeChip> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.car.remaining;
    final urgent = left != null && left.inSeconds < 15;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: urgent ? const Color(0x55EF5350) : AppColors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            left == null
                ? Icons.timer_outlined
                : Icons.hourglass_bottom_rounded,
            size: 14,
            color: urgent ? const Color(0xFFEF5350) : AppColors.muted,
          ),
          const SizedBox(width: 4),
          Text(
            formatDuration(left ?? widget.car.elapsed),
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    super.key,
    required this.toast,
    required this.vehicle,
    required this.showNames,
    required this.lockHints,
  });

  final _Toast toast;
  final Vehicle vehicle;
  final bool showNames, lockHints;

  @override
  Widget build(BuildContext context) {
    final p = toast.part;
    final name = partName(vehicle, p);
    final (
      IconData icon,
      Color color,
      String title,
      String body,
    ) = switch (toast.kind) {
      _ToastKind.placed || _ToastKind.tapped => (
        Icons.check_circle_rounded,
        p.group.color,
        toast.kind == _ToastKind.placed
            ? tr('placed_title', {'name': name})
            : name,
        partInfo(vehicle, p),
      ),
      _ToastKind.info when !showNames => (
        Icons.help_rounded,
        AppColors.accent,
        tr('mystery'),
        tr('mystery_body'),
      ),
      _ToastKind.info => (
        Icons.pan_tool_alt_rounded,
        p.group.color,
        tr('drag_me', {'name': name}),
        partInfo(vehicle, p),
      ),
      _ToastKind.wrong => (
        Icons.close_rounded,
        const Color(0xFFEF5350),
        tr('wrong_title'),
        showNames ? tr('wrong_body', {'name': name}) : tr('wrong_body_hidden'),
      ),
      _ToastKind.locked => (
        Icons.lock_rounded,
        const Color(0xFFEF5350),
        tr('locked_title', {'name': showNames ? name : tr('mystery')}),
        lockHints
            ? tr('locked_body', {
                'list': toast.missing
                    .map((m) => partName(vehicle, m))
                    .join(', '),
              })
            : tr('locked_body_hidden'),
      ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartsTray extends StatelessWidget {
  const _PartsTray({
    required this.car,
    required this.name,
    required this.onTap,
  });

  final AssemblyController car;
  final String Function(VehiclePart) name;
  final void Function(VehiclePart) onTap;

  @override
  Widget build(BuildContext context) {
    final tray = car.tray;
    final hint = car.showHint ? car.nextHint : null;
    return Container(
      height: 150,
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        scrollDirection: Axis.horizontal,
        itemCount: tray.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final p = tray[i];
          final card = _PartCard(
            part: p,
            name: name(p),
            paintColor: car.paintColor,
            locked: car.level.lockIcons && !car.canInstall(p),
            isHint: p == hint,
            onTap: () => onTap(p),
          );
          return Draggable<VehiclePart>(
            key: ValueKey(p.id),
            data: p,
            affinity: Axis.vertical,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            onDragStarted: () {
              buzz();
              car.startDrag(p);
            },
            onDragEnd: (_) => car.endDrag(),
            feedback: _DragFeedback(part: p, paintColor: car.paintColor),
            childWhenDragging: Opacity(opacity: 0.25, child: card),
            child: card,
          );
        },
      ),
    );
  }
}

/// The part image under the finger while dragging, centred on the pointer.
class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.part, required this.paintColor});

  final VehiclePart part;
  final Color paintColor;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-48, -48),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.accent, width: 2),
          boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black54)],
        ),
        padding: const EdgeInsets.all(10),
        child: PartThumbnail(part: part, paintColor: paintColor),
      ),
    );
  }
}

class _PartCard extends StatelessWidget {
  const _PartCard({
    required this.part,
    required this.name,
    required this.paintColor,
    required this.locked,
    required this.isHint,
    required this.onTap,
  });

  final VehiclePart part;
  final String name;
  final Color paintColor;
  final bool locked, isHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 96,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHint ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Opacity(
            opacity: locked ? 0.38 : 1,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: PartThumbnail(
                          part: part,
                          paintColor: paintColor,
                        ),
                      ),
                      if (locked)
                        const Positioned(
                          right: 0,
                          top: 0,
                          child: Icon(Icons.lock_rounded, size: 14),
                        ),
                      if (isHint)
                        const Positioned(
                          left: 0,
                          top: 0,
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            size: 16,
                            color: AppColors.accent,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, height: 1.15),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 3,
                  width: 24,
                  decoration: BoxDecoration(
                    color: part.group.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletePanel extends StatelessWidget {
  const _CompletePanel({
    required this.car,
    required this.newBest,
    required this.onRetry,
    required this.onNext,
  });

  final AssemblyController car;
  final bool newBest;
  final VoidCallback onRetry;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              StarRow(filled: car.stars, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('complete_title', {'v': vehicleName(car.vehicle)}),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      [
                        '${tr('score')} ${car.score}',
                        if (car.timeBonus > 0)
                          tr('time_bonus', {'n': car.timeBonus}),
                        tr('mistakes', {'n': car.mistakes}),
                        if (newBest) tr('new_best'),
                      ].join('  ·  '),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PaintPicker(selected: car.paintColor, onSelect: car.setPaint),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: outlinedStyle,
                  // Starting a drive is an ad break; stopping is instant.
                  onPressed: car.driving
                      ? car.toggleDrive
                      : () => AdService.instance.showInterstitial(
                          onDismissed: car.toggleDrive,
                        ),
                  icon: Icon(
                    car.driving
                        ? Icons.stop_rounded
                        : Icons.directions_car_rounded,
                  ),
                  label: Text(car.driving ? tr('stop') : tr('drive')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: outlinedStyle,
                  onPressed: onRetry,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(tr('retry')),
                ),
              ),
            ],
          ),
          if (onNext != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.skip_next_rounded),
                label: Text(tr('next_level')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FailedPanel extends StatelessWidget {
  const _FailedPanel({required this.car, required this.onRetry});

  final AssemblyController car;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.hourglass_empty_rounded,
            size: 36,
            color: Color(0xFFEF5350),
          ),
          const SizedBox(height: 6),
          Text(
            tr('times_up'),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          Text(
            tr('times_up_body', {
              'd': car.installedCount,
              'n': car.parts.length,
            }),
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: outlinedStyle,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.list_rounded),
                  label: Text(tr('levels')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(tr('retry')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
