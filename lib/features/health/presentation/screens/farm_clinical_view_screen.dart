import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/health/data/lab_test_service.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/lab_test_model.dart';
import 'package:flock_sense/features/intelligence/domain/disease_evidence_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_health_intelligence_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_metric_baseline_model.dart';
import 'package:flock_sense/features/intelligence/domain/role_recommendation_model.dart';
import 'package:flock_sense/features/intelligence/presentation/providers/farm_intelligence_providers.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/farm_health_timeline_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/nearby_activity_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/role_recommendations_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/thermal_environment_widget.dart';

/// Deep Clinical Farm View for Veterinarians (Part 11)
/// Reads the IDENTICAL farm intelligence data with clinical decision-support tooling
class FarmClinicalViewScreen extends ConsumerStatefulWidget {
  final String farmId;
  final String? farmName;
  final String? farmerName;
  final String? district;

  const FarmClinicalViewScreen({
    super.key,
    required this.farmId,
    this.farmName,
    this.farmerName,
    this.district,
  });

  @override
  ConsumerState<FarmClinicalViewScreen> createState() => _FarmClinicalViewScreenState();
}

class _FarmClinicalViewScreenState extends ConsumerState<FarmClinicalViewScreen> {
  int _selectedTab = 0; // 0: Clinical Overview, 1: Disease Evidence, 2: Lab & Rx, 3: Timeline

