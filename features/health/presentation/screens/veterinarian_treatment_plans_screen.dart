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

/// Dedicated Screen for Treatment Plans & Prescriptions (SIH26128)
class VeterinarianTreatmentPlansScreen extends StatefulWidget {
  final String? vetId;

  const VeterinarianTreatmentPlansScreen({
    super.key,
    this.vetId,
  });

  @override
  State<VeterinarianTreatmentPlansScreen> createState() => _VeterinarianTreatmentPlansScreenState();
}

class _VeterinarianTreatmentPlansScreenState extends State<VeterinarianTreatmentPlansScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HealthCaseModel>>(
      stream: HealthService.streamHealthCases(),
      builder: (context, snapshot) {
        final allCases = snapshot.data ?? [];
        final withTreatment = allCases.where((c) => c.status == HealthCaseStatus.treatment_started || c.veterinarianAssessment != null).toList();

        final filtered = withTreatment.where((c) {
          return c.caseNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.farmName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.flockName.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WebPageHeader(
                title: 'Clinical Treatment Plans & Prescriptions',
                subtitle: 'Prescribed supportive care, pharmaceuticals, biosecurity cordons, and withdrawal periods',
              ),

              // Search bar
              AppCard(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search treatment plans by case ID, farm name, or medication...',
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
                    child: Center(child: Text('No active treatment plans matching query.')),
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
                                  Text('Plan for ${c.caseNumber}', style: AppTypography.cardTitle),
                                  const SizedBox(width: 12),
                                  StatusBadge.fromStatus(c.status.name.replaceAll('_', ' ').toUpperCase()),
                                ],
                              ),
                              Text('Active Care Protocol', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('${c.farmName} • Flock: ${c.flockName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.slate200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Prescription & Supportive Guidance:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                const SizedBox(height: 4),
                                Text(
                                  c.veterinarianAssessment ?? 'Standard supportive electrolyte and bio-isolation protocol.',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.slate900),
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
