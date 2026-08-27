import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';

enum AppCardVariant {
  surface,
  flat,
  outlined,
  gradient,
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.elevation = 0,
    this.borderRadius = AppDesign.radiusLg,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.variant = AppCardVariant.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double elevation;
  final double borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? borderColor;
  final LinearGradient? gradient;
  final AppCardVariant variant;

  @override
  Widget build(BuildContext context) {
    Color bg = backgroundColor ?? AppColors.surface;
    BorderSide borderSide = BorderSide(
      color: borderColor ?? AppColors.border,
      width: 1,
    );
    List<BoxShadow>? shadows;

    switch (variant) {
      case AppCardVariant.surface:
        shadows = AppDesign.cardShadow;
        break;
      case AppCardVariant.flat:
        shadows = null;
        break;
      case AppCardVariant.outlined:
        bg = Colors.transparent;
        shadows = null;
        borderSide = BorderSide(
          color: borderColor ?? AppColors.borderStrong,
          width: 1,
        );
        break;
      case AppCardVariant.gradient:
        shadows = AppDesign.cardShadow;
        break;
    }

    final decoration = BoxDecoration(
      color: gradient == null ? bg : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.fromBorderSide(borderSide),
      boxShadow: shadows,
    );

    Widget cardContent = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      cardContent = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          hoverColor: AppColors.primaryLight.withOpacity(0.2),
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    if (margin != EdgeInsets.zero) {
      cardContent = Padding(padding: margin, child: cardContent);
    }

    return cardContent;
  }
}
