import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/health/data/health_service.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';

/// Dedicated Screen for Case Follow-Ups & Recovery Tracking (SIH26128)
class VeterinarianFollowUpsScreen extends StatefulWidget {
  final String? vetId;

  const VeterinarianFollowUpsScreen({
    super.key,
    this.vetId,
  });

  @override
  State<VeterinarianFollowUpsScreen> createState() => _VeterinarianFollowUpsScreenState();
}

class _VeterinarianFollowUpsScreenState extends State<VeterinarianFollowUpsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HealthCaseModel>>(
      stream: HealthService.streamHealthCases(),
      builder: (context, snapshot) {
        final allCases = snapshot.data ?? [];
        final followUps = allCases.where((c) => c.status == HealthCaseStatus.treatment_started || c.status == HealthCaseStatus.monitoring).toList();

        final filtered = followUps.where((c) {
          return c.caseNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.farmName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.flockName.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WebPageHeader(
                title: 'Clinical Follow-Ups & Recovery Monitoring',
                subtitle: 'Track flock recovery progression, farmer compliance with treatment regimens, and discharge status',
              ),

              // Search bar
              AppCard(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search follow-up cases by case ID, farm name, or flock...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(height: 16),

              if (filtered.isEmpty)
                const AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No active follow-ups currently pending.')),
                  ),
                )
              else
                ...filtered.map((c) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text('Follow-Up: ${c.caseNumber}', style: AppTypography.cardTitle),
                                  const SizedBox(width: 12),
                                  StatusBadge.fromStatus(c.status.name.replaceAll('_', ' ').toUpperCase()),
                                ],
                              ),
                              Text('Reported: ${DateFormat('dd MMM').format(c.reportedAt)}', style: AppTypography.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('${c.farmName} • Flock: ${c.flockName} (${c.affectedCount} affected / ${c.mortalityCount} dead)', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.slate200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text('Recovery Progress: Stabilizing under supportive care.', style: AppTypography.bodySmall.copyWith(color: AppColors.slate900)),
                                ),
                                AppButton(
                                  label: 'Mark Resolved',
                                  size: AppButtonSize.small,
                                  variant: AppButtonVariant.outlined,
                                  onPressed: () async {
                                    await HealthService.updateCaseStatus(c.id, HealthCaseStatus.closed, vetNotes: 'Flock mortality returned to baseline. Case resolved.');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
