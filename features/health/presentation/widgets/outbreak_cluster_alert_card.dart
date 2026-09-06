import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/health/data/outbreak_cluster_service.dart';
import 'package:flock_sense/features/health/domain/outbreak_cluster_model.dart';

/// Web SaaS Outbreak Early Warning & Disease Cluster Alert Card (SIH26128 Phase 8)
class OutbreakClusterAlertCard extends StatelessWidget {
  final String district;
  final bool isFarmerView;

  const OutbreakClusterAlertCard({
    super.key,
    this.district = 'Nashik',
    this.isFarmerView = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OutbreakClusterModel>>(
      stream: OutbreakClusterService.streamClustersByDistrict(district),
      builder: (context, snapshot) {
        final clusters = snapshot.data ?? [];
        if (clusters.isEmpty) return const SizedBox.shrink();

        final cluster = clusters.first;

        if (isFarmerView) {
          return _buildFarmerAnonymizedWarning(cluster);
        }

        return _buildVetGovClusterDossier(cluster);
      },
    );
  }

  /// Anonymized Farmer Preventive Early Warning (Preserves Neighboring Farms' Privacy)
  Widget _buildFarmerAnonymizedWarning(OutbreakClusterModel cluster) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        border: Border.all(color: AppColors.critical.withValues(alpha: 0.35)),
        boxShadow: AppDesign.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.criticalBg.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDesign.radiusMd),
                topRight: Radius.circular(AppDesign.radiusMd),
              ),
              border: Border(bottom: BorderSide(color: AppColors.critical.withValues(alpha: 0.2), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.critical.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.critical, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Regional Disease Activity Advisory',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.critical),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Elevated ${cluster.syndrome} health signals detected within ~${cluster.radiusKm.toStringAsFixed(0)} km in ${cluster.district} district.',
                        style: const TextStyle(fontSize: 12, color: AppColors.slate700),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: 'PREVENTIVE ALERT',
                  type: StatusBadgeType.critical,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended Biosecurity Precautions:',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.slate800),
                ),
                const SizedBox(height: 10),
                _buildActionRow('Restrict all non-essential farm visitors and poultry delivery vehicles.'),
                const SizedBox(height: 6),
                _buildActionRow('Replenish virucidal footbaths at all shed entry points.'),
                const SizedBox(height: 6),
                _buildActionRow('Inspect flock immediately for respiratory clicking or drop in daily water intake.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.3),
          ),
        ),
      ],
    );
  }

  /// Full Epidemiological Dossier for Veterinarian Priority Queue & Government Surveillance
  Widget _buildVetGovClusterDossier(OutbreakClusterModel cluster) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        border: Border.all(color: AppColors.critical.withOpacity(0.5)),
        boxShadow: AppDesign.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.criticalBg.withOpacity(0.6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDesign.radiusLg),
                topRight: Radius.circular(AppDesign.radiusLg),
              ),
              border: Border(bottom: BorderSide(color: AppColors.critical.withOpacity(0.3), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.critical, borderRadius: BorderRadius.circular(AppDesign.radiusSm)),
                        child: const Icon(Icons.radar_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Text('POSSIBLE OUTBREAK CLUSTER • ${cluster.clusterCode}', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.critical)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.critical, borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    cluster.severity.toUpperCase(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${cluster.possibleDisease} • ${cluster.district} District (${cluster.state})',
                              style: const TextStyle(fontSize: 12, color: AppColors.slate700, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge.fromStatus(cluster.status.name),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Statistics Grid
                Row(
                  children: [
                    _buildStatPill(Icons.home_work_outlined, 'Farms Affected', '${cluster.farmCount} Unique Farms'),
                    const SizedBox(width: 12),
                    _buildStatPill(Icons.map_outlined, 'Cluster Radius', '${cluster.radiusKm.toStringAsFixed(1)} km Radius'),
                    const SizedBox(width: 12),
                    _buildStatPill(Icons.coronavirus_outlined, 'Mortalities', '${cluster.mortalityCount} Deaths (${cluster.affectedCount} Sick)'),
                    const SizedBox(width: 12),
                    _buildStatPill(Icons.verified_outlined, 'Correlation Confidence', '${cluster.clusterConfidence}% (${cluster.confidenceLabel.name.replaceAll("_", " ")})'),
                  ],
                ),
                const SizedBox(height: 18),

                // Explainable Evidence Breakdown
                const Text('EXPLAINABLE GEOGRAPHIC & TEMPORAL CORRELATION EVIDENCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.slate500)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: cluster.evidenceSummary.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.circle, size: 6, color: AppColors.critical),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e, style: const TextStyle(fontSize: 12, color: AppColors.slate800, height: 1.3))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Disclaimer
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: AppColors.slate500),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Outbreak Early Warning Notice: Signal identified from multi-farm spatial-temporal correlation. Field epidemiological verification recommended.',
                        style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: AppColors.slate600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.slate600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.slate600, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.slate900)),
          ],
        ),
      ),
    );
  }
}
