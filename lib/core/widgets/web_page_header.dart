import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_typography.dart';

/// Agronex-Inspired Web Page Header for FlockSense
/// Features clean, bold geometric typography, metadata subtitle, and stadium pill action buttons.
class WebPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? breadcrumb;
  final List<Widget>? actions;
  final Widget? trailing;

  const WebPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumb,
    this.actions,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (breadcrumb != null) ...[
            Text(
              breadcrumb!.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.pageTitle.copyWith(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AppTypography.pageSubtitle.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(width: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: actions!,
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.divider),
        ],
      ),
    );
  }
}
