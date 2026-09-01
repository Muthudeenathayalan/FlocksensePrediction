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
import 'package:flock_sense/features/health/data/escalation_service.dart';
import 'package:flock_sense/features/health/data/health_case_workflow_service.dart';
import 'package:flock_sense/features/health/domain/vet_assignment_model.dart';

/// Dedicated Screen for Unassigned District Queue Cases (SIH26128)
class VeterinarianDistrictQueueScreen extends StatefulWidget {
  final String? district;
  final String? vetId;

  const VeterinarianDistrictQueueScreen({
    super.key,
    this.district,
    this.vetId,
  });

  @override
  State<VeterinarianDistrictQueueScreen> createState() => _VeterinarianDistrictQueueScreenState();
}

class _VeterinarianDistrictQueueScreenState extends State<VeterinarianDistrictQueueScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final districtName = widget.district ?? 'Nashik';
    final activeVetId = widget.vetId ?? 'vet_dr_sharma';

    return StreamBuilder<List<VetAssignmentModel>>(
      stream: EscalationService.streamUnassignedDistrictQueue(districtName),
      builder: (context, snapshot) {
        final queue = snapshot.data ?? [];
        final filtered = queue.where((a) {
          final caseNum = a.caseNumber ?? '';
          final farm = a.farmName ?? '';
          final flock = a.flockName ?? '';
          return caseNum.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              farm.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              flock.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WebPageHeader(
                title: 'District Pool / Unassigned Cases',
                subtitle: 'Regional queue of reported cases awaiting discovery and assignment by duty veterinarians in $districtName',
              ),
              AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.hub_outlined, color: AppColors.info, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('District Veterinary Roster Discovery', style: AppTypography.cardTitle),
                          const SizedBox(height: 4),
                          Text(
                            'When automatic discovery fails or a case is escalated to district level, it enters this public queue for clinician claim and triage.',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Search bar
              AppCard(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search unassigned cases by case ID, farm name, or flock batch...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(height: 16),

              // Table
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unclaimed District Incident Queue ($districtName Zone)', style: AppTypography.cardTitle),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No unassigned cases in district queue. All active reports are assigned to attending clinicians.'),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 22,
                          horizontalMargin: 12,
                          columns: const [
                            DataColumn(label: Text('Case ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Farm Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Flock', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Priority Tier', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Affected / Dead', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Waiting Time', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filtered.map((a) {
                            final waitingMins = DateTime.now().difference(a.assignedAt).inMinutes;
                            return DataRow(
                              cells: [
                                DataCell(Text(a.caseNumber ?? 'HC-UNASSIGNED', style: const TextStyle(fontWeight: FontWeight.w700))),
                                DataCell(Text(a.farmName ?? 'District Farm', style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(Text(a.flockName ?? 'Flock')),
                                DataCell(StatusBadge.fromStatus(a.priorityLevel.name.toUpperCase())),
                                DataCell(Text('${a.affectedCount} / ${a.mortalityCount}')),
                                DataCell(Text('$waitingMins mins waiting', style: const TextStyle(fontSize: 12))),
                                DataCell(
                                  AppButton(
                                    label: 'Claim & Accept',
                                    icon: Icons.check_circle_outline,
                                    size: AppButtonSize.small,
                                    onPressed: () async {
                                      final res = await HealthCaseWorkflowService.acceptCase(
                                        caseId: a.caseId,
                                        vetId: activeVetId,
                                        vetName: 'Dr. V. Sharma (Surgeon)',
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(res.message),
                                            backgroundColor: res.success ? AppColors.healthy : AppColors.critical,
                                          ),
                                        );
                                      }
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
}
