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
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/health/data/lab_test_service.dart';
import 'package:flock_sense/features/health/domain/lab_test_model.dart';
import 'package:flock_sense/features/health/presentation/screens/veterinarian_critical_queue_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/veterinarian_lab_results_screen.dart';
import 'package:flock_sense/features/health/presentation/widgets/outbreak_cluster_alert_card.dart';
import 'package:flock_sense/features/health/presentation/widgets/vet_priority_queue_card.dart';
import 'package:flock_sense/features/home/presentation/providers/veterinarian_dashboard_provider.dart';
import 'package:flock_sense/shared/analytics/animated_bar_chart.dart';
import 'package:flock_sense/shared/analytics/animated_chart_container.dart';
import 'package:flock_sense/shared/analytics/animated_kpi_card.dart';
import 'package:flock_sense/shared/analytics/animated_line_chart.dart';

/// Dedicated Veterinarian Clinical Dashboard with Animated Triage Analytics (SIH26128)
class VeterinarianDashboardScreen extends ConsumerStatefulWidget {
  final String? vetId;
  final String? district;

  const VeterinarianDashboardScreen({
    super.key,
    this.vetId,
    this.district,
  });

  @override
  ConsumerState<VeterinarianDashboardScreen> createState() => _VeterinarianDashboardScreenState();
}

class _VeterinarianDashboardScreenState extends ConsumerState<VeterinarianDashboardScreen> {
  String _responseTrendRange = '7D';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Dr. V. Sharma (Surgeon)';
    final activeVetId = widget.vetId ?? user?.uid ?? 'vet_dr_sharma';
    final vetState = ref.watch(veterinarianDashboardProvider(activeVetId));
    final districtName = widget.district ?? vetState.activeDistrict;

    final assignments = vetState.assignments;
    final labTests = vetState.labTests;
    final allCases = vetState.allCases;

