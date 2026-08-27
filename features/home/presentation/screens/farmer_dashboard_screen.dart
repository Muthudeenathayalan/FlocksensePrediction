import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/health/data/health_service.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/presentation/screens/health_screen.dart';
import 'package:flock_sense/features/health/presentation/widgets/farm_prevention_dashboard_card.dart';
import 'package:flock_sense/features/health/presentation/widgets/outbreak_cluster_alert_card.dart';
import 'package:flock_sense/features/home/presentation/providers/farmer_dashboard_provider.dart';
import 'package:flock_sense/features/vaccine/presentation/screens/vaccine_records_screen.dart';
import 'package:flock_sense/shared/analytics/animated_chart_container.dart';
import 'package:flock_sense/shared/analytics/animated_donut_chart.dart';
import 'package:flock_sense/shared/analytics/animated_kpi_card.dart';
import 'package:flock_sense/shared/analytics/animated_line_chart.dart';
import 'package:flock_sense/shared/analytics/biosecurity_score_bar.dart';

/// Dedicated Farmer Operational Dashboard with Interactive Real-Time Analytics (SIH26128)
class FarmerDashboardScreen extends ConsumerStatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  ConsumerState<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends ConsumerState<FarmerDashboardScreen> {
  String _mortalityTimeRange = '7D';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Farmer';
    final state = ref.watch(farmerDashboardProvider);

    final farms = state.farms;
    final activeBatches = state.activeBatches;
    final activeCases = state.activeCases;
    final criticalAlerts = state.criticalAlerts;
    final totalLiveBirds = state.totalLiveBirds;
    final todayMortality = state.todayMortality;

