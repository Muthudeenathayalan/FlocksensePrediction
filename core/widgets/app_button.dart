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

/// Agronex-Inspired Stadium Pill Button Component
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
        return 42;
      case AppButtonSize.large:
        return 48;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppButtonSize.small:
        return 12.0;
      case AppButtonSize.medium:
        return 13.0;
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
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 6);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 9);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
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
        bg = effectiveDisabled ? AppColors.slate200 : AppColors.primary;
        fg = effectiveDisabled ? AppColors.slate400 : AppColors.onPrimary;
        break;
      case AppButtonVariant.secondary:
        bg = effectiveDisabled ? AppColors.slate200 : AppColors.primaryDark;
        fg = effectiveDisabled ? AppColors.slate400 : Colors.white;
        break;
      case AppButtonVariant.outlined:
        bg = Colors.transparent;
        fg = effectiveDisabled ? AppColors.slate400 : AppColors.textPrimary;
        border = BorderSide(
          color: effectiveDisabled ? AppColors.slate200 : AppColors.border,
          width: 1.2,
        );
        break;
      case AppButtonVariant.danger:
        bg = effectiveDisabled ? AppColors.slate200 : AppColors.critical;
        fg = effectiveDisabled ? AppColors.slate400 : Colors.white;
        break;
      case AppButtonVariant.text:
        bg = Colors.transparent;
        fg = effectiveDisabled ? AppColors.slate400 : AppColors.textPrimary;
        break;
    }

    final child = Row(
      mainAxisSize: width != null ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(width: 7),
        ],
        Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: _fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            decoration: TextDecoration.none,
          ),
        ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: 7),
          Icon(trailingIcon, size: _iconSize, color: fg),
        ],
      ],
    );

    return SizedBox(
      height: _height,
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: effectiveDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppDesign.radiusPill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: _padding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppDesign.radiusPill),
              border: border != BorderSide.none ? Border.fromBorderSide(border) : null,
              boxShadow: (variant == AppButtonVariant.primary && !effectiveDisabled)
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
