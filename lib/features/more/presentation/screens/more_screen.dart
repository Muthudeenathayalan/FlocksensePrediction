import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/ai/presentation/screens/ai_screen.dart';
import 'package:flock_sense/features/calendar/presentation/screens/calendar_dashboard_screen.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_list_screen.dart';
import 'package:flock_sense/features/finance/presentation/screens/finance_dashboard_screen.dart';
import 'package:flock_sense/features/inventory/presentation/screens/inventory_dashboard_screen.dart';
import 'package:flock_sense/features/notifications/presentation/screens/notification_center_screen.dart';
import 'package:flock_sense/features/performance/presentation/screens/growth_analytics_screen.dart';
import 'package:flock_sense/features/reports/presentation/screens/reports_dashboard_screen.dart';
import 'package:flock_sense/features/settings/presentation/screens/settings_dashboard_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Web Page Header
          const WebPageHeader(
            title: 'FlockSense Module Directory',
            subtitle:
                'Explore all farm operations, biometric AI predictions, financial ledgers, and governance tools.',
            breadcrumb: 'Explore / All Modules',
          ),

          // 2. Operational Modules
          AppDesign.sectionTitle('Farm Operations & Logging'),
          _buildGrid(context, [
            _ModuleItem('Farmer Dashboard', Icons.dashboard_rounded, 'Live farm overview & alerts', AppColors.primary, () => onNavigateToTab?.call(0)),
            _ModuleItem('Daily Records', Icons.assignment_rounded, 'Mortality, feed & water logs', AppColors.amber, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyRecordsDashboardScreen()))),
            _ModuleItem('My Farms & Sheds', Icons.home_work_rounded, 'Multi-facility management', AppColors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FarmListScreen()))),
            _ModuleItem('Inventory Stock', Icons.inventory_2_rounded, 'Feed silos & vaccine stock', AppColors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryDashboardScreen()))),
          ]),

          const SizedBox(height: 28),

          // 3. Analytics & Prediction Modules
          AppDesign.sectionTitle('Biometrics, AI & Financial Analytics'),
          _buildGrid(context, [
            _ModuleItem('Growth & FCR Analytics', Icons.trending_up_rounded, 'Growth curves & uniformity', AppColors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrowthAnalyticsScreen()))),
            _ModuleItem('AI Clinical Assistant', Icons.psychology_rounded, 'Symptom & disease triage', AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiScreen()))),
            _ModuleItem('Finance & BI Ledger', Icons.account_balance_wallet_rounded, 'Income, feed cost & P&L', AppColors.emerald, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceDashboardScreen()))),
            _ModuleItem('Reports & Data Export', Icons.bar_chart_rounded, 'Official PDF & Excel audit logs', AppColors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsDashboardScreen()))),
          ]),

          const SizedBox(height: 28),

          // 4. Governance & Communications
          AppDesign.sectionTitle('Schedules & Communications'),
          _buildGrid(context, [
            _ModuleItem('Calendar & Tasks', Icons.calendar_month_rounded, 'Vaccination schedule & tasks', AppColors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarDashboardScreen()))),
            _ModuleItem('Notification Center', Icons.notifications_active_rounded, 'Real-time syndromic alerts', AppColors.amber, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationCenterScreen()))),
            _ModuleItem('System Settings', Icons.settings_rounded, 'Thresholds & cloud sync', AppColors.slate700, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsDashboardScreen()))),
          ]),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<_ModuleItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1000
            ? 4
            : (constraints.maxWidth >= 600 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 2.6,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _ModuleCard(item: items[i]),
        );
      },
    );
  }
}

class _ModuleItem {
  final String label;
  final IconData icon;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModuleItem(this.label, this.icon, this.subtitle, this.color, this.onTap);
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.item});
  final _ModuleItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: item.onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppDesign.radiusMd),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.slate300),
        ],
      ),
    );
  }
}
