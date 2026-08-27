import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/health/presentation/widgets/vet_priority_queue_card.dart';

/// Dedicated Screen for Veterinarian Critical Priority Queue & Emergency Triage
class VeterinarianCriticalQueueScreen extends StatelessWidget {
  final String? vetId;
  final String? district;

  const VeterinarianCriticalQueueScreen({
    super.key,
    this.vetId,
    this.district,
  });

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebPageHeader(
            title: 'Critical Emergency Triage Queue',
            subtitle: 'Priority-1 health cases requiring immediate clinical intervention and isolation protocols',
          ),
          AppCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.criticalBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.emergency_outlined, color: AppColors.critical, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emergency Response Protocol Active', style: AppTypography.cardTitle),
                      const SizedBox(height: 4),
                      Text(
                        'Cases in this queue exhibit severe mortality escalation (>4× shed baseline) or respiratory distress syndromes with high contagion velocity.',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          VetPriorityQueueCard(
            vetId: vetId ?? 'vet_dr_sharma',
            district: district ?? 'Nashik',
          ),
        ],
      ),
    );
  }
}
