import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';

/// Agronex-Inspired Operational KPI Metric Card
/// Features 20px smooth corners, bold display metrics, category chips, and stadium pill deltas.
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final String? subtitle;
  final String? delta;
  final bool? isPositiveDelta;
  final VoidCallback? onTap;
  final String? indexNumber;

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
    this.indexNumber,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? AppColors.primaryDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(22.0),
          decoration: AppDesign.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Title + Index / Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: AppTypography.kpiLabel.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (icon != null)
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: effectiveAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                      ),
                      child: Icon(
                        icon,
                        size: 17,
                        color: effectiveAccent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Middle: Bold KPI Value
              Text(
                value,
                style: AppTypography.kpiValue.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Bottom Row: Delta Stadium Pill & Subtitle
              if (delta != null || subtitle != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (delta != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isPositiveDelta ?? true)
                              ? AppColors.healthyBg
                              : AppColors.criticalBg,
                          borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                          border: Border.all(
                            color: (isPositiveDelta ?? true)
                                ? AppColors.healthyBorder
                                : AppColors.criticalBorder,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (isPositiveDelta ?? true)
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 11,
                              color: (isPositiveDelta ?? true)
                                  ? AppColors.healthy
                                  : AppColors.critical,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              delta!,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: (isPositiveDelta ?? true)
                                    ? AppColors.healthy
                                    : AppColors.critical,
                                decoration: TextDecoration.none,
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
                          style: AppTypography.metadata.copyWith(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
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
