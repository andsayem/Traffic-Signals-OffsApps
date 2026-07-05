import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/theme_constants.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? customColor;
  final Color? customBorderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.customColor,
    this.customBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final cardColor = customColor ?? 
        (isDark ? ThemeConstants.darkCardColor : ThemeConstants.lightCardColor);
        
    final borderColor = customBorderColor ?? 
        (isDark ? ThemeConstants.darkBorderColor : ThemeConstants.lightBorderColor);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(borderRadius),
          child: onTap != null
              ? InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(borderRadius),
                  splashColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                  highlightColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                  child: Container(
                    padding: padding,
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: child,
                  ),
                )
              : Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: child,
                ),
        ),
      ),
    );
  }
}
