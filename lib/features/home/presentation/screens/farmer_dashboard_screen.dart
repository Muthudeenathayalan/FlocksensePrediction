import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_record_form_screen.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/farms/presentation/providers/selected_farm_provider.dart';
import 'package:flock_sense/features/health/presentation/screens/health_screen.dart';
import 'package:flock_sense/features/home/presentation/providers/farmer_dashboard_provider.dart';
import 'package:flock_sense/features/intelligence/domain/farm_health_intelligence_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_metric_baseline_model.dart';
import 'package:flock_sense/features/intelligence/domain/role_recommendation_model.dart';
import 'package:flock_sense/features/intelligence/presentation/providers/farm_intelligence_providers.dart';
import 'package:flock_sense/features/intelligence/presentation/screens/farm_health_intelligence_screen.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/farm_health_timeline_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/nearby_activity_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/role_recommendations_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/thermal_environment_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/visitor_log_dialog.dart';

/// Farmer Operations & Health Intelligence Dashboard (Part 10)
class FarmerDashboardScreen extends ConsumerStatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  ConsumerState<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends ConsumerState<FarmerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Farmer';
    final activeContext = ref.watch(activeFarmContextProvider);
    final rawFarms = ref.watch(farmListProvider).value ?? FarmService.inMemoryFarms;
    final farms = rawFarms.isNotEmpty ? rawFarms : FarmService.inMemoryFarms;
    final dashboardState = ref.watch(farmerDashboardProvider);

    // Watch central Farm Health Intelligence for the active farm
    final intel = ref.watch(farmHealthIntelligenceProvider((
      farmId: activeContext.farmId,
      role: ResponsibleRole.farmer,
    )));

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Top Farm Switcher & Status Header ─────────────────────────────
          _buildFarmHeader(displayName, activeContext, farms),
          const SizedBox(height: 20),

          // ── 2. 4-Card Hero Metric Baseline Strip ─────────────────────────────
          _buildMetricBaselineStrip(intel),
          const SizedBox(height: 24),

          // ── 3. Action Toolbar ────────────────────────────────────────────────
          _buildActionToolbar(activeContext),
          const SizedBox(height: 24),

          // ── 4. Main Split: Thermal Telemetry & Nearby Corridor Activity ──────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1000;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: ThermalEnvironmentWidget(
                        result: intel.environmentalStressResult,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: NearbyActivityWidget(
                        exposure: intel.nearbyExposure,
                        isClinicianView: false,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    ThermalEnvironmentWidget(result: intel.environmentalStressResult),
                    const SizedBox(height: 16),
                    NearbyActivityWidget(exposure: intel.nearbyExposure, isClinicianView: false),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // ── 5. Actionable Recommendations (WHAT, WHY, WHO, STATUS) ───────────
          RoleRecommendationsWidget(recommendations: intel.recommendations),
          const SizedBox(height: 24),

          // ── 6. Farm Health Timeline ──────────────────────────────────────────
          FarmHealthTimelineWidget(
            events: intel.timeline,
            onAddEvent: () => _openVisitorDialog(activeContext.farmId),
          ),
          const SizedBox(height: 24),

          // ── 7. Active Flocks & Batch Overview ────────────────────────────────
          _buildActiveBatchesSection(dashboardState, activeContext),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFarmHeader(String displayName, ActiveFarmContext activeContext, List<FarmModel> farms) {
    final effectiveFarms = farms.isNotEmpty ? farms : FarmService.inMemoryFarms;
    final farmIds = effectiveFarms.map((f) => f.id).toSet();
    final selectedFarmId = farmIds.contains(activeContext.farmId)
        ? activeContext.farmId
        : (effectiveFarms.isNotEmpty ? effectiveFarms.first.id : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppDesign.subtleShadow,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;
          return Flex(
            direction: isNarrow ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isNarrow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                    ),
                    child: const Icon(Icons.agriculture_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            activeContext.farmName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.healthyBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.healthy.withOpacity(0.3)),
                            ),
                            child: Text(
                              '${activeContext.district} • Active',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.healthy),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Farmer: $displayName • ${activeContext.batchName ?? "Flock Monitoring Active"}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.slate500),
                      ),
                    ],
                  ),
                ],
              ),
              if (effectiveFarms.length > 1) ...[
                if (isNarrow) const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedFarmId,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 20, color: AppColors.primary),
                      items: effectiveFarms.map((f) {
                        return DropdownMenuItem<String>(
                          value: f.id,
                          child: Text(f.farmName, style: AppTypography.labelMedium),
                        );
                      }).toList(),
                      onChanged: (farmId) {
                        if (farmId != null) {
                          final selected = effectiveFarms.firstWhere((f) => f.id == farmId);
                          ref.read(activeFarmContextProvider.notifier).selectFarmModel(selected);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricBaselineStrip(FarmHealthIntelligenceModel intel) {
    final mort = intel.metricBaselines['mortality'];
    final feed = intel.metricBaselines['feed'];
    final water = intel.metricBaselines['water'];

    final isCritical = intel.overallRiskScore >= 76;
    final isHigh = intel.overallRiskScore >= 51;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 36) / 4;
        final isNarrow = constraints.maxWidth < 900;
        final itemWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : cardWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Card 1: Overall Health Risk
            _buildMetricCard(
              title: 'Farm Health Risk',
              value: '${intel.overallRiskScore} / 100',
              subtitle: 'Risk Level: ${intel.overallRiskLevel.name.toUpperCase()}',
              statusText: intel.farmBehaviourStatus.label,
              statusType: isCritical ? StatusBadgeType.critical : (isHigh ? StatusBadgeType.warning : StatusBadgeType.healthy),
              icon: Icons.health_and_safety_outlined,
              width: itemWidth,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FarmHealthIntelligenceScreen(
                      farmId: intel.farmId,
                      role: ResponsibleRole.farmer,
                    ),
                  ),
                );
              },
            ),

            // Card 2: Mortality vs Baseline
            _buildMetricCard(
              title: 'Daily Mortality vs Baseline',
              value: '${mort?.currentValue.toInt() ?? 3} birds/day',
              subtitle: '7-Day Baseline: ${mort?.baselineMean.toStringAsFixed(1) ?? "3.0"}/day (${mort?.ratio.toStringAsFixed(1) ?? "1.0"}x)',
              statusText: mort?.status.label ?? 'NORMAL',
              statusType: (mort?.status == MetricStatus.severeAnomaly || mort?.status == MetricStatus.abnormal)
                  ? StatusBadgeType.critical
                  : StatusBadgeType.healthy,
              icon: Icons.trending_up_rounded,
              width: itemWidth,
            ),

            // Card 3: Feed Consumption vs Baseline
            _buildMetricCard(
              title: 'Feed Intake vs Baseline',
              value: '${feed?.currentValue.toStringAsFixed(0) ?? "510"} kg/day',
              subtitle: 'Baseline: ${feed?.baselineMean.toStringAsFixed(0) ?? "510"} kg (${feed?.deviationPercent.toStringAsFixed(1) ?? "0.0"}%)',
              statusText: feed?.status.label ?? 'NORMAL',
              statusType: feed?.status == MetricStatus.normal ? StatusBadgeType.healthy : StatusBadgeType.warning,
              icon: Icons.restaurant_outlined,
              width: itemWidth,
            ),

            // Card 4: Water Intake vs Baseline
            _buildMetricCard(
              title: 'Water Intake vs Baseline',
              value: '${water?.currentValue.toStringAsFixed(0) ?? "900"} L/day',
              subtitle: 'Baseline: ${water?.baselineMean.toStringAsFixed(0) ?? "900"} L (${water?.deviationPercent.toStringAsFixed(1) ?? "0.0"}%)',
              statusText: water?.status.label ?? 'NORMAL',
              statusType: water?.status == MetricStatus.normal ? StatusBadgeType.healthy : StatusBadgeType.warning,
              icon: Icons.water_drop_outlined,
              width: itemWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required String statusText,
    required StatusBadgeType statusType,
    required IconData icon,
    required double width,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDesign.radiusSm),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDesign.radiusSm),
          border: Border.all(color: AppColors.border),
          boxShadow: AppDesign.subtleShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: AppTypography.caption, overflow: TextOverflow.ellipsis)),
                Icon(icon, size: 16, color: AppColors.slate400),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.headingMedium.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.slate600)),
            const SizedBox(height: 8),
            StatusBadge(label: statusText, type: statusType),
          ],
        ),
      ),
    );
  }

  Widget _buildActionToolbar(ActiveFarmContext activeContext) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final itemWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: AppButton(
                label: 'Log Daily Record',
                icon: Icons.edit_note_rounded,
                variant: AppButtonVariant.primary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DailyRecordFormScreen(
                        farmId: activeContext.farmId,
                        batchId: activeContext.batchId ?? 'batch_01',
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AppButton(
                label: 'Report Health Anomaly',
                icon: Icons.report_problem_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HealthScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AppButton(
                label: 'Log Visitor Entry',
                icon: Icons.person_add_alt_1_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => _openVisitorDialog(activeContext.farmId),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: AppButton(
                label: 'Intelligence Engine',
                icon: Icons.psychology_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FarmHealthIntelligenceScreen(
                        farmId: activeContext.farmId,
                        role: ResponsibleRole.farmer,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveBatchesSection(FarmerDashboardState state, ActiveFarmContext activeContext) {
    final rawBatches = state.activeBatches.isNotEmpty ? state.activeBatches : BatchService.inMemoryBatches;
    final batches = rawBatches.where((b) => b.farmId == activeContext.farmId || activeContext.farmId.isEmpty).toList();
    final effectiveBatches = batches.isNotEmpty ? batches : rawBatches;
    final totalBirds = effectiveBatches.fold<int>(0, (sum, b) => sum + b.currentBirds);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Flocks & Batch Telemetry', style: AppTypography.headingSmall),
              Text('$totalBirds Live Birds Total', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: effectiveBatches.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final batch = effectiveBatches[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.egg_outlined, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(batch.batchName, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                            Text('Breed: ${batch.breedOrFlockType} • Placed: ${batch.currentBirds} birds', style: AppTypography.caption),
                          ],
                        ),
                      ],
                    ),
                    StatusBadge(label: batch.status.toUpperCase(), type: StatusBadgeType.healthy),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openVisitorDialog(String farmId) {
    showDialog(
      context: context,
      builder: (_) => VisitorLogDialog(
        farmId: farmId,
        onSaved: () => setState(() {}),
      ),
    );
  }
}
