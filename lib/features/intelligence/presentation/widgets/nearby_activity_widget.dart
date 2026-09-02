import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/intelligence/domain/nearby_exposure_model.dart';

/// Nearby Health Activity & Epidemiological Corridor Card (Part 6 & 18)
/// Protects data privacy: Anonymizes other farm names and contacts for farmers
class NearbyActivityWidget extends StatelessWidget {
  final NearbyExposureModel exposure;
  final bool isClinicianView;

  const NearbyActivityWidget({
    super.key,
    required this.exposure,
    this.isClinicianView = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = exposure.nearbyExposureLevel == NearbyExposureLevel.critical;
    final isHigh = exposure.nearbyExposureLevel == NearbyExposureLevel.high;
    final isMod = exposure.nearbyExposureLevel == NearbyExposureLevel.moderate;

    Color badgeColor = AppColors.healthy;
    if (isCritical) {
      badgeColor = AppColors.critical;
    } else if (isHigh || isMod) {
      badgeColor = AppColors.warning;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.share_location_rounded, color: badgeColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nearby Health & Disease Activity', style: AppTypography.headingSmall),
                      Text('10 km spatial corridor • Past 72 hours', style: AppTypography.bodySmall),
                    ],
                  ),
                ],
              ),
              StatusBadge(
                label: 'EXPOSURE: ${exposure.nearbyExposureLevel.label}',
                type: isCritical
                    ? StatusBadgeType.critical
                    : (isHigh || isMod ? StatusBadgeType.warning : StatusBadgeType.healthy),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Anonymized Summary Banner for Farmer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCritical
                  ? AppColors.criticalBg.withOpacity(0.5)
                  : (isHigh || isMod ? AppColors.warningBg.withOpacity(0.5) : AppColors.surfaceSubtle),
              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
              border: Border.all(
                color: isCritical
                    ? AppColors.critical.withOpacity(0.4)
                    : (isHigh || isMod ? AppColors.warning.withOpacity(0.4) : AppColors.border),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isCritical || isHigh ? Icons.crisis_alert_rounded : Icons.shield_outlined,
                  size: 20,
                  color: isCritical ? AppColors.critical : (isHigh ? AppColors.warning : AppColors.healthy),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isClinicianView ? exposure.clinicalSummary : exposure.farmerAnonymizedSummary,
                    style: AppTypography.bodySmall.copyWith(
                      color: isCritical ? AppColors.critical : AppColors.slate900,
                      fontWeight: isCritical || isHigh ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detail Signals for Clinician / Vet view
          if (isClinicianView && exposure.nearbySignals.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Corridor Incident Signals (Authorized View)', style: AppTypography.labelMedium),
            const SizedBox(height: 6),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exposure.nearbySignals.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final sig = exposure.nearbySignals[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: sig.riskLevel == 'critical' ? AppColors.critical : AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Text(sig.farmName, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 6),
                          Text('(~${sig.distanceKm} km)', style: AppTypography.caption),
                        ],
                      ),
                      Row(
                        children: [
                          Text('Syndrome: ${sig.syndrome}', style: AppTypography.caption),
                          const SizedBox(width: 8),
                          StatusBadge(
                            label: sig.riskLevel.toUpperCase(),
                            type: sig.riskLevel == 'critical' ? StatusBadgeType.critical : StatusBadgeType.warning,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
