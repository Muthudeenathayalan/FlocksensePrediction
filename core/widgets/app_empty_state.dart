import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onButtonPressed,
    this.secondaryButtonLabel,
    this.onSecondaryButtonPressed,
    this.icon = Icons.inbox_outlined,
    this.iconColor,
  });

  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryButtonPressed;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.slate400;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: effectiveIconColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
            ),
            if (buttonLabel != null || secondaryButtonLabel != null) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (secondaryButtonLabel != null) ...[
                    AppButton(
                      label: secondaryButtonLabel!,
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.small,
                      onPressed: onSecondaryButtonPressed,
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (buttonLabel != null)
                    AppButton(
                      label: buttonLabel!,
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.small,
                      onPressed: onButtonPressed,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
