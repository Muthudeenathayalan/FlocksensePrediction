import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/health/data/biosecurity_service.dart';
import 'package:flock_sense/features/health/domain/biosecurity_assessment_model.dart';

/// Government Prevention Page 7: Biosecurity & Preventive Vulnerability
/// Answers: Where are preventable vulnerabilities highest?
class GovernmentBiosecurityScreen extends StatefulWidget {
  const GovernmentBiosecurityScreen({super.key});

  @override
  State<GovernmentBiosecurityScreen> createState() =>
      _GovernmentBiosecurityScreenState();
}

class _GovernmentBiosecurityScreenState
    extends State<GovernmentBiosecurityScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BiosecurityAssessmentModel>>(
      stream: BiosecurityService.streamAllAssessments(),
      builder: (context, snapshot) {
        final assessments = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting && assessments.isEmpty;

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final avgScore = assessments.isNotEmpty
            ? (assessments.map((a) => a.score).reduce((a, b) => a + b) / assessments.length).round()
            : 74;
        final highVulnerability = assessments.where((a) => a.score < 60).length;
        final pendingActions = assessments.map((a) => a.recommendations.length).fold<int>(0, (prev, count) => prev + count);

        final districtBiosecurityList = [
          _DistrictBioRow(district: 'Nashik', avgScore: 68, vulnerableFarms: 6, pendingActions: 14, clusterRisk: 'CRITICAL (OUT-001 Proximity)', priority: 'URGENT'),
          _DistrictBioRow(district: 'Pune', avgScore: 84, vulnerableFarms: 1, pendingActions: 4, clusterRisk: 'LOW (No active cluster)', priority: 'ROUTINE'),
          _DistrictBioRow(district: 'Ahmednagar', avgScore: 71, vulnerableFarms: 4, pendingActions: 9, clusterRisk: 'MODERATE (5km buffer)', priority: 'ELEVATED'),
          _DistrictBioRow(district: 'Dhule', avgScore: 62, vulnerableFarms: 8, pendingActions: 18, clusterRisk: 'HIGH (Border corridor)', priority: 'HIGH'),
          _DistrictBioRow(district: 'Jalgaon', avgScore: 76, vulnerableFarms: 2, pendingActions: 6, clusterRisk: 'MODERATE', priority: 'ROUTINE'),
        ];

        final filteredDistricts = districtBiosecurityList.where((d) =>
            d.district.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

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
                        color: AppColors.healthyBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_outlined, color: AppColors.healthy, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Biosecurity & Prevention Vulnerability Matrix', style: AppTypography.pageTitle),
                          const SizedBox(height: 4),
                          Text(
                            'Assess farm physical barrier integrity, water sanitation compliance, visitor logs, and perimeter bird-proofing across commercial poultry belts.',
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
                      _buildKpiCard('State Biosecurity Index', '$avgScore / 100', Icons.verified_user_outlined, avgScore >= 75 ? AppColors.healthy : AppColors.warning, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('High-Vulnerability Facilities', '$highVulnerability Farms (<60 Score)', Icons.warning_amber_rounded, AppColors.critical, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Critical Corrective Actions', '$pendingActions Directives', Icons.assignment_late_outlined, AppColors.highRisk, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Perimeter Buffer Audits', '14 Active Audits', Icons.fence_outlined, AppColors.primary, isNarrow ? constraints.maxWidth : cardWidth),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Search Filter
              AppCard(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search district biosecurity posture...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(height: 16),

              // District Biosecurity Table
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('District Physical & Sanitary Biosecurity Index', style: AppTypography.cardTitle),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 24,
                        horizontalMargin: 12,
                        columns: const [
                          DataColumn(label: Text('District', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Avg Biosecurity Score', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Vulnerable Farms', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Pending Directives', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Cluster Exposure Risk', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Prevention Priority', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filteredDistricts.map((d) {
                          final isUrgent = d.priority == 'URGENT' || d.priority == 'HIGH';
                          return DataRow(
                            cells: [
                              DataCell(Text(d.district, style: const TextStyle(fontWeight: FontWeight.w700))),
                              DataCell(
                                Row(
                                  children: [
                                    Text('${d.avgScore}/100', style: TextStyle(fontWeight: FontWeight.w700, color: d.avgScore < 70 ? AppColors.critical : AppColors.healthy)),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 45,
                                      child: LinearProgressIndicator(
                                        value: d.avgScore / 100.0,
                                        backgroundColor: AppColors.slate200,
                                        valueColor: AlwaysStoppedAnimation(d.avgScore < 70 ? AppColors.critical : AppColors.healthy),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text('${d.vulnerableFarms} Facilities', style: TextStyle(fontWeight: d.vulnerableFarms > 0 ? FontWeight.bold : FontWeight.normal, color: d.vulnerableFarms > 3 ? AppColors.critical : AppColors.slate900))),
                              DataCell(Text('${d.pendingActions} Actions')),
                              DataCell(Text(d.clusterRisk, style: TextStyle(fontSize: 12, color: d.clusterRisk.contains('CRITICAL') ? AppColors.critical : AppColors.slate900, fontWeight: FontWeight.w500))),
                              DataCell(StatusBadge(
                                label: d.priority,
                                backgroundColor: isUrgent ? AppColors.criticalBg : AppColors.healthyBg,
                                color: isUrgent ? AppColors.critical : AppColors.healthy,
                              )),
                              DataCell(
                                AppButton(
                                  label: 'Audit Report',
                                  size: AppButtonSize.small,
                                  variant: AppButtonVariant.outlined,
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Opening comprehensive sanitary biosecurity audit log for ${d.district}.'),
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

class _DistrictBioRow {
  final String district;
  final int avgScore;
  final int vulnerableFarms;
  final int pendingActions;
  final String clusterRisk;
  final String priority;

  const _DistrictBioRow({
    required this.district,
    required this.avgScore,
    required this.vulnerableFarms,
    required this.pendingActions,
    required this.clusterRisk,
    required this.priority,
  });
}
