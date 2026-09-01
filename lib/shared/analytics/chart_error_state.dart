import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/widgets/app_button.dart';

/// Clean error state for analytical charts with retry mechanism
class ChartErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final double height;

  const ChartErrorState({
    super.key,
    this.title = 'Unable to load analytics',
    this.message = 'Please check your connection and try again.',
    this.onRetry,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.critical.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDesign.radiusMd),
            ),
            child: const Icon(Icons.error_outline_rounded, size: 22, color: AppColors.critical),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
            ),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slate500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            AppButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              size: AppButtonSize.small,
              variant: AppButtonVariant.outlined,
              onPressed: onRetry!,
            ),
          ],
        ],
      ),
    );
  }
}