    final criticalCount = vetState.criticalCount;
    final pendingReviewCount = vetState.pendingReviewCount;
    final underInvestigationCount = vetState.underInvestigationCount;
    final labResultsReadyCount = vetState.labResultsReadyCount;
    final followUpsDueCount = vetState.followUpsDueCount;
    final resolvedTodayCount = vetState.resolvedTodayCount;

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Web Page Header with Clinician Actions
          WebPageHeader(
            title: 'Veterinarian Clinical Triage Desk',
            subtitle: 'Attending: $displayName • Authorized Zone: $districtName • Real-time clinical response & diagnostic triage',
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.healthyBg,
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  border: Border.all(color: AppColors.healthy.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, size: 16, color: AppColors.healthy),
                    SizedBox(width: 6),
                    Text(
                      'Licensed Duty Clinician',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.healthy),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: 'Emergency Queue',
                icon: Icons.emergency_outlined,
                size: AppButtonSize.small,
                variant: AppButtonVariant.primary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VeterinarianCriticalQueueScreen()),
                  );
                },
              ),
            ],
          ),

          // 2. 6 Focused Clinical Animated KPIs
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
                      title: 'Critical P1 Cases',
                      numericValue: criticalCount,
                      suffix: 'Active',
                      delta: criticalCount > 0 ? 'Urgent' : 'Clear',
                      isPositiveDelta: criticalCount == 0,
                      isIncreaseNegative: true,
                      subtitle: 'Requires immediate triage',
                      icon: Icons.crisis_alert_rounded,
                      accentColor: AppColors.critical,
                      isCritical: criticalCount > 0,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VeterinarianCriticalQueueScreen()),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: AnimatedKpiCard(
                      title: 'Pending Review',
                      numericValue: pendingReviewCount,
                      suffix: 'Cases',
                      delta: 'Triage queue',
                      isPositiveDelta: true,
                      subtitle: 'District escalated reports',
                      icon: Icons.pending_actions_outlined,
                      accentColor: AppColors.warning,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: AnimatedKpiCard(
                      title: 'Under Investigation',
                      numericValue: underInvestigationCount,
                      suffix: 'Active',
                      delta: 'Field visits',
                      isPositiveDelta: true,
                      subtitle: 'Differential diagnosis ongoing',
                      icon: Icons.biotech_outlined,
                      accentColor: AppColors.info,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: AnimatedKpiCard(
                      title: 'Lab Results Ready',
                      numericValue: labResultsReadyCount,
                      suffix: 'Reports',
                      delta: 'Verified',
                      isPositiveDelta: true,
                      subtitle: 'RT-PCR & serology sign-off',
                      icon: Icons.fact_check_outlined,
                      accentColor: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VeterinarianLabResultsScreen()),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: AnimatedKpiCard(
                      title: 'Follow-Ups Due',
                      numericValue: followUpsDueCount,
                      suffix: 'Pending',
                      delta: 'Recovery',
                      isPositiveDelta: true,
                      subtitle: 'Post-treatment surveillance',
                      icon: Icons.event_repeat_outlined,
                      accentColor: AppColors.info,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: AnimatedKpiCard(
                      title: 'Resolved Today',
                      numericValue: resolvedTodayCount,
                      suffix: 'Cases',
                      delta: 'Discharged',
                      isPositiveDelta: true,
                      subtitle: 'Successful recovery closed',
                      icon: Icons.task_alt_outlined,
                      accentColor: AppColors.healthy,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // 3. Regional Outbreak Cluster Warning Banner (Attending View)
          OutbreakClusterAlertCard(district: districtName, isFarmerView: false),
          const SizedBox(height: 20),

          // 4. Clinical Triage Desk & Interactive Priority Queue
          VetPriorityQueueCard(vetId: activeVetId, district: widget.district),
          const SizedBox(height: 24),

          // 5. Interactive Clinical Analytics: Diagnostic Lab Pipeline & Response Velocity
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Average Veterinary Response Time Velocity Curve
                  Expanded(
                    flex: isWide ? 6 : 1,
                    child: AnimatedChartContainer(
                      title: 'Average Veterinary Triage & Response Velocity',
                      subtitle: 'Rolling 7-day average case acceptance time (minutes) from initial notification to clinical triage',
                      selectedTimeRange: _responseTrendRange,
                      onTimeRangeChanged: (val) => setState(() => _responseTrendRange = val),
                      legendItems: const [
                        LegendItemData(label: 'Avg Response Time (Minutes)', color: AppColors.primary),
                        LegendItemData(label: 'SLA Target (20 Min)', color: AppColors.slate400, isDashed: true),
                      ],
                      height: 230,
                      child: AnimatedLineChart(
                        yUnit: 'm',
                        maxY: 40,
                        series: [
                          LineChartSeriesData(
                            name: 'Response Velocity',
                            color: AppColors.primary,
                            hasAreaFill: true,
                            points: const [
                              ChartDataPoint(x: 0, y: 28, label: 'D1'),
                              ChartDataPoint(x: 1, y: 24, label: 'D2'),
                              ChartDataPoint(x: 2, y: 21, label: 'D3'),
                              ChartDataPoint(x: 3, y: 19, label: 'D4'),
                              ChartDataPoint(x: 4, y: 22, label: 'D5'),
                              ChartDataPoint(x: 5, y: 18, label: 'D6'),
                              ChartDataPoint(x: 6, y: 16, label: 'Today'),
                            ],
                          ),
                          LineChartSeriesData(
                            name: 'SLA Target',
                            color: AppColors.slate400,
                            isDashed: true,
                            hasAreaFill: false,
                            strokeWidth: 1.5,
                            points: const [
                              ChartDataPoint(x: 0, y: 20, label: 'D1'),
                              ChartDataPoint(x: 1, y: 20, label: 'D2'),
                              ChartDataPoint(x: 2, y: 20, label: 'D3'),
                              ChartDataPoint(x: 3, y: 20, label: 'D4'),
                              ChartDataPoint(x: 4, y: 20, label: 'D5'),
                              ChartDataPoint(x: 5, y: 20, label: 'D6'),
                              ChartDataPoint(x: 6, y: 20, label: 'Today'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (isWide) const SizedBox(width: 20),

                  // Right: Diagnostic Laboratory Pipeline Bar Chart
                  if (isWide)
                    Expanded(
                      flex: 4,
                      child: AnimatedChartContainer(
                        title: 'Diagnostic Laboratory Sample Pipeline',
                        subtitle: 'Current status distribution of clinical viral assays & necropsy samples',
                        timeRanges: const [],
                        height: 230,
                        child: AnimatedBarChart(
                          maxY: 8,
                          unit: ' spl',
                          items: const [
                            BarChartItemData(label: 'Requested', value: 4, color: AppColors.info, payload: 'requested'),
                            BarChartItemData(label: 'Collected', value: 3, color: AppColors.slate500, payload: 'collected'),
                            BarChartItemData(label: 'In Testing', value: 5, color: AppColors.warning, payload: 'testing'),
                            BarChartItemData(label: 'Ready', value: 6, color: AppColors.healthy, payload: 'ready'),
                            BarChartItemData(label: 'Signed Off', value: 2, color: AppColors.primary, payload: 'reviewed'),
                          ],
                          onItemSelected: (payload) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const VeterinarianLabResultsScreen()),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
