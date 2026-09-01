import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/vaccine/data/vaccine_service.dart';
import 'package:flock_sense/features/vaccine/domain/vaccine_record_model.dart';

/// Government Prevention Page 6: Vaccination Surveillance & Immunity Gaps
/// Answers: Where are vaccination gaps increasing vulnerability?
class GovernmentVaccinationScreen extends StatefulWidget {
  const GovernmentVaccinationScreen({super.key});

  @override
  State<GovernmentVaccinationScreen> createState() =>
      _GovernmentVaccinationScreenState();
}

class _GovernmentVaccinationScreenState
    extends State<GovernmentVaccinationScreen> {
  String _searchQuery = '';
  String _selectedDistrict = 'All Districts';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VaccineRecordModel>>(
      stream: VaccineService.watchVaccineRecords('farm_01', 'flock_01'),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting && records.isEmpty;

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // State-wide coverage KPIs
        final totalScheduled = records.length;
        final stateCoverage = 78.4;
        final overdue = 12;

        // District Data Mock/Model Matrix for State Oversight
        final districtMatrix = [
          _DistrictVaccineRow(district: 'Nashik', coverage: 71.4, overdue: 4, dueSoon: 6, highRiskGaps: 3, totalBatches: 28),
          _DistrictVaccineRow(district: 'Pune', coverage: 88.2, overdue: 1, dueSoon: 8, highRiskGaps: 0, totalBatches: 34),
          _DistrictVaccineRow(district: 'Ahmednagar', coverage: 74.0, overdue: 3, dueSoon: 5, highRiskGaps: 2, totalBatches: 22),
          _DistrictVaccineRow(district: 'Dhule', coverage: 68.5, overdue: 5, dueSoon: 4, highRiskGaps: 4, totalBatches: 18),
          _DistrictVaccineRow(district: 'Jalgaon', coverage: 82.0, overdue: 2, dueSoon: 7, highRiskGaps: 1, totalBatches: 20),
          _DistrictVaccineRow(district: 'Satara', coverage: 91.5, overdue: 0, dueSoon: 9, highRiskGaps: 0, totalBatches: 26),
        ];

        final filteredDistricts = districtMatrix.where((d) {
          final matchesSearch = d.district.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesDist = _selectedDistrict == 'All Districts' || d.district == _selectedDistrict;
          return matchesSearch && matchesDist;
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
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.vaccines_outlined, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('State Vaccination Surveillance & Immunity Gap Tracking', style: AppTypography.pageTitle),
                          const SizedBox(height: 4),
                          Text(
                            'Monitor mandatory poultry immunization coverage, identify high-vulnerability vaccination gaps, and coordinate cold-chain vaccine drives.',
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
                      _buildKpiCard('State Vaccination Coverage', '${stateCoverage.toStringAsFixed(1)}%', Icons.shield_outlined, stateCoverage >= 75 ? AppColors.healthy : AppColors.critical, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Overdue Immunization Batches', '$overdue Batches', Icons.warning_amber_rounded, AppColors.critical, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('High-Risk Farms With Gaps', '10 Facilities', Icons.error_outline_rounded, AppColors.highRisk, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Districts Below 75% Target', '2 Districts', Icons.location_city_rounded, AppColors.warning, isNarrow ? constraints.maxWidth : cardWidth),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Filter Controls
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search district immunization records...',
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
                      value: _selectedDistrict,
                      underline: const SizedBox(),
                      items: ['All Districts', 'Nashik', 'Pune', 'Ahmednagar', 'Dhule', 'Jalgaon', 'Satara']
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedDistrict = v ?? 'All Districts'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // District Coverage Table
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('District Poultry Immunization Coverage & Gaps', style: AppTypography.cardTitle),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 24,
                        horizontalMargin: 12,
                        columns: const [
                          DataColumn(label: Text('District', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Immunity Coverage', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Coverage Target (80%)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Overdue Batches', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Due Next 7 Days', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('High-Risk Gaps', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Total Batches', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filteredDistricts.map((d) {
                          final isBelow = d.coverage < 75.0;
                          return DataRow(
                            cells: [
                              DataCell(Text(d.district, style: const TextStyle(fontWeight: FontWeight.w700))),
                              DataCell(
                                Row(
                                  children: [
                                    Text('${d.coverage}%', style: TextStyle(fontWeight: FontWeight.w700, color: isBelow ? AppColors.critical : AppColors.healthy)),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 50,
                                      child: LinearProgressIndicator(
                                        value: d.coverage / 100.0,
                                        backgroundColor: AppColors.slate200,
                                        valueColor: AlwaysStoppedAnimation(isBelow ? AppColors.critical : AppColors.healthy),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(StatusBadge(
                                label: isBelow ? 'BELOW TARGET' : 'COMPLIANT',
                                backgroundColor: isBelow ? AppColors.criticalBg : AppColors.healthyBg,
                                color: isBelow ? AppColors.critical : AppColors.healthy,
                              )),
                              DataCell(Text('${d.overdue}', style: TextStyle(fontWeight: d.overdue > 0 ? FontWeight.bold : FontWeight.normal, color: d.overdue > 0 ? AppColors.critical : AppColors.slate900))),
                              DataCell(Text('${d.dueSoon}')),
                              DataCell(Text('${d.highRiskGaps}', style: TextStyle(fontWeight: d.highRiskGaps > 0 ? FontWeight.bold : FontWeight.normal, color: d.highRiskGaps > 0 ? AppColors.critical : AppColors.slate900))),
                              DataCell(Text('${d.totalBatches}')),
                              DataCell(
                                AppButton(
                                  label: 'Initiate Drive',
                                  size: AppButtonSize.small,
                                  variant: AppButtonVariant.outlined,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('State ring-vaccination drive notification dispatched to ${d.district} veterinary officers.'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  },
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
}

class _DistrictVaccineRow {
  final String district;
  final double coverage;
  final int overdue;
  final int dueSoon;
  final int highRiskGaps;
  final int totalBatches;

  const _DistrictVaccineRow({
    required this.district,
    required this.coverage,
    required this.overdue,
    required this.dueSoon,
    required this.highRiskGaps,
    required this.totalBatches,
  });
}
