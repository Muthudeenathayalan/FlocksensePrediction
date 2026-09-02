import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/farms/presentation/providers/selected_farm_provider.dart';
import 'package:flock_sense/features/intelligence/domain/disease_evidence_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_health_intelligence_model.dart';
import 'package:flock_sense/features/intelligence/domain/role_recommendation_model.dart';
import 'package:flock_sense/features/intelligence/presentation/providers/farm_intelligence_providers.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/farm_health_timeline_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/nearby_activity_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/role_recommendations_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/thermal_environment_widget.dart';

/// Comprehensive Farm Health Intelligence & Explainability Screen (Part 20)
class FarmHealthIntelligenceScreen extends ConsumerWidget {
  final String? farmId;
  final ResponsibleRole role;

  const FarmHealthIntelligenceScreen({
    super.key,
    this.farmId,
    this.role = ResponsibleRole.farmer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeContext = ref.watch(activeFarmContextProvider);
    final targetFarmId = farmId ?? activeContext.farmId;
    final intel = ref.watch(farmHealthIntelligenceProvider((farmId: targetFarmId, role: role)));

    final isCritical = intel.overallRiskScore >= 76;
    final isHigh = intel.overallRiskScore >= 51;

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebPageHeader(
            title: 'Farm Health Intelligence Engine',
            subtitle: 'Composite clinical decision-support • Farm: ${intel.farmName} • Evaluated via Rule-Based + Statistical + Spatio-Temporal Intelligence',
            actions: [
              StatusBadge(
                label: 'RISK: ${intel.overallRiskLevel.name.toUpperCase()} (${intel.overallRiskScore}/100)',
                type: isCritical ? StatusBadgeType.critical : (isHigh ? StatusBadgeType.warning : StatusBadgeType.healthy),
              ),
            ],
          ),

          // ── 1. Top 4-Pillar Intelligence Score Cards ─────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 36) / 4;
              final isNarrow = constraints.maxWidth < 900;
              final itemWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : cardWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildPillarCard(
                    title: 'Farm Behaviour',
                    score: intel.farmBehaviourStatus.label,
                    subtitle: '7-Day Statistical Baseline',
                    icon: Icons.show_chart_rounded,
                    color: intel.farmBehaviourStatus == FarmBehaviourStatus.severeAnomaly ? AppColors.critical : AppColors.warning,
                    width: itemWidth,
                  ),
                  _buildPillarCard(
                    title: 'Primary Syndrome',
                    score: '${intel.primarySyndrome.label}',
                    subtitle: 'Signal: ${intel.syndromeSignalStrength.label}',
                    icon: Icons.coronavirus_outlined,
                    color: AppColors.primary,
                    width: itemWidth,
                  ),
                  _buildPillarCard(
                    title: 'Environmental Stress',
                    score: '${intel.environmentalStressScore}/100',
                    subtitle: 'Level: ${intel.environmentalStressLevel.label}',
                    icon: Icons.thermostat_rounded,
                    color: intel.environmentalStressLevel.index >= 2 ? AppColors.warning : AppColors.healthy,
                    width: itemWidth,
                  ),
                  _buildPillarCard(
                    title: 'Biosecurity Exposure',
                    score: '${intel.biosecurityExposureScore}/100',
                    subtitle: 'Level: ${intel.biosecurityExposureLevel.label}',
                    icon: Icons.shield_outlined,
                    color: intel.biosecurityExposureLevel.index >= 2 ? AppColors.warning : AppColors.healthy,
                    width: itemWidth,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ── 2. Why This Was Flagged & Missing Evidence Split ──────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1000;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _buildWhyFlaggedCard(intel)),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: _buildMissingEvidenceCard(intel)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildWhyFlaggedCard(intel),
                    const SizedBox(height: 16),
                    _buildMissingEvidenceCard(intel),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 20),

          // ── 3. Differential Disease Evidence Match ────────────────────────────
          _buildDiseaseCandidatesSection(intel.diseaseCandidates),
          const SizedBox(height: 20),

          // ── 4. Thermal & Environmental Widget ─────────────────────────────────
          ThermalEnvironmentWidget(result: intel.environmentalStressResult),
          const SizedBox(height: 20),

          // ── 5. Nearby Activity & Recommendations ──────────────────────────────
          NearbyActivityWidget(
            exposure: intel.nearbyExposure,
            isClinicianView: role == ResponsibleRole.veterinarian || role == ResponsibleRole.government,
          ),
          const SizedBox(height: 20),

          RoleRecommendationsWidget(recommendations: intel.recommendations),
          const SizedBox(height: 20),

          // ── 6. Farm Health Timeline ───────────────────────────────────────────
          FarmHealthTimelineWidget(events: intel.timeline),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPillarCard({
    required String title,
    required String score,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.caption),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(score, style: AppTypography.headingSmall.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.slate500)),
        ],
      ),
    );
  }

  Widget _buildWhyFlaggedCard(FarmHealthIntelligenceModel intel) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.criticalBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag_outlined, color: AppColors.critical, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Why This Was Flagged', style: AppTypography.headingSmall),
                  Text('Real multi-factor evidence signals identified by engine', style: AppTypography.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (intel.topContributingSignals.isEmpty)
            Text('No acute risk triggers detected.', style: AppTypography.bodySmall)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: intel.topContributingSignals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final sig = intel.topContributingSignals[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.critical),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(sig, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w500)),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMissingEvidenceCard(FarmHealthIntelligenceModel intel) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.help_outline_rounded, color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Missing Evidence & Gaps', style: AppTypography.headingSmall),
                  Text('Information needed for definitive diagnosis', style: AppTypography.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (intel.missingEvidence.isEmpty)
            Text('All necessary clinical inputs recorded.', style: AppTypography.bodySmall)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: intel.missingEvidence.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final missing = intel.missingEvidence[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.radio_button_unchecked, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(missing, style: AppTypography.bodySmall.copyWith(color: AppColors.slate700)),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCandidatesSection(List<DiseaseCandidate> candidates) {
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
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.biotech_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Possible Conditions (Differential Evidence Match)', style: AppTypography.headingSmall),
                      Text('Species-specific veterinary reference matching • Clinical confirmation required', style: AppTypography.bodySmall),
                    ],
                  ),
                ],
              ),
              StatusBadge(
                label: '${candidates.length} Candidates',
                type: StatusBadgeType.info,
              ),
            ],
          ),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: candidates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cand = candidates[index];
              return _buildCandidateCard(cand);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(DiseaseCandidate cand) {
    Color badgeColor = AppColors.info;
    if (cand.evidenceMatch == EvidenceMatchLevel.veryHigh) {
      badgeColor = AppColors.critical;
    } else if (cand.evidenceMatch == EvidenceMatchLevel.high) {
      badgeColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(14),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  cand.evidenceMatch.label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(cand.clinicalNote, style: AppTypography.caption.copyWith(color: AppColors.slate600)),
          const SizedBox(height: 8),

          // Supporting evidence chips
          if (cand.supportingEvidence.isNotEmpty) ...[
            Text('Supporting Evidence:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: cand.supportingEvidence.map((e) {
                return Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(color: AppColors.border),
                  label: Text(e, style: const TextStyle(fontSize: 11)),
                );
              }).toList(),
            ),
          ],

          if (cand.recommendedDiagnosticEvidence.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Recommended Diagnostic Confirmation:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cand.recommendedDiagnosticEvidence.map((d) {
                return Row(
                  children: [
                    const Icon(Icons.arrow_right, size: 16, color: AppColors.primary),
                    Text(d, style: AppTypography.caption),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
