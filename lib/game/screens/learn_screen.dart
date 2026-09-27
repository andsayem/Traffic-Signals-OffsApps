import 'package:flutter/material.dart';

import '../data/part.dart';
import '../data/vehicles.dart';
import '../engine/renderer.dart';
import '../l10n/strings.dart';
import '../logic/assembly.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets/car_viewer.dart';
import '../widgets/common.dart';
import '../widgets/labels.dart';
import '../widgets/part_thumbnail.dart';

/// Explore a finished vehicle: tap parts to learn their names and jobs,
/// pull the vehicle apart with the exploded view.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key, required this.vehicle, required this.paint});

  final Vehicle vehicle;
  final Color paint;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late final _car = AssemblyController(
    vehicle: widget.vehicle,
    paint: widget.paint,
  )..installAll();
  late final _view = ViewController(
    target: widget.vehicle.cameraTarget,
    distance: widget.vehicle.cameraDistance,
  );
  final _list = ScrollController();
  // All-name labels crowd larger vehicles, so they start off for the car.
  late bool _allNames = settings.labels && _car.parts.length <= 16;
  VehiclePart? _selected;

  @override
  void initState() {
    super.initState();
    _car.showHint = false;
  }

  @override
  void dispose() {
    _car.dispose();
    _view.dispose();
    _list.dispose();
    super.dispose();
  }

  void _select(VehiclePart? p) {
    buzz();
    setState(() => _selected = p == _selected ? null : p);
    _car.setFocus(_selected?.id);
    final i = p == null ? -1 : _car.parts.indexOf(p);
    if (i >= 0 && _list.hasClients) {
      _list.animateTo(
        (i * 96.0 - 120).clamp(0, _list.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _paintLabels(Canvas canvas, Size size, OrbitCamera cam) {
    final v = widget.vehicle;
    final sel = _selected;
    paintLabels(canvas, cam, [
      if (_allNames && sel == null)
        for (final p in _car.parts)
          Label3D(_car.anchorOf(p), partName(v, p), p.group.color),
      if (sel != null)
        Label3D(
          _car.anchorOf(sel),
          partName(v, sel),
          sel.group.color,
          strong: true,
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final sel = _selected;
    return Scaffold(
      body: DecoratedBox(
        decoration: garageGradient,
        child: SafeArea(
          child: Column(
            children: [
              ScreenBar(
                title: tr('learn_title', {'v': vehicleName(v)}),
                subtitle: tr('parts_count', {'n': _car.parts.length}),
                actions: [
                  IconButton(
                    tooltip: tr('all_names'),
                    onPressed: () => setState(() => _allNames = !_allNames),
                    icon: Icon(
                      _allNames ? Icons.label_rounded : Icons.label_off_rounded,
                    ),
                    color: _allNames ? AppColors.accent : null,
                  ),
                  ListenableBuilder(
                    listenable: _view,
                    builder: (context, _) => IconButton(
                      tooltip: tr('auto_rotate'),
                      onPressed: _view.toggleAutoRotate,
                      icon: const Icon(Icons.threesixty_rounded),
                      color: _view.autoRotate ? AppColors.accent : null,
                    ),
                  ),
                  IconButton(
                    tooltip: tr('reset_view'),
                    onPressed: _view.reset,
                    icon: const Icon(Icons.center_focus_strong_rounded),
                  ),
                ],
              ),
              Expanded(
                child: CarViewer(
                  view: _view,
                  items: _car.renderItems,
                  style: () => _car.style,
                  onTick: _car.tick,
                  repaint: _car,
                  overlay: _paintLabels,
                  onTapItem: (i) =>
                      _select(i == null ? null : _car.partAtItem(i)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.open_in_full_rounded,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr('explode'),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    Expanded(
                      child: Slider(
                        value: _car.explode,
                        onChanged: (x) => setState(() => _car.setExplode(x)),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                constraints: const BoxConstraints(minHeight: 96),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: sel?.group.color ?? Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: sel == null
                    ? Row(
                        children: [
                          const Icon(
                            Icons.touch_app_rounded,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tr('learn_hint'),
                              style: const TextStyle(
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  partName(v, sel),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: sel.group.color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  groupName(sel.group),
                                  style: TextStyle(
                                    color: sel.group.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            partInfo(v, sel),
                            style: const TextStyle(
                              color: AppColors.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
              ),
              SizedBox(
                height: 118,
                child: ListView.separated(
                  controller: _list,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: _car.parts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final p = _car.parts[i];
                    final on = p == sel;
                    return GestureDetector(
                      onTap: () => _select(p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 88,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: on
                              ? p.group.color.withValues(alpha: 0.2)
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: on ? p.group.color : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: PartThumbnail(
                                part: p,
                                paintColor: _car.paintColor,
                              ),
                            ),
                            Text(
                              partName(v, p),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
