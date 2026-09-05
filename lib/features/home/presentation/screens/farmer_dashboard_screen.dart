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
import 'package:flock_sense/features/vaccination/presentation/screens/vaccination_screen.dart';
import 'package:flock_sense/features/home/presentation/providers/farmer_dashboard_provider.dart';
import 'package:flock_sense/features/intelligence/domain/farm_health_intelligence_model.dart';
import 'package:flock_sense/features/intelligence/domain/farm_metric_baseline_model.dart';
import 'package:flock_sense/features/intelligence/domain/role_recommendation_model.dart';
import 'package:flock_sense/features/intelligence/domain/environmental_intelligence_model.dart';
import 'package:flock_sense/features/intelligence/presentation/providers/farm_intelligence_providers.dart';
import 'package:flock_sense/features/intelligence/presentation/screens/farm_health_intelligence_screen.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/farm_health_timeline_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/nearby_activity_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/role_recommendations_widget.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/visitor_log_dialog.dart';
import 'package:flock_sense/shared/analytics/animated_chart_container.dart';
import 'package:flock_sense/shared/analytics/animated_kpi_card.dart';
import 'package:flock_sense/shared/analytics/animated_line_chart.dart';

/// Next-Generation Farmer Agricultural Command Center
class FarmerDashboardScreen extends ConsumerStatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  ConsumerState<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends ConsumerState<FarmerDashboardScreen> {
  String _chartTimeframe = '7D';
  
  // Interactive checklist state for daily farm routines
  final Map<String, bool> _completedChores = {
    'morning_mortality': true,
    'water_flushing': true,
    'feed_level': false,
    'curtain_adjustment': false,
  };

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
          // ── 1. Hero SaaS Farm Command Banner ────────────────────────────────
          _buildHeroFarmBanner(displayName, activeContext, farms, intel),
          const SizedBox(height: 20),

          // ── 2. 5-Card Operational KPI Matrix ────────────────────────────────
          _buildOperationalKpiMatrix(dashboardState, intel),
          const SizedBox(height: 20),

          // ── 3. High-Impact Action Command Grid ──────────────────────────────
          _buildActionCommandGrid(activeContext),
          const SizedBox(height: 24),

