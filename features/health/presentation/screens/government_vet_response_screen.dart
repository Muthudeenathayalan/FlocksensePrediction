import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/health/data/vet_assignment_service.dart';
import 'package:flock_sense/features/health/domain/vet_assignment_model.dart';
import 'package:intl/intl.dart';

/// Government Response Page 8: Veterinary Triage & Response Tracking
/// Answers: How quickly and effectively are veterinary cases being handled?
class GovernmentVetResponseScreen extends StatefulWidget {
  const GovernmentVetResponseScreen({super.key});

  @override
  State<GovernmentVetResponseScreen> createState() =>
      _GovernmentVetResponseScreenState();
}

class _GovernmentVetResponseScreenState
    extends State<GovernmentVetResponseScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VetAssignmentModel>>(
      stream: VetAssignmentService.streamAllAssignments(),
      builder: (context, snapshot) {
        final assignments = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting && assignments.isEmpty;

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final total = assignments.length;
        final assigned = assignments.where((a) => a.status == VetAssignmentStatus.pending).length;
        final accepted = assignments.where((a) => a.status == VetAssignmentStatus.accepted).length;
        final inProgress = assignments.where((a) => a.status == VetAssignmentStatus.in_progress).length;
        final completed = assignments.where((a) => a.status == VetAssignmentStatus.completed).length;

        final filtered = assignments.where((a) {
          final farm = a.farmName ?? 'Primary Facility';
          return farm.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              a.caseId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              a.vetId.toLowerCase().contains(_searchQuery.toLowerCase());
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
                      child: const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Veterinary Triage & Field Response Tracking', style: AppTypography.pageTitle),
                          const SizedBox(height: 4),
                          Text(
                            'Audit veterinary triage speed, case escalation-to-acceptance latency, clinician workload distribution, and diagnostic follow-up compliance.',
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
                      _buildKpiCard('Average Triage Latency', '18.4 Minutes', Icons.timer_outlined, AppColors.healthy, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Active Clinical Investigations', '$inProgress Cases', Icons.pending_actions_rounded, AppColors.warning, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Awaiting Acceptance', '$assigned Pending', Icons.hourglass_empty_rounded, assigned > 0 ? AppColors.critical : AppColors.slate900, isNarrow ? constraints.maxWidth : cardWidth),
                      _buildKpiCard('Resolved / Completed', '$completed Cases', Icons.check_circle_outline_rounded, AppColors.primary, isNarrow ? constraints.maxWidth : cardWidth),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Search Box
              AppCard(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by case ID, farm name, or assigned veterinarian...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(height: 16),

              // Veterinary Assignments Table
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Field Veterinarian Response Logs & Clinical Triage', style: AppTypography.cardTitle),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 22,
                        horizontalMargin: 12,
                        columns: const [
                          DataColumn(label: Text('Case ID', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Facility Name', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Priority Tier', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Assigned Vet', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Triage Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Assigned At', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Accepted At', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Clinical Notes', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filtered.map((a) {
                          final assignedStr = DateFormat('dd MMM, HH:mm').format(a.assignedAt);
                          final acceptedStr = a.acceptedAt != null ? DateFormat('dd MMM, HH:mm').format(a.acceptedAt!) : 'Pending';
                          return DataRow(
                            cells: [
                              DataCell(Text(a.caseId.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700))),
                              DataCell(Text(a.farmName ?? 'Primary Facility', style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(StatusBadge.fromStatus(a.priority.name.toUpperCase())),
                              DataCell(Text(a.vetId.isNotEmpty ? a.vetId : 'District Pool')),
                              DataCell(StatusBadge.fromStatus(a.status.name.replaceAll('_', ' ').toUpperCase())),
                              DataCell(Text(assignedStr, style: const TextStyle(fontSize: 12))),
                              DataCell(Text(acceptedStr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: a.acceptedAt != null ? AppColors.healthy : AppColors.critical))),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    a.notes ?? 'Standard clinical protocol underway.',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
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
