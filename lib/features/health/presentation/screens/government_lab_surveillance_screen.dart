import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/health/data/lab_test_service.dart';
import 'package:flock_sense/features/health/domain/lab_test_model.dart';
import 'package:intl/intl.dart';

/// Government Response Page 9: Laboratory Diagnostic Surveillance
/// Answers: What is the diagnostic pipeline status?
class GovernmentLabSurveillanceScreen extends StatefulWidget {
  const GovernmentLabSurveillanceScreen({super.key});

  @override
  State<GovernmentLabSurveillanceScreen> createState() =>
      _GovernmentLabSurveillanceScreenState();
}

class _GovernmentLabSurveillanceScreenState
    extends State<GovernmentLabSurveillanceScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LabTestModel>>(
      stream: LabTestService.streamAllLabRequests(),
      builder: (context, snapshot) {
        final tests = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting && tests.isEmpty;

        final totalTests = tests.length;
        final inTransit = tests.where((t) => t.status == LabTestStatus.dispatched).length;
        final inTesting = tests.where((t) => t.status == LabTestStatus.testing || t.status == LabTestStatus.received).length;
        final completed = tests.where((t) => t.status == LabTestStatus.result_available || t.status == LabTestStatus.reviewed).length;

        final filtered = tests.where((t) {
          return t.sampleId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.testRequested.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.caseId.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesign.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description banner
              AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: const Icon(Icons.science_outlined, color: Color(0xFF4F46E5), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Laboratory Diagnostic Pipeline & Pathogen Surveillance', style: AppTypography.pageTitle),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF86EFAC)),
                                ),
                                child: const Text(
                                  'DAHD • PATHOGEN DIAGNOSTICS & RT-PCR',
                                  style: TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Centralized diagnostic sample tracking, cold-chain receipt verification, RT-PCR viral panel assays, and confirmed laboratory findings.',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // KPI Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 48) / 4;
                  final isNarrow = constraints.maxWidth < 800;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildKpiCard('Total Diagnostic Requests', '$totalTests Specimens', Icons.biotech_outlined, const Color(0xFF15803D), isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Samples In Transit (Cold-Chain)', '$inTransit Dispatched', Icons.local_shipping_outlined, AppColors.warning, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Active Laboratory Assays', '$inTesting in Processing', Icons.hourglass_top_rounded, const Color(0xFF4F46E5), isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Diagnostic Results Ready', '$completed Confirmed', Icons.fact_check_outlined, AppColors.healthy, isNarrow ? constraints.maxWidth : cardWidth),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Search Filter
              AppCard(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by sample ID (SMP-...), test type (RT-PCR), or case ID...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(height: 16),

              // Laboratory Diagnostic Table
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Diagnostic Samples & Viral Identification Queue', style: AppTypography.cardTitle),
                    const SizedBox(height: 12),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        horizontalMargin: 12,
                        columns: const [
                          DataColumn(label: Text('Sample ID', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Case ID', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Specimen Type', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Requested Assay', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Destination Lab', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Pipeline Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Requested At', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((t) {
                          final reqStr = DateFormat('dd MMM, HH:mm').format(t.requestedAt);
                          final isUrgent = t.priority.toLowerCase() == 'urgent';
                          final destLab = (t.destinationLab != null && t.destinationLab!.isNotEmpty) ? t.destinationLab! : 'Central Diagnostic Lab';
                          return DataRow(
                            cells: [
                              DataCell(Text(t.sampleId, style: const TextStyle(fontWeight: FontWeight.w700))),
                              DataCell(Text(t.caseId.toUpperCase())),
                              DataCell(Text(t.sampleType)),
                              DataCell(Text(t.testRequested, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(StatusBadge(
                                label: t.priority.toUpperCase(),
                                backgroundColor: isUrgent ? AppColors.criticalBg : AppColors.slate100,
                                color: isUrgent ? AppColors.critical : AppColors.slate900,
                              )),
                              DataCell(Text(destLab)),
                              DataCell(StatusBadge.fromStatus(t.status.name.toUpperCase())),
                              DataCell(Text(reqStr, style: const TextStyle(fontSize: 12))),
                              DataCell(
                                AppButton(
                                  label: 'Inspect Result',
                                  size: AppButtonSize.small,
                                  variant: AppButtonVariant.outlined,
                                  onPressed: () => _openLabModal(t),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, double width) {
    return SizedBox(
      width: width,
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.kpiLabel),
                  const SizedBox(height: 2),
                  Text(value, style: AppTypography.cardTitle.copyWith(color: AppColors.slate900, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLabModal(LabTestModel t) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 680,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DIAGNOSTIC DOSSIER: ${t.sampleId}', style: AppTypography.sectionTitle),
                        Text('Case ${t.caseId} • ${t.destinationLab}', style: AppTypography.bodySmall),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(height: 24),
                _buildModalDetailRow('Requested Assay', t.testRequested),
                _buildModalDetailRow('Sample Specimen', '${t.sampleType} (${t.sampleQuantity ?? '4 Vials'})'),
                _buildModalDetailRow('Packaging / Cold Chain', t.packagingCondition ?? 'Insulated box with dry ice packs'),
                _buildModalDetailRow('Requested By', t.requestedBy),
                _buildModalDetailRow('Current Status', t.status.name.toUpperCase()),
                _buildModalDetailRow('Diagnostic Finding Notes', t.resultNotes ?? 'Viral RNA extraction completed; RT-PCR amplification in progress.'),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: 'Close Dossier',
                      variant: AppButtonVariant.outlined,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 180, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.slate900, fontSize: 13))),
        ],
      ),
    );
  }
}
