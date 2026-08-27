import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/metric_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/responsive_data_table.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_command_center_screen.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/health_screen.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';

/// Clean, desktop-first Web SaaS Dashboard for FlockSense
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(homeDashboardDataProvider);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Farmer';

    return dashboardAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Unable to load dashboard telemetry'),
            const SizedBox(height: 12),
            AppButton(
              label: 'Retry',
              size: AppButtonSize.small,
              onPressed: () => ref.invalidate(homeDashboardDataProvider),
            ),
          ],
        ),
      ),
      data: (data) {
        final activeBatches = ref.watch(allUserBatchesProvider).value ?? [];
        final totalBirds = data.liveBirds > 0
            ? data.liveBirds
            : activeBatches.fold<int>(0, (sum, b) => sum + b.currentBirdCount);
        final activeBatchCount = activeBatches.isNotEmpty
            ? activeBatches.where((b) => b.status == 'active').length
            : data.activeBatchCount;

        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Web Page Header with Quick Actions
              WebPageHeader(
                title: 'Operational Dashboard',
                subtitle: 'Welcome back, $displayName • Live poultry farm situation & animal health telemetry',
                actions: [
                  AppButton(
                    label: 'Add Daily Record',
                    icon: Icons.add_circle_outline_rounded,
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

              // 2. 5 Concise SaaS KPI Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Total Birds',
                          value: NumberFormat('#,###').format(totalBirds),
                          icon: Icons.pets_outlined,
                          accentColor: AppColors.primary,
                          subtitle: 'Across active flocks',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricCard(
                          title: 'Active Flocks',
                          value: '$activeBatchCount Batches',
                          icon: Icons.grid_view_outlined,
                          accentColor: AppColors.info,
                          subtitle: 'Under real-time monitoring',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricCard(
                          title: 'Health Index',
                          value: '92 / 100',
                          delta: '+1.8%',
                          isPositiveDelta: true,
                          icon: Icons.favorite_outline_rounded,
                          accentColor: AppColors.healthy,
                          subtitle: 'Biosecurity optimal',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricCard(
                          title: 'Active Alerts',
                          value: '1 Warning',
                          delta: 'Attention',
                          isPositiveDelta: false,
                          icon: Icons.notifications_active_outlined,
                          accentColor: AppColors.warning,
                          subtitle: 'Respiratory check',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricCard(
                          title: "Today's Mortality",
                          value: '${data.todayMortality} Birds',
                          delta: 'Normal',
                          isPositiveDelta: true,
                          icon: Icons.sick_outlined,
                          accentColor: data.todayMortality > 15
                              ? AppColors.critical
                              : AppColors.slate700,
                          subtitle: '0.04% daily mortality',
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // 3. Middle Two-Column Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left (60%): Farm Telemetry & Mortality Trend
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppDesign.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.activeFarm?.farmName ?? 'Primary Facility',
                                    style: AppTypography.cardTitle,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${data.activeFarm?.district ?? "Nashik"}, Maharashtra • Broiler Unit',
                                    style: AppTypography.metadata,
                                  ),
                                ],
                              ),
                              StatusBadge.fromStatus('Healthy'),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Telemetry Mini Metrics
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                              border: Border.all(color: AppColors.border, width: 1),
                            ),
                            child: Row(
                              children: [
                                _buildTelemetryItem('Shed Temp', '28.4°C', 'Optimal 26-29°C', Icons.thermostat_outlined, AppColors.healthy),
                                const VerticalDivider(width: 24, thickness: 1, color: AppColors.divider),
                                _buildTelemetryItem('Humidity', '62%', 'Standard 60-70%', Icons.water_drop_outlined, AppColors.info),
                                const VerticalDivider(width: 24, thickness: 1, color: AppColors.divider),
                                _buildTelemetryItem('Feed Intake', '480 kg', '100% Target', Icons.restaurant_outlined, AppColors.warning),
                                const VerticalDivider(width: 24, thickness: 1, color: AppColors.divider),
                                _buildTelemetryItem('Water Usage', '860 L', '2.1 L/kg ratio', Icons.local_drink_outlined, AppColors.primary),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 7-Day Mortality Trend Simulation Bar
                          const Text(
                            '7-Day Mortality & Anomaly Baseline',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 85,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildDayMortalityBar('18 Aug', 3, 20),
                                _buildDayMortalityBar('19 Aug', 4, 25),
                                _buildDayMortalityBar('20 Aug', 2, 15),
                                _buildDayMortalityBar('21 Aug', 5, 30),
                                _buildDayMortalityBar('22 Aug', 3, 20),
                                _buildDayMortalityBar('23 Aug', 4, 25),
                                _buildDayMortalityBar('Today', data.todayMortality > 0 ? data.todayMortality : 2, 15, isToday: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Right (40%): Active Alerts & Health Cases
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppDesign.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Disease Surveillance Alerts',
                                style: AppTypography.cardTitle,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const HealthScreen(),
                                    ),
                                  );
                                },
                                child: const Text('View All', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Active Alert Items
                          _buildAlertCard(
                            severity: 'CRITICAL',
                            title: 'Mortality anomaly in Batch B07',
                            time: '12 min ago',
                            farm: 'Green Valley • Shed 2',
                            color: AppColors.critical,
                            bgColor: AppColors.criticalBg,
                          ),
                          const SizedBox(height: 10),
                          _buildAlertCard(
                            severity: 'WARNING',
                            title: 'Vaccination Due: ND LaSota Booster',
                            time: 'Today, 4:00 PM',
                            farm: 'Batch B04 • Age 21d',
                            color: AppColors.warning,
                            bgColor: AppColors.warningBg,
                          ),
                          const SizedBox(height: 10),
                          _buildAlertCard(
                            severity: 'INFO',
                            title: 'Routine Feed Delivery Received',
                            time: '2 hours ago',
                            farm: 'Godrej Broiler Finisher (40 Bags)',
                            color: AppColors.info,
                            bgColor: AppColors.infoBg,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Active Flocks / Batches Table
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Flocks & Batch Telemetry',
                    style: AppTypography.sectionTitle,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.farms),
                    child: const Text('Manage Farms & Flocks →'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ResponsiveDataTable(
                columns: const [
                  ResponsiveDataColumn(label: 'Flock Name', flex: 2),
                  ResponsiveDataColumn(label: 'Breed', flex: 2),
                  ResponsiveDataColumn(label: 'Age', flex: 1),
                  ResponsiveDataColumn(label: 'Current Birds', flex: 2),
                  ResponsiveDataColumn(label: 'Cumulative Mort.', flex: 2),
                  ResponsiveDataColumn(label: 'Health Status', flex: 2),
                  ResponsiveDataColumn(label: 'Action', flex: 1, align: TextAlign.right),
                ],
                rows: activeBatches.isNotEmpty
                    ? activeBatches.map((b) {
                        final age = DateTime.now().difference(b.placementDate).inDays;
                        return ResponsiveDataRow(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BatchCommandCenterScreen(
                                  farmId: b.farmId,
                                  batchId: b.id,
                                  batchName: b.batchName,
                                ),
                              ),
                            );
                          },
                          cells: [
                            Text(b.batchName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900)),
                            Text(b.breed, style: const TextStyle(color: AppColors.slate700)),
                            Text('$age days', style: const TextStyle(color: AppColors.slate700)),
                            Text('${NumberFormat("#,###").format(b.currentBirdCount)} birds', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('${b.initialChicksCount - b.currentBirdCount} (${(((b.initialChicksCount - b.currentBirdCount) / (b.initialChicksCount > 0 ? b.initialChicksCount : 1)) * 100).toStringAsFixed(1)}%)'),
                            StatusBadge.fromStatus(b.status == 'active' ? 'Healthy' : 'Monitoring'),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BatchCommandCenterScreen(
                                      farmId: b.farmId,
                                      batchId: b.id,
                                      batchName: b.batchName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      }).toList()
                    : [
                        ResponsiveDataRow(
                          cells: [
                            const Text('Batch B07 (Cobb 500)', style: TextStyle(fontWeight: FontWeight.w600)),
                            const Text('Broiler Cobb 500'),
                            const Text('28 days'),
                            const Text('4,920 birds', style: TextStyle(fontWeight: FontWeight.w600)),
                            const Text('80 (1.6%)'),
                            StatusBadge.fromStatus('Healthy'),
                            const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.slate400),
                          ],
                        ),
                        ResponsiveDataRow(
                          cells: [
                            const Text('Batch B08 (Ross 308)', style: TextStyle(fontWeight: FontWeight.w600)),
                            const Text('Broiler Ross 308'),
                            const Text('14 days'),
                            const Text('3,500 birds', style: TextStyle(fontWeight: FontWeight.w600)),
                            const Text('35 (1.0%)'),
                            StatusBadge.fromStatus('Healthy'),
                            const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.slate400),
                          ],
                        ),
                      ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTelemetryItem(String label, String value, String target, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate900)),
          Text(target, style: const TextStyle(fontSize: 10.5, color: AppColors.slate400)),
        ],
      ),
    );
  }

  Widget _buildDayMortalityBar(String day, int count, double heightPx, {bool isToday = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isToday ? AppColors.primary : AppColors.slate600)),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: heightPx,
          decoration: BoxDecoration(
            color: isToday ? AppColors.primary : AppColors.slate300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(day, style: TextStyle(fontSize: 11, color: isToday ? AppColors.primaryDark : AppColors.slate500, fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
      ],
    );
  }

  Widget _buildAlertCard({
    required String severity,
    required String title,
    required String time,
    required String farm,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppDesign.radiusXs),
            ),
            child: Text(
              severity,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate900),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(farm, style: const TextStyle(fontSize: 11.5, color: AppColors.slate600)),
                    const Text(' • ', style: TextStyle(color: AppColors.slate400)),
                    Text(time, style: const TextStyle(fontSize: 11.5, color: AppColors.slate500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
