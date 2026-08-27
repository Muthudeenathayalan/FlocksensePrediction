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
import 'package:flock_sense/features/health/data/lab_test_service.dart';
import 'package:flock_sense/features/health/domain/lab_test_model.dart';
import 'package:flock_sense/features/health/presentation/widgets/lab_diagnostic_workflow_card.dart';

/// Dedicated Screen for Verified Laboratory Results (SIH26128)
class VeterinarianLabResultsScreen extends StatefulWidget {
  const VeterinarianLabResultsScreen({super.key});

  @override
  State<VeterinarianLabResultsScreen> createState() => _VeterinarianLabResultsScreenState();
}

class _VeterinarianLabResultsScreenState extends State<VeterinarianLabResultsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LabTestModel>>(
      stream: LabTestService.streamAllLabRequests(),
      builder: (context, snapshot) {
        final tests = snapshot.data ?? [];
        final results = tests.where((t) => t.status == LabTestStatus.result_available || t.status == LabTestStatus.reviewed).toList();

        final filtered = results.where((t) {
          return t.sampleId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.caseId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.testRequested.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WebPageHeader(
                title: 'Laboratory Diagnostic Results & Pathogen Confirmation',
                subtitle: 'Verified RT-PCR assays, pathogen isolation findings, and clinician confirmation sign-off',
              ),

              // Search bar
              AppCard(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search verified diagnostic findings by sample ID, case ID, or assay...',
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
                    child: Center(child: Text('No verified laboratory results matching query.')),
                  ),
                )
              else
                ...filtered.map((t) {
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
                                  Text(t.sampleId, style: AppTypography.cardTitle),
                                  const SizedBox(width: 12),
                                  StatusBadge.fromStatus(t.status.name.toUpperCase()),
                                ],
                              ),
                              Text('Case: ${t.caseId.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Assay: ${t.testRequested} • Specimen: ${t.sampleType}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.healthyBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Laboratory Finding: ${t.resultNotes ?? "Pathogen identification complete."}', style: AppTypography.bodySmall.copyWith(color: AppColors.slate900)),
                                if (t.vetInterpretationNotes != null && t.vetInterpretationNotes!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Clinician Sign-Off: "${t.vetInterpretationNotes}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                ],
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
