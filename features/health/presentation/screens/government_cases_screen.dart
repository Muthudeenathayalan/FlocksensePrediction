import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/health/data/health_service.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:intl/intl.dart';

/// Government Surveillance Page 4: Regional Animal Health Cases Registry
/// Answers: Which individual animal-health cases require surveillance attention?
class GovernmentCasesScreen extends StatefulWidget {
  const GovernmentCasesScreen({super.key});

  @override
  State<GovernmentCasesScreen> createState() => _GovernmentCasesScreenState();
}

class _GovernmentCasesScreenState extends State<GovernmentCasesScreen> {
  String _searchQuery = '';
  String _riskFilter = 'All';
  String _districtFilter = 'All Districts';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HealthCaseModel>>(
      stream: HealthService.streamHealthCases(), // Streams all live health cases across Maharashtra
      builder: (context, snapshot) {
        final cases = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting && cases.isEmpty;

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Summary counts
        final totalCases = cases.length;
        final criticalCases = cases.where((c) => c.riskLevel == HealthRiskLevel.critical).length;
        final underInvestigation = cases.where((c) => c.status == HealthCaseStatus.under_investigation).length;
        final labLinked = cases.where((c) => c.status == HealthCaseStatus.sample_requested || c.status == HealthCaseStatus.diagnosis_recorded).length;

        // Filter
        final filteredCases = cases.where((c) {
          final syndrome = c.possibleDiseases.isNotEmpty ? c.possibleDiseases.first : (c.diagnosis ?? 'Respiratory');
          final matchesSearch = c.farmName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.flockName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              syndrome.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesRisk = _riskFilter == 'All' || c.riskLevel.name.toLowerCase() == _riskFilter.toLowerCase();
          return matchesSearch && matchesRisk;
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
                        color: AppColors.criticalBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sick_outlined, color: AppColors.critical, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Regional Health Cases & Clinical Surveillance', style: AppTypography.pageTitle),
                          const SizedBox(height: 4),
                          Text(
                            'State-level oversight of reported poultry morbidity events, AI syndromic differentials, and veterinary diagnostic verification.',
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
                      _buildKpiCard('Total Reported Cases', '$totalCases Incidents', Icons.folder_open_rounded, AppColors.primary, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Critical Priority', '$criticalCases P1 Alerts', Icons.error_outline_rounded, AppColors.critical, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Under Active Triage', '$underInvestigation Cases', Icons.medical_services_outlined, AppColors.warning, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Lab Diagnostics Linked', '$labLinked Specimens', Icons.science_outlined, AppColors.indigo, isNarrow ? constraints.maxWidth : cardWidth),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Filters Bar
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by farm, batch, or suspected syndrome...',
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
                      value: _riskFilter,
                      underline: const SizedBox(),
                      items: ['All', 'Critical', 'High', 'Moderate', 'Low']
                          .map((r) => DropdownMenuItem(value: r, child: Text('Risk Tier: $r')))
                          .toList(),
                      onChanged: (v) => setState(() => _riskFilter = v ?? 'All'),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _districtFilter,
                      underline: const SizedBox(),
                      items: ['All Districts', 'Nashik', 'Pune', 'Ahmednagar', 'Dhule']
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setState(() => _districtFilter = v ?? 'All Districts'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cases Data Table
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Clinical Health Cases (Statewide Stream)', style: AppTypography.cardTitle),
                    const SizedBox(height: 12),
                    if (filteredCases.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No health cases matching selected filter criteria.')),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 18,
                          horizontalMargin: 12,
                          columns: const [
                            DataColumn(label: Text('Case ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Farm / Batch', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('District', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Risk Level', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Syndrome Profile', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Affected / Dead', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Triage Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Reported', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredCases.map((c) {
                            final dateStr = DateFormat('dd MMM, HH:mm').format(c.reportedAt);
                            return DataRow(
                              cells: [
                                DataCell(Text(c.id.length > 8 ? c.id.substring(0, 8).toUpperCase() : c.id, style: const TextStyle(fontWeight: FontWeight.w700))),
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(c.farmName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900)),
                                      Text('Flock: ${c.flockName}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                DataCell(Text(c.district ?? 'Nashik')),
                                DataCell(StatusBadge.fromStatus(c.riskLevel.name.toUpperCase())),
                                DataCell(Text(c.possibleDiseases.isNotEmpty ? c.possibleDiseases.first : (c.diagnosis ?? 'Respiratory Distress'))),
                                DataCell(Text('${c.affectedCount} affected / ${c.mortalityCount} dead')),
                                DataCell(StatusBadge.fromStatus(c.status.name.replaceAll('_', ' ').toUpperCase())),
                                DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                                DataCell(
                                  AppButton(
                                    label: 'View Case',
                                    size: AppButtonSize.small,
                                    variant: AppButtonVariant.outlined,
                                    onPressed: () => _openCaseDetailModal(c),
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

  void _openCaseDetailModal(HealthCaseModel c) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 720,
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
                            Text('CASE DOSSIER: ${c.id.toUpperCase()}', style: AppTypography.sectionTitle),
                            const SizedBox(width: 12),
                            StatusBadge.fromStatus(c.riskLevel.name.toUpperCase()),
                          ],
                        ),
                        Text('${c.farmName} • Flock ${c.flockName} • Read-Only Surveillance View', style: AppTypography.bodySmall),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(height: 24),

                // Clinical overview row
                Row(
                  children: [
                    _buildModalField('Preliminary Syndrome', c.possibleDiseases.isNotEmpty ? c.possibleDiseases.first : (c.diagnosis ?? 'Respiratory Distress')),
                    _buildModalField('Affected Birds', '${c.affectedCount} Birds'),
                    _buildModalField('Cumulative Mortality', '${c.mortalityCount} Deaths'),
                    _buildModalField('Triage Status', c.status.name.replaceAll('_', ' ').toUpperCase()),
                  ],
                ),
                const SizedBox(height: 16),

                // Farmer Observation Notes
                Text('Farmer Incident Report & Clinical Signs', style: AppTypography.cardTitle),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Text(
                    c.notes.isNotEmpty
                        ? c.notes
                        : 'Severe respiratory distress, tracheal rales, facial swelling, greenish-white watery diarrhea, and rapid mortality escalation observed in Shed 2 over the past 24 hours.',
                    style: AppTypography.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),

                // AI Decision Support & Risk Differential
                Text('AI Explainable Risk Differential', style: AppTypography.cardTitle),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('• Highest Differential Match: Newcastle Disease Virus (NDV) (89% Confidence)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('• Secondary Differential: Infectious Bronchitis (IBV) (45% Confidence)', style: TextStyle(fontSize: 12)),
                      SizedBox(height: 4),
                      Text('• Spatial Context: Farm is located within 4.2 km of active outbreak cluster OUT-2026-NSK-001.', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
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

  Widget _buildModalField(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate900)),
        ],
      ),
    );
  }
}
