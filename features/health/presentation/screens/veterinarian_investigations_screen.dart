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
import 'package:flock_sense/features/health/presentation/widgets/ai_health_assessment_card.dart';

/// Dedicated Screen for Active Clinical Investigations (SIH26128)
class VeterinarianInvestigationsScreen extends StatefulWidget {
  final String? vetId;

  const VeterinarianInvestigationsScreen({
    super.key,
    this.vetId,
  });

  @override
  State<VeterinarianInvestigationsScreen> createState() => _VeterinarianInvestigationsScreenState();
}

class _VeterinarianInvestigationsScreenState extends State<VeterinarianInvestigationsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HealthCaseModel>>(
      stream: HealthService.streamHealthCases(),
      builder: (context, snapshot) {
        final allCases = snapshot.data ?? [];
        final investigating = allCases
            .where((c) => c.status == HealthCaseStatus.under_investigation || c.status == HealthCaseStatus.treatment_started)
            .toList();

        final filtered = investigating.where((c) {
          return c.caseNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.farmName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.flockName.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WebPageHeader(
                title: 'Clinical Investigations & Diagnostic Triage',
                subtitle: 'Active poultry disease differential diagnoses, clinical telemetry progression, and treatment tracking',
              ),

              // Search bar
              AppCard(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search active clinical investigations...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(height: 16),

              // Investigation cards
              if (filtered.isEmpty)
                const AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No active clinical investigations matching query.'),
                    ),
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
                                  Text(c.caseNumber, style: AppTypography.cardTitle),
                                  const SizedBox(width: 12),
                                  StatusBadge.fromStatus(c.riskLevel.name.toUpperCase()),
                                  const SizedBox(width: 8),
                                  StatusBadge.fromStatus(c.status.name.replaceAll('_', ' ').toUpperCase()),
                                ],
                              ),
                              Text(DateFormat('dd MMM yyyy, HH:mm').format(c.reportedAt), style: AppTypography.bodySmall),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('${c.farmName} • Flock: ${c.flockName} (${c.affectedCount} affected / ${c.mortalityCount} dead)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.slate200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Farmer Observation: ${c.notes}', style: AppTypography.bodySmall),
                                const SizedBox(height: 4),
                                Text(
                                  'Attending Clinician Assessment: ${c.veterinarianAssessment ?? "Physical examination and laboratory swab ordered."}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.slate900),
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
