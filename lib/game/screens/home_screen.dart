import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../data/vehicles.dart';
import '../l10n/strings.dart';
import '../logic/assembly.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets/car_viewer.dart';
import '../widgets/common.dart';
import 'learn_screen.dart';
import 'level_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // One finished showroom model per vehicle, created on first view.
  final _models = <String, AssemblyController>{};
  Vehicle _vehicle = vehicles.first;
  late final _view = ViewController(
    target: _vehicle.cameraTarget,
    distance: _vehicle.cameraDistance,
  )..autoRotate = true;

  AssemblyController get _model => _models.putIfAbsent(
    _vehicle.id,
    () => AssemblyController(vehicle: _vehicle)
      ..showHint = false
      ..installAll(),
  );

  @override
  void dispose() {
    for (final m in _models.values) {
      m.dispose();
    }
    _view.dispose();
    super.dispose();
  }

  void _select(Vehicle v) {
    if (v == _vehicle) return;
    setState(() => _vehicle = v);
    _view.frame(v.cameraTarget, v.cameraDistance);
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {}); // refresh stars
  }

  @override
  Widget build(BuildContext context) {
    final model = _model;
    return Scaffold(
      body: DecoratedBox(
        decoration: garageGradient,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                child: Row(
                  children: [
                    // Back to the Traffic Signals app (the game is hosted
                    // inside it rather than being the root route).
                    if (Navigator.of(context, rootNavigator: true).canPop())
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                    else
                      const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('app_title'),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: AppColors.text,
                            ),
                          ),
                          Text(
                            tr('tagline'),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: tr('settings'),
                      onPressed: () => _open(const SettingsScreen()),
                      icon: const Icon(Icons.settings_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _VehiclePicker(selected: _vehicle, onSelect: _select),
              Expanded(
                child: CarViewer(
                  key: ValueKey(_vehicle.id),
                  view: _view,
                  items: model.renderItems,
                  style: () => model.style,
                  onTick: model.tick,
                  repaint: model,
                ),
              ),
              PaintPicker(
                selected: model.paintColor,
                onSelect: (c) => setState(() => model.setPaint(c)),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _Stat(
                      icon: Icons.star_rounded,
                      label: tr('stars_total'),
                      value:
                          '${Progress.totalStars(_vehicle.id)} / ${levels.length * 3}',
                    ),
                    const SizedBox(width: 12),
                    _Stat(
                      icon: Icons.flag_rounded,
                      label: tr('levels_done'),
                      value:
                          '${Progress.levelsDone(_vehicle.id)} / ${levels.length}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: outlinedStyle,
                        onPressed: () => _open(
                          LearnScreen(
                            vehicle: _vehicle,
                            paint: model.paintColor,
                          ),
                        ),
                        icon: const Icon(Icons.school_rounded),
                        label: Text(tr('learn')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _open(
                          LevelScreen(
                            vehicle: _vehicle,
                            paint: model.paintColor,
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(tr('play')),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VehiclePicker extends StatelessWidget {
  const _VehiclePicker({required this.selected, required this.onSelect});

  final Vehicle selected;
  final ValueChanged<Vehicle> onSelect;

  @override
  Widget build(BuildContext context) {
    // Scrolls sideways so more vehicles fit on narrow phones.
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: vehicles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final v = vehicles[i];
          return GestureDetector(
            onTap: () => onSelect(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 86,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: v == selected
                    ? AppColors.accent.withValues(alpha: 0.18)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: v == selected ? AppColors.accent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    v.icon,
                    size: 28,
                    color: v == selected ? AppColors.accent : AppColors.muted,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vehicleName(v),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: v == selected ? AppColors.text : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