    return StreamBuilder<List<HealthCaseModel>>(
      stream: HealthService.streamHealthCases(),
      builder: (context, caseSnapshot) {
        final allCases = caseSnapshot.data ?? activeCases;
        final liveCritical = allCases.where((c) => c.riskLevel == HealthRiskLevel.critical || c.riskLevel == HealthRiskLevel.high).toList();

        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Web Page Header with Farmer Actions
              WebPageHeader(
                title: 'Farmer Operations & Health Telemetry',
                subtitle: 'Welcome back, $displayName • Live poultry farm situation, flock telemetry & syndromic surveillance',
                actions: [
                  AppButton(
                    label: 'Report Health Issue',
                    icon: Icons.add_alert_rounded,
                    size: AppButtonSize.small,
                    variant: AppButtonVariant.outlined,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HealthScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: 'Add Daily Record',
                    icon: Icons.edit_note_rounded,
                    size: AppButtonSize.small,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyRecordsDashboardScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // 2. 6 Focused Animated Farm Operational KPIs
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 50) / 6;
                  final isNarrow = constraints.maxWidth < 1100;
                  final itemWidth = isNarrow ? (constraints.maxWidth - 20) / 2 : cardWidth;

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: AnimatedKpiCard(
                          title: 'Total Farms',
                          numericValue: farms.isNotEmpty ? farms.length : 1,
                          suffix: 'Units',
                          delta: 'Active',
                          isPositiveDelta: true,
                          subtitle: 'Verified facilities',
                          icon: Icons.storefront_outlined,
                          accentColor: AppColors.primary,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: AnimatedKpiCard(
                          title: 'Active Flocks',
                          numericValue: activeBatches.isNotEmpty ? activeBatches.length : 2,
                          suffix: 'Batches',
                          delta: 'Normal',
                          isPositiveDelta: true,
                          subtitle: '${NumberFormat('#,###').format(totalLiveBirds)} Live birds',
                          icon: Icons.pets_outlined,
                          accentColor: AppColors.primary,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: AnimatedKpiCard(
                          title: 'Active Health Cases',
                          numericValue: allCases.where((c) => c.status != HealthCaseStatus.closed).length,
                          suffix: 'Cases',
                          delta: liveCritical.isEmpty ? 'Stable' : 'Elevated',
                          isPositiveDelta: liveCritical.isEmpty,
                          subtitle: liveCritical.isEmpty ? 'Flocks in baseline' : 'Under observation',
                          icon: Icons.healing_outlined,
                          accentColor: liveCritical.isEmpty ? AppColors.healthy : AppColors.warning,
                          isCritical: liveCritical.isNotEmpty,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HealthScreen()),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: AnimatedKpiCard(
                          title: 'Critical Alerts',
                          numericValue: liveCritical.length,
                          suffix: 'Alerts',
                          delta: liveCritical.isEmpty ? 'Zero P1' : 'Action Req',
                          isPositiveDelta: liveCritical.isEmpty,
                          isIncreaseNegative: true,
                          subtitle: liveCritical.isEmpty ? 'No emergency alerts' : 'Veterinary review',
                          icon: Icons.error_outline_rounded,
                          accentColor: liveCritical.isEmpty ? AppColors.healthy : AppColors.critical,
                          isCritical: liveCritical.isNotEmpty,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: AnimatedKpiCard(
                          title: "Today's Mortality",
                          numericValue: todayMortality,
                          suffix: 'Birds',
                          delta: '+0.02%',
                          isPositiveDelta: todayMortality <= 5,
                          isIncreaseNegative: true,
                          subtitle: '0.04% vs 0.10% target',
                          icon: Icons.trending_down_rounded,
                          accentColor: todayMortality > 10 ? AppColors.critical : AppColors.slate700,
                          isCritical: todayMortality > 15,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: AnimatedKpiCard(
                          title: 'Prevention Actions',
                          numericValue: 2,
                          suffix: 'Pending',
                          delta: 'Biosecurity',
                          isPositiveDelta: true,
                          subtitle: 'Barrier audit ready',
                          icon: Icons.shield_outlined,
                          accentColor: AppColors.healthy,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // 3. Early Warning Regional Outbreak Advisory (Farmer View)
              const OutbreakClusterAlertCard(district: 'Nashik', isFarmerView: true),
              const SizedBox(height: 20),

              // 4. Interactive Animated Charts Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 960;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Interactive Mortality & Feed Analytics
                      Expanded(
                        flex: isWide ? 6 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 4A. Animated Mortality Trend vs 7-Day Baseline Chart
                            AnimatedChartContainer(
                              title: 'Daily Mortality Trend vs 7-Day Baseline',
                              subtitle: 'Real-time mortality logs, baseline moving average, and AI anomaly spike detection',
                              selectedTimeRange: _mortalityTimeRange,
                              onTimeRangeChanged: (range) {
                                setState(() => _mortalityTimeRange = range);
                              },
                              legendItems: const [
                                LegendItemData(label: 'Actual Mortality (Birds)', color: AppColors.critical),
                                LegendItemData(label: '7-Day Expected Baseline', color: AppColors.slate400, isDashed: true),
                              ],
                              height: 230,
                              onExport: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Exporting mortality time series CSV...')),
                                );
                              },
                              child: AnimatedLineChart(
                                yUnit: 'b',
                                maxY: 20,
                                series: [
                                  LineChartSeriesData(
                                    name: 'Actual Mortality',
                                    color: AppColors.critical,
                                    hasAreaFill: true,
                                    points: _getMortalityPoints(_mortalityTimeRange),
                                  ),
                                  LineChartSeriesData(
                                    name: '7-Day Baseline',
                                    color: AppColors.slate400,
                                    isDashed: true,
                                    hasAreaFill: false,
                                    strokeWidth: 1.8,
                                    points: _getBaselinePoints(_mortalityTimeRange),
                                  ),
                                ],
                                onPointSelected: (payload) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const HealthScreen()),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 4B. Active Flocks Status Overview
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.grid_view_rounded, size: 20, color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Text('Active Flock Status & Shed Telemetry', style: AppTypography.cardTitle),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const DailyRecordsDashboardScreen(),
                                            ),
                                          );
                                        },
                                        child: const Text('View All Records →'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFlockRow(
                                    flockName: 'Cobb 500 — Shed 1 (Batch B08)',
                                    ageDays: 24,
                                    birds: 8500,
                                    mortalityRate: '0.03%',
                                    status: 'Healthy',
                                    statusColor: AppColors.healthy,
                                  ),
                                  const Divider(height: 16),
                                  _buildFlockRow(
                                    flockName: 'Ross 308 — Shed 2 (Batch B07)',
                                    ageDays: 31,
                                    birds: 5700,
                                    mortalityRate: '0.12%',
                                    status: 'Observation',
                                    statusColor: AppColors.warning,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 4C. Biosecurity Prevention Intelligence
                            const FarmPreventionDashboardCard(
                              farmId: 'farm_gv_01',
                              farmName: 'Green Valley Poultry Farm',
                            ),
                          ],
                        ),
                      ),

                      if (isWide) const SizedBox(width: 20),

                      // Right Column: Vaccination Donut & Biosecurity Score
                      if (isWide)
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 4D. Vaccination Status Animated Donut
                              AnimatedChartContainer(
                                title: 'Flock Vaccination Adherence',
                                subtitle: 'Current batch immunization completion rate',
                                timeRanges: const [],
                                height: 210,
                                legendItems: const [
                                  LegendItemData(label: 'Completed (71%)', color: AppColors.healthy),
                                  LegendItemData(label: 'Due Soon (14%)', color: AppColors.warning),
                                  LegendItemData(label: 'Overdue (15%)', color: AppColors.critical),
                                ],
                                child: AnimatedDonutChart(
                                  centerValueNumber: 71,
                                  centerValueSuffix: '%',
                                  centerLabel: 'COMPLETED',
                                  segments: const [
                                    DonutSegmentData(label: 'Completed', value: 71, color: AppColors.healthy, payload: 'completed'),
                                    DonutSegmentData(label: 'Due Soon', value: 14, color: AppColors.warning, payload: 'due'),
                                    DonutSegmentData(label: 'Overdue', value: 15, color: AppColors.critical, payload: 'overdue'),
                                  ],
                                  onSegmentSelected: (payload) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const VaccineRecordsScreen()),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 4E. Biosecurity Score Bar & Dimension Breakdown
                              const BiosecurityScoreBar(
                                score: 76,
                                previousScore: 52,
                                ratingText: 'Tier-1 High Integrity',
                                categories: [
                                  BiosecurityCategoryItem(title: 'Visitor & Vehicle Gate Disinfection', scorePercent: 84, color: AppColors.healthy),
                                  BiosecurityCategoryItem(title: 'Shed Perimeter Isolation & Bird Proofing', scorePercent: 78, color: AppColors.healthy),
                                  BiosecurityCategoryItem(title: 'Water Chlorination & Feed Hygiene', scorePercent: 88, color: AppColors.healthy),
                                  BiosecurityCategoryItem(title: 'Daily Mortality Disposal Protocol', scorePercent: 62, color: AppColors.warning),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // 4F. Upcoming Vaccination Schedule
                              AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.vaccines_outlined, size: 20, color: AppColors.primary),
                                            const SizedBox(width: 8),
                                            Text('Vaccination Schedule', style: AppTypography.cardTitle),
                                          ],
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const VaccineRecordsScreen(),
                                              ),
                                            );
                                          },
                                          child: const Text('View All →'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _buildVaccineItem(
                                      title: 'LaSota (Newcastle Disease Booster)',
                                      flock: 'Batch B08 (Day 28)',
                                      dueDate: 'In 4 Days',
                                      status: 'Upcoming',
                                      color: AppColors.info,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildVaccineItem(
                                      title: 'Gumboro (IBD Live Vaccine)',
                                      flock: 'Batch B09 (Day 14)',
                                      dueDate: 'Tomorrow',
                                      status: 'Due Soon',
                                      color: AppColors.warning,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<ChartDataPoint> _getMortalityPoints(String range) {
    if (range == '7D') {
      return const [
        ChartDataPoint(x: 0, y: 3, label: 'Mon'),
        ChartDataPoint(x: 1, y: 4, label: 'Tue'),
        ChartDataPoint(x: 2, y: 3, label: 'Wed'),
        ChartDataPoint(x: 3, y: 5, label: 'Thu'),
        ChartDataPoint(x: 4, y: 4, label: 'Fri'),
        ChartDataPoint(x: 5, y: 15, label: 'Sat', isSpike: true, payload: 'HC-00128'),
        ChartDataPoint(x: 6, y: 6, label: 'Sun'),
      ];
    } else if (range == '30D') {
      return List.generate(30, (i) {
        final isSpike = i == 25;
        final val = isSpike ? 15.0 : (2.0 + (i % 4));
        return ChartDataPoint(x: i.toDouble(), y: val, label: 'D${i + 1}', isSpike: isSpike);
      });
    }
    return List.generate(12, (i) {
      return ChartDataPoint(x: i.toDouble(), y: 3.0 + (i % 5), label: 'W${i + 1}');
    });
  }

  List<ChartDataPoint> _getBaselinePoints(String range) {
    if (range == '7D') {
      return const [
        ChartDataPoint(x: 0, y: 3.2, label: 'Mon'),
        ChartDataPoint(x: 1, y: 3.4, label: 'Tue'),
        ChartDataPoint(x: 2, y: 3.3, label: 'Wed'),
        ChartDataPoint(x: 3, y: 3.5, label: 'Thu'),
        ChartDataPoint(x: 4, y: 3.4, label: 'Fri'),
        ChartDataPoint(x: 5, y: 3.6, label: 'Sat'),
        ChartDataPoint(x: 6, y: 3.5, label: 'Sun'),
      ];
    } else if (range == '30D') {
      return List.generate(30, (i) => ChartDataPoint(x: i.toDouble(), y: 3.5, label: 'D${i + 1}'));
    }
    return List.generate(12, (i) => ChartDataPoint(x: i.toDouble(), y: 3.5, label: 'W${i + 1}'));
  }

  Widget _buildFlockRow({
    required String flockName,
    required int ageDays,
    required int birds,
    required String mortalityRate,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.egg_outlined, color: statusColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(flockName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              Text('Age: $ageDays Days • Live: ${NumberFormat('#,###').format(birds)} Birds • Mortality: $mortalityRate', style: AppTypography.bodySmall),
            ],
          ),
        ),
        StatusBadge(
          label: status,
          backgroundColor: statusColor.withOpacity(0.12),
          color: statusColor,
        ),
      ],
    );
  }

  Widget _buildVaccineItem({
    required String title,
    required String flock,
    required String dueDate,
    required String status,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                Text('$flock • $dueDate', style: AppTypography.bodySmall),
              ],
            ),
          ),
          StatusBadge(label: status, color: color, backgroundColor: color.withOpacity(0.1)),
        ],
      ),
    );
  }
}
