import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';
import 'package:flock_sense/features/notifications/domain/notification_providers.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: canPop
          ? AppBar(
              title: const Text('Notification Center',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              elevation: 0,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            WebPageHeader(
              title: 'Notification Center',
              subtitle: 'Real-time syndromic surveillance alerts, vaccination reminders, and system notifications.',
              actions: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'All Alerts'),
                      Tab(text: 'Critical Disease Warnings'),
                      Tab(text: 'Operational Tasks'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'Mark All as Read',
                  icon: Icons.done_all_rounded,
                  variant: AppButtonVariant.outlined,
                  size: AppButtonSize.small,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All notifications marked as read.')),
                    );
                  },
                ),
              ],
            ),

            // 2. Tab Views
            SizedBox(
              height: 650,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllNotificationsList(),
                  _buildCriticalAlertsList(),
                  _buildTasksList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllNotificationsList() {
    return ListView(
      children: [
        _buildNotificationRow(
          title: 'Mortality anomaly detected in Batch B07',
          subtitle: 'Green Valley Farm • 15 dead birds reported in Shed #2. Feed intake down 18%. AI assessment triggered.',
          time: '12 min ago',
          variant: BadgeVariant.critical,
          isUnread: true,
        ),
        const SizedBox(height: 10),
        _buildNotificationRow(
          title: 'Vaccination Due: Newcastle Disease (LaSota Booster)',
          subtitle: 'Batch B04 has reached 28 days of age. Drinking water oral administration scheduled for today.',
          time: '1 hour ago',
          variant: BadgeVariant.warning,
          isUnread: true,
        ),
        const SizedBox(height: 10),
        _buildNotificationRow(
          title: 'Veterinarian Prescribed Electrolyte Solution',
          subtitle: 'Dr. V. Sharma added a supportive care prescription for Batch B07 following heat stress observation.',
          time: '3 hours ago',
          variant: BadgeVariant.info,
          isUnread: false,
        ),
        const SizedBox(height: 10),
        _buildNotificationRow(
          title: 'Weekly Farm Audit PDF Generated',
          subtitle: 'Your weekly performance and biosecurity audit log has been compiled and is ready for download.',
          time: 'Yesterday, 06:00 PM',
          variant: BadgeVariant.healthy,
          isUnread: false,
        ),
      ],
    );
  }

  Widget _buildCriticalAlertsList() {
    return ListView(
      children: [
        _buildNotificationRow(
          title: 'Mortality anomaly detected in Batch B07',
          subtitle: 'Green Valley Farm • 15 dead birds reported in Shed #2. Feed intake down 18%. AI assessment triggered.',
          time: '12 min ago',
          variant: BadgeVariant.critical,
          isUnread: true,
        ),
      ],
    );
  }

  Widget _buildTasksList() {
    return ListView(
      children: [
        _buildNotificationRow(
          title: 'Vaccination Due: Newcastle Disease (LaSota Booster)',
          subtitle: 'Batch B04 has reached 28 days of age. Drinking water oral administration scheduled for today.',
          time: '1 hour ago',
          variant: BadgeVariant.warning,
          isUnread: true,
        ),
      ],
    );
  }

  Widget _buildNotificationRow({
    required String title,
    required String subtitle,
    required String time,
    required BadgeVariant variant,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.surface : AppColors.slate50,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        border: Border.all(
          color: isUnread ? AppColors.primary.withOpacity(0.3) : AppColors.border,
          width: 1,
        ),
        boxShadow: isUnread ? AppDesign.subtleShadow : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(label: variant.name.toUpperCase(), variant: variant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                        color: AppColors.slate900,
                      ),
                    ),
                    Text(
                      time,
                      style: AppTypography.metadata,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.slate600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
