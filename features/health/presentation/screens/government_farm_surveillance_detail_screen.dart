import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/intelligence/domain/disease_evidence_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_health_intelligence_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_metric_baseline_model.dart';
import 'package:flock_sense/features/intelligence/domain/role_recommendation_model.dart';
import 'package:flock_sense/features/intelligence/presentation/providers/farm_intelligence_providers.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/farm_health_timeline_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/nearby_activity_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/role_recommendations_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/thermal_environment_widget.dart';

/// Authorized Read-Only Surveillance Detail Screen for Government Officers (Part 12)
class GovernmentFarmSurveillanceDetailScreen extends ConsumerWidget {
  final String farmId;
  final String? farmName;
  final String? district;
  final String? assignedVetName;

  const GovernmentFarmSurveillanceDetailScreen({
    super.key,
    required this.farmId,
    this.farmName,
    this.district,
    this.assignedVetName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intel = ref.watch(farmHealthIntelligenceProvider((
      farmId: farmId,
      role: ResponsibleRole.government,
    )));

    final effectiveFarmName = farmName ?? intel.farmName;
    final effectiveDistrict = district ?? 'Nashik';
    final effectiveVet = assignedVetName ?? 'Dr. V. Sharma (Surgeon)';

    final isCritical = intel.overallRiskScore >= 76;
    final isHigh = intel.overallRiskScore >= 51;

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hierarchical Breadcrumb (Part 12: Government → District → Veterinarian → Farm → Flock → Health Case)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _buildBreadcrumbItem(context, 'Government Command', true),
                _buildBreadcrumbSeparator(),
                _buildBreadcrumbItem(context, effectiveDistrict, true),
                _buildBreadcrumbSeparator(),
                _buildBreadcrumbItem(context, effectiveVet, true),
                _buildBreadcrumbSeparator(),
                _buildBreadcrumbItem(context, effectiveFarmName, false),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Header
          WebPageHeader(
            title: 'Surveillance Dossier • $effectiveFarmName',
            subtitle: 'Government Animal Health Command • District: $effectiveDistrict • Assigned Duty Clinician: $effectiveVet',
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.policy_outlined, size: 16, color: Color(0xFF15803D)),
                    SizedBox(width: 6),
                    Text(
                      'Authorized Government Surveillance (Read-Only)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: 'RISK: ${intel.overallRiskLevel.name.toUpperCase()} (${intel.overallRiskScore}/100)',
                type: isCritical ? StatusBadgeType.critical : (isHigh ? StatusBadgeType.warning : StatusBadgeType.healthy),
              ),
            ],
          ),

          // 3. Epidemiological Surveillance Metrics
          _buildSurveillanceMetricGrid(intel),
          const SizedBox(height: 20),

          // 4. Regional Cordon & Nearby Activity
          NearbyActivityWidget(exposure: intel.nearbyExposure, isClinicianView: true),
          const SizedBox(height: 20),

          // 5. Thermal & Environmental Microclimate
          ThermalEnvironmentWidget(result: intel.environmentalStressResult),
          const SizedBox(height: 20),

          // 6. Regional Government Recommendations
          RoleRecommendationsWidget(recommendations: intel.recommendations),
          const SizedBox(height: 20),

          // 7. Timeline
          FarmHealthTimelineWidget(events: intel.timeline),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(BuildContext context, String text, bool isLink) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: isLink ? FontWeight.w600 : FontWeight.w800,
        color: isLink ? const Color(0xFF15803D) : const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildBreadcrumbSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.slate400),
    );
  }

  Widget _buildSurveillanceMetricGrid(FarmHealthIntelligenceModel intel) {
    final mort = intel.metricBaselines['mortality'];
    final feed = intel.metricBaselines['feed'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 36) / 4;
        final isNarrow = constraints.maxWidth < 900;
        final itemWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : cardWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildGovCard('Surveillance Status', intel.farmBehaviourStatus.label, 'Primary Syndrome: ${intel.primarySyndrome.label}', intel.farmBehaviourStatus == FarmBehaviourStatus.severeAnomaly ? AppColors.critical : AppColors.warning, itemWidth),
            _buildGovCard('Mortality Velocity', '${mort?.currentValue.toInt() ?? 15} dead/day', 'Spike Ratio: ${mort?.ratio.toStringAsFixed(1) ?? "5.0"}x baseline', (mort?.status == MetricStatus.severeAnomaly || mort?.status == MetricStatus.abnormal) ? AppColors.critical : AppColors.healthy, itemWidth),
            _buildGovCard('Feed Intake Trend', '${feed?.deviationPercent.toStringAsFixed(1) ?? "-19.6"}%', 'Current: ${feed?.currentValue.toStringAsFixed(0) ?? "410"} kg/day', feed?.status == MetricStatus.normal ? AppColors.healthy : AppColors.warning, itemWidth),
            _buildGovCard('Biosecurity Barrier Index', '${intel.biosecurityExposureScore}/100', 'Exposure Level: ${intel.biosecurityExposureLevel.label}', intel.biosecurityExposureLevel.index >= 2 ? AppColors.warning : AppColors.healthy, itemWidth),
          ],
        );
      },
    );
  }

  Widget _buildGovCard(String title, String val, String sub, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.caption),
          const SizedBox(height: 6),
          Text(val, style: AppTypography.headingSmall.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sub, style: AppTypography.caption.copyWith(color: AppColors.slate600)),
        ],
      ),
    );
  }
}
