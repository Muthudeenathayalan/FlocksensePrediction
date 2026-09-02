import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/features/intelligence/domain/farm_health_timeline_model.dart';

/// Reusable Farm Health Timeline Widget (Part 21)
/// Chronologically displays metric anomalies, environment shifts, visitor events, vet visits, lab results, and actions
class FarmHealthTimelineWidget extends StatelessWidget {
  final List<FarmHealthTimelineEvent> events;
  final VoidCallback? onAddEvent;

  const FarmHealthTimelineWidget({
    super.key,
    required this.events,
    this.onAddEvent,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.timeline_outlined, size: 36, color: AppColors.slate400),
                const SizedBox(height: 8),
                Text('No recent farm health events logged', style: AppTypography.bodyMedium),
                const SizedBox(height: 4),
                Text('Daily logs, visitor entries, and veterinary updates will appear here chronologically.',
                    style: AppTypography.caption),
              ],
            ),
          ),
        ),
      );
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
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history_edu_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Farm Health Timeline', style: AppTypography.headingSmall),
                      Text('Chronological telemetry, biosecurity, and clinical records', style: AppTypography.bodySmall),
                    ],
                  ),
                ],
              ),
              if (onAddEvent != null)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  tooltip: 'Record Event',
                  onPressed: onAddEvent,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Timeline List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              final event = events[index];
              final isLast = index == events.length - 1;
              return _buildTimelineItem(event, isLast);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(FarmHealthTimelineEvent event, bool isLast) {
    Color dotColor = AppColors.primary;
    IconData icon = Icons.circle;

    switch (event.eventType) {
      case TimelineEventType.daily_metric_anomaly:
        dotColor = event.severity == 'critical' ? AppColors.critical : AppColors.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case TimelineEventType.environment_event:
        dotColor = AppColors.warning;
        icon = Icons.thermostat_outlined;
        break;
      case TimelineEventType.visitor_event:
        dotColor = event.severity == 'warning' ? AppColors.critical : AppColors.info;
        icon = Icons.person_pin_circle_outlined;
        break;
      case TimelineEventType.vaccination:
        dotColor = AppColors.healthy;
        icon = Icons.vaccines_outlined;
        break;
      case TimelineEventType.health_report:
        dotColor = AppColors.critical;
        icon = Icons.report_problem_outlined;
        break;
      case TimelineEventType.risk_assessment:
        dotColor = AppColors.primary;
        icon = Icons.analytics_outlined;
        break;
      case TimelineEventType.vet_assignment:
        dotColor = AppColors.info;
        icon = Icons.medical_services_outlined;
        break;
      case TimelineEventType.lab_test:
        dotColor = AppColors.warning;
        icon = Icons.biotech_outlined;
        break;
      case TimelineEventType.diagnosis:
        dotColor = AppColors.healthy;
        icon = Icons.verified_outlined;
        break;
      case TimelineEventType.treatment:
        dotColor = AppColors.healthy;
        icon = Icons.medication_liquid_outlined;
        break;
      case TimelineEventType.cluster_warning:
        dotColor = AppColors.critical;
        icon = Icons.crisis_alert_rounded;
        break;
      case TimelineEventType.recommendation_completed:
        dotColor = AppColors.healthy;
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(event.timestamp);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Rail with Line & Dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: dotColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                  child: Icon(icon, size: 12, color: dotColor),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.slate200,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content Box
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
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
                        Expanded(
                          child: Text(
                            event.title,
                            style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: AppTypography.caption.copyWith(color: AppColors.slate500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.description,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.slate700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
