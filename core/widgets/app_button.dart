import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  gradient,
  danger,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.trailingIcon,
    this.width,
    this.gradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final IconData? trailingIcon;
  final double? width;
  final LinearGradient? gradient;

  double get _height {
    switch (size) {
      case AppButtonSize.small:
        return 34;
      case AppButtonSize.medium:
        return 40;
      case AppButtonSize.large:
        return 46;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppButtonSize.small:
        return 12.5;
      case AppButtonSize.medium:
        return 13.5;
      case AppButtonSize.large:
        return 14.5;
    }
  }

  double get _iconSize {
    switch (size) {
      case AppButtonSize.small:
        return 14;
      case AppButtonSize.medium:
        return 16;
      case AppButtonSize.large:
        return 18;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool effectiveDisabled = isDisabled || isLoading || onPressed == null;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.gradient:
        bg = effectiveDisabled ? AppColors.slate300 : AppColors.primary;
        fg = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bg = effectiveDisabled ? AppColors.slate100 : AppColors.slate100;
        fg = effectiveDisabled ? AppColors.slate400 : AppColors.slate800;
        border = BorderSide(color: AppColors.slate200, width: 1);
        break;
      case AppButtonVariant.outlined:
        bg = Colors.transparent;
        fg = effectiveDisabled ? AppColors.slate400 : AppColors.slate700;
        border = BorderSide(
          color: effectiveDisabled ? AppColors.slate200 : AppColors.slate300,
          width: 1,
        );
        break;
      case AppButtonVariant.text:
        bg = Colors.transparent;
        fg = effectiveDisabled ? AppColors.slate400 : AppColors.primary;
        break;
      case AppButtonVariant.danger:
        bg = effectiveDisabled ? AppColors.slate200 : AppColors.criticalBg;
        fg = effectiveDisabled ? AppColors.slate400 : AppColors.critical;
        border = BorderSide(
          color: effectiveDisabled ? AppColors.slate200 : AppColors.criticalBorder,
          width: 1,
        );
        break;
    }

    Widget content = Row(
      mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: _iconSize, color: fg),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
            color: fg,
            letterSpacing: 0.1,
          ),
        ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: 6),
          Icon(trailingIcon, size: _iconSize, color: fg),
        ],
      ],
    );

    return SizedBox(
      height: _height,
      width: width,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        child: InkWell(
          onTap: effectiveDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
          child: Container(
            padding: _padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDesign.radiusMd),
              border: border != BorderSide.none
                  ? Border.fromBorderSide(border)
                  : null,
            ),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
