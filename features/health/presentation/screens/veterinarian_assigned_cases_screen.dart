import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/health/data/health_service.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/presentation/widgets/lab_diagnostic_workflow_card.dart';

/// Dedicated Screen for Veterinarian Assigned Cases (SIH26128)
class VeterinarianAssignedCasesScreen extends StatefulWidget {
  final String? vetId;

  const VeterinarianAssignedCasesScreen({
    super.key,
    this.vetId,
  });

  @override
  State<VeterinarianAssignedCasesScreen> createState() => _VeterinarianAssignedCasesScreenState();
}

class _VeterinarianAssignedCasesScreenState extends State<VeterinarianAssignedCasesScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final activeVetId = widget.vetId ?? 'vet_dr_sharma';

    return StreamBuilder<List<HealthCaseModel>>(
      stream: HealthService.streamAssignedCases(activeVetId),
      builder: (context, snapshot) {
        final cases = snapshot.data ?? [];
        final total = cases.length;
        final underInvestigation = cases.where((c) => c.status == HealthCaseStatus.under_investigation).length;
        final treatmentActive = cases.where((c) => c.status == HealthCaseStatus.treatment_started).length;
        final resolved = cases.where((c) => c.status == HealthCaseStatus.closed).length;

        final filtered = cases.where((c) {
          final matchesSearch = c.caseNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.farmName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.flockName.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesStatus = _statusFilter == 'All' || c.status.name.toLowerCase() == _statusFilter.toLowerCase();
          return matchesSearch && matchesStatus;
        }).toList();

        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WebPageHeader(
                title: 'Assigned Clinical Cases',
                subtitle: 'Cases formally assigned to your veterinary caseload • Triage, diagnosis, and treatment',
              ),

              // KPI Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 48) / 4;
                  final isNarrow = constraints.maxWidth < 800;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildKpiCard('Total Assigned', '$total Cases', Icons.assignment_ind_outlined, AppColors.primary, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Under Investigation', '$underInvestigation Active', Icons.biotech_outlined, AppColors.info, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Treatment Regimen Active', '$treatmentActive Under Care', Icons.medication_outlined, AppColors.warning, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Resolved / Closed', '$resolved Discharged', Icons.check_circle_outline, AppColors.healthy, isNarrow ? constraints.maxWidth : cardWidth),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Search & Filter
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by case ID, farm name, or flock batch...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _statusFilter,
                      underline: const SizedBox(),
                      items: ['All', 'under_investigation', 'treatment_started', 'monitoring', 'closed']
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text('Status: ${s.replaceAll('_', ' ').toUpperCase()}'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Assigned Cases Table
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Veterinary Caseload Table', style: AppTypography.cardTitle),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No assigned cases matching selected criteria.')),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 22,
                          horizontalMargin: 12,
                          columns: const [
                            DataColumn(label: Text('Case ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Farm / Facility', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Flock Batch', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Risk Tier', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Suspected Syndrome', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Affected / Dead', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Clinical Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Reported', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filtered.map((c) {
                            final dateStr = DateFormat('dd MMM, HH:mm').format(c.reportedAt);
                            return DataRow(
                              cells: [
                                DataCell(Text(c.caseNumber, style: const TextStyle(fontWeight: FontWeight.w700))),
                                DataCell(Text(c.farmName, style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(Text(c.flockName)),
                                DataCell(StatusBadge.fromStatus(c.riskLevel.name.toUpperCase())),
                                DataCell(Text(c.possibleDiseases.isNotEmpty ? c.possibleDiseases.first : (c.diagnosis ?? 'Syndromic'))),
                                DataCell(Text('${c.affectedCount} / ${c.mortalityCount}')),
                                DataCell(StatusBadge.fromStatus(c.status.name.replaceAll('_', ' ').toUpperCase())),
                                DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                                DataCell(
                                  AppButton(
                                    label: 'Inspect Dossier',
                                    size: AppButtonSize.small,
                                    variant: AppButtonVariant.outlined,
                                    onPressed: () => _openCaseDossier(c),
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

  void _openCaseDossier(HealthCaseModel c) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 760,
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
                        Row(
                          children: [
                            Text('CLINICAL DOSSIER: ${c.caseNumber}', style: AppTypography.sectionTitle),
                            const SizedBox(width: 12),
                            StatusBadge.fromStatus(c.riskLevel.name.toUpperCase()),
                          ],
                        ),
                        Text('${c.farmName} • Flock: ${c.flockName}', style: AppTypography.bodySmall),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(height: 24),
                _buildDossierField('Symptoms Detected', c.symptoms.join(', ')),
                _buildDossierField('Reported Observations', c.notes),
                _buildDossierField('Veterinarian Assessment', c.veterinarianAssessment ?? 'Initial clinical inspection pending.'),
                _buildDossierField('Confirmed Diagnosis', c.diagnosis ?? 'Preliminary differential in progress.'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: 'Order Lab Assay',
                      icon: Icons.science_outlined,
                      size: AppButtonSize.small,
                      variant: AppButtonVariant.outlined,
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'Close Dossier',
                      size: AppButtonSize.small,
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

  Widget _buildDossierField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.slate700)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontSize: 13.5, color: AppColors.slate900)),
        ],
      ),
    );
  }
}
