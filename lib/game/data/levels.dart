/// How much placement help a level gives.
enum HintMode {
  /// A glowing ghost always shows where the next part goes.
  always,

  /// The target glows only while a part is being dragged.
  onDrag,

  /// No placement help.
  none,
}

/// Difficulty settings for one level. Every vehicle has the same ladder.
class Level {
  const Level(
    this.number, {
    required this.hint,
    required this.lockIcons,
    required this.showNames,
    required this.shuffle,
    required this.tolerance,
    this.secondsPerPart,
  });

  final int number;
  final HintMode hint;

  /// Locked parts are marked in the tray.
  final bool lockIcons;

  /// Part names are shown on tray cards (always revealed once fitted).
  final bool showNames;

  /// Tray order is mixed up instead of build order.
  final bool shuffle;

  /// Scales how close to the right spot a drop must land.
  final double tolerance;
  final double? secondsPerPart;

  Duration? timeLimit(int parts) => secondsPerPart == null
      ? null
      : Duration(seconds: (parts * secondsPerPart!).round());
}

const levels = [
  Level(
    1,
    hint: HintMode.always,
    lockIcons: true,
    showNames: true,
    shuffle: false,
    tolerance: 1.6,
  ),
  Level(
    2,
    hint: HintMode.onDrag,
    lockIcons: true,
    showNames: true,
    shuffle: true,
    tolerance: 1.3,
  ),
  Level(
    3,
    hint: HintMode.none,
    lockIcons: true,
    showNames: true,
    shuffle: true,
    tolerance: 1.1,
  ),
  Level(
    4,
    hint: HintMode.none,
    lockIcons: false,
    showNames: true,
    shuffle: true,
    tolerance: 1.0,
    secondsPerPart: 10,
  ),
  Level(
    5,
    hint: HintMode.none,
    lockIcons: false,
    showNames: false,
    shuffle: true,
    tolerance: 0.85,
    secondsPerPart: 7,
  ),
];