  @override
  Widget build(BuildContext context) {
    final intel = ref.watch(farmHealthIntelligenceProvider((
      farmId: widget.farmId,
      role: ResponsibleRole.veterinarian,
    )));

    final effectiveFarmName = widget.farmName ?? intel.farmName;
    final effectiveFarmerName = widget.farmerName ?? 'Ramesh Patil (Registered)';
    final effectiveDistrict = widget.district ?? 'Nashik';

    final isCritical = intel.overallRiskScore >= 76;
    final isHigh = intel.overallRiskScore >= 51;

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Clinician Header
          WebPageHeader(
            title: 'Clinical Farm Dossier • $effectiveFarmName',
            subtitle: 'Attending Clinician View • Farmer: $effectiveFarmerName • District: $effectiveDistrict • Live Farm Intelligence Synced',
            actions: [
              AppButton(
                label: 'Order Diagnostic Lab',
                icon: Icons.biotech_rounded,
                size: AppButtonSize.small,
                variant: AppButtonVariant.primary,
                onPressed: () => _openOrderLabDialog(context),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: 'RISK: ${intel.overallRiskLevel.name.toUpperCase()} (${intel.overallRiskScore}/100)',
                type: isCritical ? StatusBadgeType.critical : (isHigh ? StatusBadgeType.warning : StatusBadgeType.healthy),
              ),
            ],
          ),

          // 2. Navigation Tabs
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _buildTabButton(0, 'Clinical Overview', Icons.dashboard_outlined),
                _buildTabButton(1, 'Disease Evidence Match', Icons.medical_services_outlined),
                _buildTabButton(2, 'Laboratory & Treatment', Icons.biotech_outlined),
                _buildTabButton(3, 'Farm Health Timeline', Icons.timeline_outlined),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Tab Content
          if (_selectedTab == 0) ...[
            // Metric Baseline 4-Grid
            _buildClinicianMetricGrid(intel),
            const SizedBox(height: 20),

            // Thermal + Nearby Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1000;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: ThermalEnvironmentWidget(result: intel.environmentalStressResult)),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: NearbyActivityWidget(exposure: intel.nearbyExposure, isClinicianView: true)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      ThermalEnvironmentWidget(result: intel.environmentalStressResult),
                      const SizedBox(height: 16),
                      NearbyActivityWidget(exposure: intel.nearbyExposure, isClinicianView: true),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),

            // Clinical Decision Support Recommendations
            RoleRecommendationsWidget(recommendations: intel.recommendations),
          ] else if (_selectedTab == 1) ...[
            _buildDiseaseEvidenceTab(intel),
          ] else if (_selectedTab == 2) ...[
            _buildLabAndTreatmentTab(),
          ] else if (_selectedTab == 3) ...[
            FarmHealthTimelineWidget(events: intel.timeline),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.slate500),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.slate700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClinicianMetricGrid(FarmHealthIntelligenceModel intel) {
    final mort = intel.metricBaselines['mortality'];
    final feed = intel.metricBaselines['feed'];
    final water = intel.metricBaselines['water'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 36) / 4;
        final isNarrow = constraints.maxWidth < 900;
        final itemWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : cardWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildTile('Clinical Status', intel.farmBehaviourStatus.label, 'Pillar: ${intel.primarySyndrome.label}', intel.farmBehaviourStatus == FarmBehaviourStatus.severeAnomaly ? AppColors.critical : AppColors.warning, itemWidth),
            _buildTile('Daily Mortality', '${mort?.currentValue.toInt() ?? 15} dead/day', '${mort?.ratio.toStringAsFixed(1) ?? "5.0"}x Baseline (${mort?.baselineMean.toStringAsFixed(1) ?? "3.0"}/d)', (mort?.status == MetricStatus.severeAnomaly || mort?.status == MetricStatus.abnormal) ? AppColors.critical : AppColors.healthy, itemWidth),
            _buildTile('Feed Consumption', '${feed?.currentValue.toStringAsFixed(0) ?? "410"} kg/day', 'Deviation: ${feed?.deviationPercent.toStringAsFixed(1) ?? "-19.6"}%', feed?.status == MetricStatus.normal ? AppColors.healthy : AppColors.warning, itemWidth),
            _buildTile('Water Consumption', '${water?.currentValue.toStringAsFixed(0) ?? "720"} L/day', 'Deviation: ${water?.deviationPercent.toStringAsFixed(1) ?? "-20.0"}%', water?.status == MetricStatus.normal ? AppColors.healthy : AppColors.warning, itemWidth),
          ],
        );
      },
    );
  }

  Widget _buildTile(String title, String value, String sub, Color color, double width) {
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
          Text(value, style: AppTypography.headingSmall.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sub, style: AppTypography.caption.copyWith(color: AppColors.slate600)),
        ],
      ),
    );
  }

  Widget _buildDiseaseEvidenceTab(FarmHealthIntelligenceModel intel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Differential Disease Evidence Matching', style: AppTypography.headingSmall),
              Text('Veterinary clinical decision support • Ranked by evidence alignment', style: AppTypography.bodySmall),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: intel.diseaseCandidates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cand = intel.diseaseCandidates[index];
                  return _buildClinicianCandidateCard(cand);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClinicianCandidateCard(DiseaseCandidate cand) {
    Color badgeColor = AppColors.info;
    if (cand.evidenceMatch == EvidenceMatchLevel.veryHigh) {
      badgeColor = AppColors.critical;
    } else if (cand.evidenceMatch == EvidenceMatchLevel.high) {
      badgeColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(cand.name, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
              StatusBadge(label: cand.evidenceMatch.label, type: cand.evidenceMatch == EvidenceMatchLevel.veryHigh ? StatusBadgeType.critical : StatusBadgeType.warning),
            ],
          ),
          const SizedBox(height: 8),
          Text('Clinical Rationale: ${cand.clinicalNote}', style: AppTypography.bodySmall),
          const SizedBox(height: 10),

          // Supporting & Missing Split
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Supporting Evidence:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.healthy)),
                    const SizedBox(height: 4),
                    ...cand.supportingEvidence.map((s) => Text('• $s', style: AppTypography.caption)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Missing / Unverified:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.warning)),
                    const SizedBox(height: 4),
                    ...cand.missingEvidence.map((m) => Text('• $m', style: AppTypography.caption)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabAndTreatmentTab() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Diagnostic Laboratory Orders & Prescriptions', style: AppTypography.headingSmall),
          const SizedBox(height: 16),
          _buildLabRow('LAB-2026-001', 'Viral RT-PCR (NDV/IBV)', 'Tracheal / Cloacal Swabs in VTM', 'District Diagnostic Lab, Nashik', 'Under Assay', AppColors.warning),
          const Divider(height: 24),
          _buildLabRow('LAB-2026-002', 'Microscopic Fecal Oocyst Count', 'Fresh Fecal Droppings', 'Field Mobile Lab', 'Negative for Coccidia', AppColors.healthy),
          const SizedBox(height: 24),
          Text('Prescribed Supportive Regimen', style: AppTypography.headingSmall),
          const SizedBox(height: 12),
          Text('1. Continuous electrolyte + Vitamin C supportive hydration in drinking water.', style: AppTypography.bodySmall),
          Text('2. Broad-spectrum shed-entry virucidal footbath disinfectant renewal.', style: AppTypography.bodySmall),
          Text('3. Immediate isolation pen protocol for symptomatic gasping birds.', style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Widget _buildLabRow(String code, String test, String sample, String lab, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$code • $test', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
            Text('Sample: $sample • Lab: $lab', style: AppTypography.caption),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
        ),
      ],
    );
  }

  void _openOrderLabDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Order Diagnostic Laboratory Assay'),
        content: const Text('Dispatch sample collection order for RT-PCR (NDV / IBV / Avibacterium) to District Disease Diagnostic Laboratory, Nashik?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Diagnostic sample order LAB-2026-003 dispatched.')),
              );
            },
            child: const Text('Dispatch Order'),
          ),
        ],
      ),
    );
  }
}