          // ── 4. Main 2-Column Split: Telemetry & Analytics + Chores/Radar ────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1020;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (60% width)
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPerformanceTrendChart(),
                          const SizedBox(height: 20),
                          _buildModernThermalTelemetry(intel.environmentalStressResult),
                          const SizedBox(height: 20),
                          _buildActiveShedsGrid(dashboardState, activeContext),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right Column (40% width)
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDailyChoresCard(),
                          const SizedBox(height: 20),
                          NearbyActivityWidget(
                            exposure: intel.nearbyExposure,
                            isClinicianView: false,
                          ),
                          const SizedBox(height: 20),
                          RoleRecommendationsWidget(recommendations: intel.recommendations),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildPerformanceTrendChart(),
                    const SizedBox(height: 20),
                    _buildModernThermalTelemetry(intel.environmentalStressResult),
                    const SizedBox(height: 20),
                    _buildDailyChoresCard(),
                    const SizedBox(height: 20),
                    _buildActiveShedsGrid(dashboardState, activeContext),
                    const SizedBox(height: 20),
                    NearbyActivityWidget(
                      exposure: intel.nearbyExposure,
                      isClinicianView: false,
                    ),
                    const SizedBox(height: 20),
                    RoleRecommendationsWidget(recommendations: intel.recommendations),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // ── 5. Farm Health & Visitor Timeline ───────────────────────────────
          FarmHealthTimelineWidget(
            events: intel.timeline,
            onAddEvent: () => _openVisitorDialog(activeContext.farmId),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 1. HERO FARM COMMAND BANNER
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildHeroFarmBanner(
    String displayName,
    ActiveFarmContext activeContext,
    List<FarmModel> farms,
    FarmHealthIntelligenceModel intel,
  ) {
    final effectiveFarms = farms.isNotEmpty ? farms : FarmService.inMemoryFarms;
    final farmIds = effectiveFarms.map((f) => f.id).toSet();
    final selectedFarmId = farmIds.contains(activeContext.farmId)
        ? activeContext.farmId
        : (effectiveFarms.isNotEmpty ? effectiveFarms.first.id : null);

    final isOptimal = intel.overallRiskScore < 50;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C1311), // Agronex Deep Obsidian Slate
            Color(0xFF131E1B),
            Color(0xFF1A2A26),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        border: Border.all(color: const Color(0xFF223530), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 800;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Farm Identification & Status
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD2F546).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD2F546).withValues(alpha: 0.4)),
                          ),
                          child: const Icon(
                            Icons.agriculture_rounded,
                            color: Color(0xFFD2F546),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      activeContext.farmName,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isOptimal
                                          ? const Color(0xFFD2F546).withValues(alpha: 0.15)
                                          : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: isOptimal
                                            ? const Color(0xFFD2F546)
                                            : const Color(0xFFFBBF24),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isOptimal
                                                ? const Color(0xFFD2F546)
                                                : const Color(0xFFFBBF24),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${activeContext.district} • ${isOptimal ? "OPTIMAL HEALTH" : "CAUTION"}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                            color: isOptimal
                                                ? const Color(0xFFD2F546)
                                                : const Color(0xFFFEF3C7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Farmer: $displayName • ${activeContext.batchName ?? "Active Flock Monitoring"} • Broiler Batch 01',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Farm Selector Dropdown (Glassmorphism Pill)
                  if (effectiveFarms.length > 1 && !isNarrow) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedFarmId,
                          dropdownColor: const Color(0xFF131E1B),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 20, color: Color(0xFFD2F546)),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          items: effectiveFarms.map((f) {
                            return DropdownMenuItem<String>(
                              value: f.id,
                              child: Text(f.farmName, style: const TextStyle(color: Colors.white)),
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
              ),
              const SizedBox(height: 18),

              // Bottom Stats Strip in Banner: Weather + IoT Sync + Harvest Days
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildBannerStatItem(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Weather',
                      value: '29.0°C • 65% RH',
                    ),
                    _buildBannerStatItem(
                      icon: Icons.sensors_rounded,
                      label: 'Telemetry Stream',
                      value: 'Live (Sync 1m ago)',
                    ),
                    _buildBannerStatItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Harvest Target',
                      value: 'Day 32 of 42 (10 days left)',
                    ),
                    _buildBannerStatItem(
                      icon: Icons.shield_rounded,
                      label: 'Biosecurity Tier',
                      value: 'Grade A High-Integrity',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBannerStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFD2F546)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 2. 5-CARD OPERATIONAL KPI MATRIX
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildOperationalKpiMatrix(
    FarmerDashboardState state,
    FarmHealthIntelligenceModel intel,
  ) {
    final mort = intel.metricBaselines['mortality'];
    final feed = intel.metricBaselines['feed'];
    final water = intel.metricBaselines['water'];

    final isCritical = intel.overallRiskScore >= 76;
    final isHigh = intel.overallRiskScore >= 51;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // 5 cards on desktop, 3 on tablet, 2 on mobile
        double cardWidth;
        if (totalWidth >= 1100) {
          cardWidth = (totalWidth - (4 * 12)) / 5;
        } else if (totalWidth >= 750) {
          cardWidth = (totalWidth - (2 * 12)) / 3;
        } else {
          cardWidth = (totalWidth - 12) / 2;
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Card 1: Total Live Birds
            SizedBox(
              width: cardWidth,
              child: AnimatedKpiCard(
                title: 'Total Live Birds',
                numericValue: state.totalLiveBirds > 0 ? state.totalLiveBirds : 9850,
                suffix: 'birds',
                delta: '98.5% Survival',
                isPositiveDelta: true,
                subtitle: 'Target: 10,000 placed',
                icon: Icons.groups_rounded,
                accentColor: AppColors.primary,
              ),
            ),

            // Card 2: Today's Mortality
            SizedBox(
              width: cardWidth,
              child: AnimatedKpiCard(
                title: 'Daily Mortality',
                numericValue: mort?.currentValue ?? 3,
                suffix: 'birds/day',
                delta: '-0.5 vs 7d avg',
                isPositiveDelta: true,
                isIncreaseNegative: true,
                subtitle: 'Baseline: ${mort?.baselineMean.toStringAsFixed(1) ?? "2.5"}/day',
                icon: Icons.health_and_safety_rounded,
                accentColor: AppColors.healthy,
              ),
            ),

            // Card 3: Feed Consumption
            SizedBox(
              width: cardWidth,
              child: AnimatedKpiCard(
                title: 'Feed Intake (Today)',
                numericValue: feed?.currentValue ?? 510,
                suffix: 'kg/day',
                delta: '${feed?.deviationPercent.toStringAsFixed(1) ?? "0.0"}% target',
                isPositiveDelta: true,
                subtitle: '102g / bird / day',
                icon: Icons.restaurant_rounded,
                accentColor: AppColors.info,
              ),
            ),

            // Card 4: Water Intake & Ratio
            SizedBox(
              width: cardWidth,
              child: AnimatedKpiCard(
                title: 'Water Intake',
                numericValue: water?.currentValue ?? 920,
                suffix: 'L/day',
                delta: '1.80 Water:Feed',
                isPositiveDelta: true,
                subtitle: 'Baseline: 900 L/day',
                icon: Icons.water_drop_rounded,
                accentColor: const Color(0xFF0EA5E9),
              ),
            ),

            // Card 5: AI Health Risk Score
            SizedBox(
              width: cardWidth,
              child: AnimatedKpiCard(
                title: 'Farm Health Risk',
                numericValue: intel.overallRiskScore,
                suffix: '/ 100',
                delta: intel.overallRiskLevel.name.toUpperCase(),
                isPositiveDelta: !isCritical && !isHigh,
                isIncreaseNegative: true,
                subtitle: intel.farmBehaviourStatus.label,
                icon: Icons.verified_user_rounded,
                accentColor: isCritical
                    ? AppColors.critical
                    : (isHigh ? AppColors.warning : AppColors.healthy),
                isCritical: isCritical,
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
            ),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 3. ACTION COMMAND GRID
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildActionCommandGrid(ActiveFarmContext activeContext) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        double itemWidth;
        if (totalWidth >= 1050) {
          itemWidth = (totalWidth - (4 * 12)) / 5;
        } else if (totalWidth >= 650) {
          itemWidth = (totalWidth - (2 * 12)) / 3;
        } else {
          itemWidth = (totalWidth - 12) / 2;
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Action 1: Log Daily Record (Highlighted Primary Action)
            _buildCommandCard(
              title: 'Log Daily Record',
              subtitle: 'Feed, Water & Mortality',
              icon: Icons.edit_calendar_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              isPrimary: true,
              width: itemWidth,
              onTap: () {
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

            // Action 2: Health Anomaly
            _buildCommandCard(
              title: 'Report Health Anomaly',
              subtitle: 'Symptom & Thermal Alert',
              icon: Icons.add_alert_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              width: itemWidth,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HealthScreen()),
                );
              },
            ),

            // Action 3: Visitor Entry
            _buildCommandCard(
              title: 'Log Visitor Entry',
              subtitle: 'Biosecurity Gate Log',
              icon: Icons.person_add_alt_1_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              width: itemWidth,
              onTap: () => _openVisitorDialog(activeContext.farmId),
            ),

            // Action 4: Intelligence Engine
            _buildCommandCard(
              title: 'AI Intelligence Hub',
              subtitle: 'Epidemiological Forecast',
              icon: Icons.auto_awesome_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              width: itemWidth,
              onTap: () {
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

            // Action 5: Vaccination Schedule
            _buildCommandCard(
              title: 'Vaccine & Medication',
              subtitle: 'Schedule & Dosage Log',
              icon: Icons.vaccines_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
              ),
              width: itemWidth,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VaccinationScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommandCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required double width,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDesign.radiusMd),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPrimary ? null : AppColors.surface,
          gradient: isPrimary ? gradient : null,
          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
          border: Border.all(
            color: isPrimary ? Colors.transparent : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isPrimary ? 0.12 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: isPrimary ? null : gradient,
                color: isPrimary ? Colors.white.withValues(alpha: 0.25) : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isPrimary ? Colors.white : AppColors.slate900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.slate500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 4A. 7-DAY PERFORMANCE & GROWTH CHART
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildPerformanceTrendChart() {
    return AnimatedChartContainer(
      title: '7-Day Feed Intake & Growth Trajectory',
      subtitle: 'Daily feed consumption (kg) vs expected breed genetic standard curve',
      selectedTimeRange: _chartTimeframe,
      onTimeRangeChanged: (val) => setState(() => _chartTimeframe = val),
      legendItems: const [
        LegendItemData(label: 'Feed Intake (kg)', color: AppColors.primary),
        LegendItemData(label: 'Breed Standard (kg)', color: AppColors.slate400, isDashed: true),
        LegendItemData(label: 'Water Intake (x10 L)', color: Color(0xFF0EA5E9)),
      ],
      height: 250,
      child: AnimatedLineChart(
        yUnit: 'kg',
        maxY: 650,
        series: [
          LineChartSeriesData(
            name: 'Actual Feed',
            color: AppColors.primary,
            hasAreaFill: true,
            strokeWidth: 2.8,
            points: const [
              ChartDataPoint(x: 0, y: 440, label: 'Day 26'),
              ChartDataPoint(x: 1, y: 460, label: 'Day 27'),
              ChartDataPoint(x: 2, y: 475, label: 'Day 28'),
              ChartDataPoint(x: 3, y: 490, label: 'Day 29'),
              ChartDataPoint(x: 4, y: 495, label: 'Day 30'),
              ChartDataPoint(x: 5, y: 505, label: 'Day 31'),
              ChartDataPoint(x: 6, y: 510, label: 'Today (D32)'),
            ],
          ),
          LineChartSeriesData(
            name: 'Standard Target',
            color: AppColors.slate400,
            isDashed: true,
            hasAreaFill: false,
            strokeWidth: 1.8,
            points: const [
              ChartDataPoint(x: 0, y: 435, label: 'Day 26'),
              ChartDataPoint(x: 1, y: 450, label: 'Day 27'),
              ChartDataPoint(x: 2, y: 468, label: 'Day 28'),
              ChartDataPoint(x: 3, y: 482, label: 'Day 29'),
              ChartDataPoint(x: 4, y: 495, label: 'Day 30'),
              ChartDataPoint(x: 5, y: 505, label: 'Day 31'),
              ChartDataPoint(x: 6, y: 512, label: 'Today (D32)'),
            ],
          ),
          LineChartSeriesData(
            name: 'Water Intake',
            color: const Color(0xFF0EA5E9),
            hasAreaFill: false,
            strokeWidth: 2.0,
            points: const [
              ChartDataPoint(x: 0, y: 540, label: 'Day 26'),
              ChartDataPoint(x: 1, y: 560, label: 'Day 27'),
              ChartDataPoint(x: 2, y: 570, label: 'Day 28'),
              ChartDataPoint(x: 3, y: 585, label: 'Day 29'),
              ChartDataPoint(x: 4, y: 590, label: 'Day 30'),
              ChartDataPoint(x: 5, y: 600, label: 'Day 31'),
              ChartDataPoint(x: 6, y: 610, label: 'Today (D32)'),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 4B. MODERN THERMAL & ENVIRONMENTAL TELEMETRY
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildModernThermalTelemetry(EnvironmentalStressResult result) {
    final isAlert = result.environmentalStressLevel == EnvironmentalStressLevel.alert;
    final isHigh = result.environmentalStressLevel == EnvironmentalStressLevel.high;
    final isCritical = result.environmentalStressLevel == EnvironmentalStressLevel.critical;

    Color badgeColor = AppColors.healthy;
    if (isCritical) {
      badgeColor = AppColors.critical;
    } else if (isHigh || isAlert) {
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
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.thermostat_outlined, color: badgeColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('IoT Environmental & Thermal Comfort', style: AppTypography.headingSmall),
                      Text(
                        'Target profile: Broiler (Day 22-70) • Optimum: 20-25°C',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              StatusBadge(
                label: 'STRESS: ${result.environmentalStressLevel.label}',
                type: isCritical
                    ? StatusBadgeType.critical
                    : (isHigh || isAlert ? StatusBadgeType.warning : StatusBadgeType.healthy),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 Telemetry Value Tiles
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final tileWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildTelemetryTile(
                    title: 'Shed Ambient Temp',
                    value: '${result.ambientTemperature.toStringAsFixed(1)}°C',
                    target: 'Target: 20-25°C',
                    isOutOfRange: result.ambientTemperature > 25.0,
                    icon: Icons.device_thermostat_rounded,
                    width: tileWidth,
                  ),
                  _buildTelemetryTile(
                    title: 'Relative Humidity',
                    value: '${result.humidity.toStringAsFixed(0)}%',
                    target: 'Target: 50-70%',
                    isOutOfRange: result.humidity > 70 || result.humidity < 50,
                    icon: Icons.water_drop_outlined,
                    width: tileWidth,
                  ),
                  _buildTelemetryTile(
                    title: 'THI Heat Index',
                    value: result.thi.toStringAsFixed(1),
                    target: result.thi >= 78 ? 'Ventilation Active' : 'Normal Range (<78)',
                    isOutOfRange: result.thi >= 78,
                    icon: Icons.speed_rounded,
                    width: tileWidth,
                  ),
                  _buildTelemetryTile(
                    title: 'Surface Scan',
                    value: result.surfaceTemperature != null
                        ? '${result.surfaceTemperature!.toStringAsFixed(1)}°C'
                        : 'Calibrated',
                    target: '0 Hotspots Detected',
                    isOutOfRange: false,
                    icon: Icons.camera_indoor_outlined,
                    width: tileWidth,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Visual Thermal Comfort Band
          Container(
            padding: const EdgeInsets.all(12),
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
                    const Text('Flock Thermal Comfort Band (24h Trend)', style: AppTypography.labelMedium),
                    Text(
                      'Comfort Window: 20°C — 25°C',
                      style: AppTypography.caption.copyWith(color: AppColors.slate600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (result.ambientTemperature / 45.0).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: AppColors.slate200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      result.ambientTemperature > 28.0 ? AppColors.warning : AppColors.healthy,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ambient temperature (29.0°C) slightly elevated. Tunnel ventilation fans 1-4 active to maintain 2.1 m/s wind chill effect.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.slate700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryTile({
    required String title,
    required String value,
    required String target,
    required bool isOutOfRange,
    required IconData icon,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOutOfRange ? AppColors.warningLight.withValues(alpha: 0.3) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(
          color: isOutOfRange ? AppColors.warning.withValues(alpha: 0.5) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: isOutOfRange ? AppColors.warning : AppColors.slate500),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(
              color: isOutOfRange ? AppColors.warning : AppColors.slate900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            target,
            style: AppTypography.caption.copyWith(color: AppColors.slate600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 4C. DAILY FARMER CHORES & CHECKLIST
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildDailyChoresCard() {
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
                    child: const Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Today's Operational Chores", style: AppTypography.headingSmall),
                      Text("Daily bio-routine & inspection schedule", style: AppTypography.bodySmall),
                    ],
                  ),
                ],
              ),
              StatusBadge(
                label: '${_completedChores.values.where((v) => v).length}/${_completedChores.length} Done',
                type: StatusBadgeType.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildChoreItem(
            id: 'morning_mortality',
            title: 'Morning Mortality Check & Disposal',
            time: '07:30 AM • Completed',
            icon: Icons.check_circle_rounded,
          ),
          const Divider(height: 1),
          _buildChoreItem(
            id: 'water_flushing',
            title: 'Drinker Line Pressure & Nipple Flush',
            time: '09:00 AM • Completed',
            icon: Icons.water_drop_outlined,
          ),
          const Divider(height: 1),
          _buildChoreItem(
            id: 'feed_level',
            title: 'Afternoon Silo & Feeder Auger Check',
            time: '01:00 PM • Due in 2 hours',
            icon: Icons.inventory_2_outlined,
          ),
          const Divider(height: 1),
          _buildChoreItem(
            id: 'curtain_adjustment',
            title: 'Evening Tunnel Ventilation Tuning',
            time: '04:30 PM • Pending',
            icon: Icons.air_rounded,
          ),
          const SizedBox(height: 8),

          // Scheduled Vaccine Reminder Banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.notification_important_rounded, size: 18, color: Color(0xFF0D9488)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Upcoming: ND Lasota Vaccine Booster scheduled for Day 34 (in 2 days).',
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFF0F766E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoreItem({
    required String id,
    required String title,
    required String time,
    required IconData icon,
  }) {
    final isDone = _completedChores[id] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: isDone,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) {
              setState(() {
                _completedChores[id] = val ?? false;
              });
            },
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? AppColors.slate500 : AppColors.slate900,
                  ),
                ),
                Text(time, style: AppTypography.caption.copyWith(color: AppColors.slate500)),
              ],
            ),
          ),
          if (isDone)
            const Icon(Icons.check_rounded, size: 18, color: AppColors.healthy)
          else
            const Icon(Icons.schedule_rounded, size: 16, color: AppColors.slate400),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 4D. ACTIVE SHEDS & FLOCKS OVERVIEW
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildActiveShedsGrid(FarmerDashboardState state, ActiveFarmContext activeContext) {
    final rawBatches = state.activeBatches.isNotEmpty ? state.activeBatches : BatchService.inMemoryBatches;
    final batches = rawBatches.where((b) => b.farmId == activeContext.farmId || activeContext.farmId.isEmpty).toList();
    final effectiveBatches = batches.isNotEmpty ? batches : rawBatches;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Active Sheds & Flock Telemetry', style: AppTypography.headingSmall),
              Text(
                '${effectiveBatches.length} Operational Sheds',
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: effectiveBatches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final batch = effectiveBatches[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.warehouse_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batch.batchName,
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Breed: ${batch.breedOrFlockType} • ${batch.currentBirds} Live Birds',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text('29.0°C • 65% RH', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.slate700)),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(label: batch.status.toUpperCase(), type: StatusBadgeType.healthy),
                      ],
                    ),
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

