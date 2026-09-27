import 'package:flutter/material.dart';

import '../logic/assembly.dart';
import '../theme.dart';

final outlinedStyle = OutlinedButton.styleFrom(
  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);

/// Row of paint colour swatches.
class PaintPicker extends StatelessWidget {
  const PaintPicker({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final Color selected;
  final ValueChanged<Color> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final c in paintColors)
          GestureDetector(
            onTap: () => onSelect(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == c ? AppColors.accent : Colors.white24,
                  width: selected == c ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Three stars, [filled] of them lit.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.filled, this.size = 22});

  final int filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: i < filled ? AppColors.accent : AppColors.muted,
            size: size,
          ),
      ],
    );
  }
}

/// Top bar with a back button, a title block and trailing actions.
class ScreenBar extends StatelessWidget {
  const ScreenBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
