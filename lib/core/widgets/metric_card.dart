import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';

/// Clean, compact Desktop SaaS KPI Card
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final String? subtitle;
  final String? delta;
  final bool? isPositiveDelta;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.accentColor,
    this.subtitle,
    this.delta,
    this.isPositiveDelta,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: AppDesign.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Title + Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.kpiLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (icon != null)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: effectiveAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: effectiveAccent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Middle: Value
              Text(
                value,
                style: AppTypography.kpiValue.copyWith(
                  color: AppColors.slate900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Bottom Row: Delta / Subtitle
              if (delta != null || subtitle != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (delta != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isPositiveDelta ?? true)
                              ? AppColors.healthyBg
                              : AppColors.criticalBg,
                          borderRadius:
                              BorderRadius.circular(AppDesign.radiusXs),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (isPositiveDelta ?? true)
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 12,
                              color: (isPositiveDelta ?? true)
                                  ? AppColors.healthy
                                  : AppColors.critical,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              delta!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: (isPositiveDelta ?? true)
                                    ? AppColors.healthy
                                    : AppColors.critical,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (subtitle != null)
                      Expanded(
                        child: Text(
                          subtitle!,
                          style: AppTypography.metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
