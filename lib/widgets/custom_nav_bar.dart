import 'package:flutter/material.dart';
import '../utils/translations.dart';
import '../utils/theme_constants.dart';
import 'glass_card.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // One colour per tab, echoing the traffic-light theme.
  static const _items = [
    _NavBarItem(
      icon: Icons.home_rounded,
      labelKey: 'home',
      color: ThemeConstants.signalRed,
    ),
    _NavBarItem(
      icon: Icons.quiz_rounded,
      labelKey: 'quiz',
      color: ThemeConstants.signalOrange,
    ),
    _NavBarItem(
      icon: Icons.favorite_rounded,
      labelKey: 'favorites',
      color: ThemeConstants.signalGreen,
    ),
    _NavBarItem(
      icon: Icons.settings_rounded,
      labelKey: 'settings',
      color: ThemeConstants.signalBlue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final inactive = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          borderRadius: 26,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = index == currentIndex;
              // Every tab always shows its label so new users can tell
              // what each one does; the active tab gets a coloured pill.
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? item.color.withValues(alpha: 0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.12 : 1,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            item.icon,
                            color: selected ? item.color : inactive,
                            size: 23,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.tr(item.labelKey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: selected ? item.color : inactive,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem {
  final IconData icon;
  final String labelKey;
  final Color color;

  const _NavBarItem({
    required this.icon,
    required this.labelKey,
    required this.color,
  });
}
