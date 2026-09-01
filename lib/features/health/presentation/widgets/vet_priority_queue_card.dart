import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/health/data/escalation_service.dart';
import 'package:flock_sense/features/health/data/health_case_workflow_service.dart';
import 'package:flock_sense/features/health/data/health_service.dart';
import 'package:flock_sense/features/health/domain/case_follow_up_model.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/lab_test_model.dart';
import 'package:flock_sense/features/health/domain/treatment_plan_model.dart';
import 'package:flock_sense/features/health/domain/vet_assignment_model.dart';
import 'package:flock_sense/features/health/domain/vet_clinical_assessment_model.dart';
import 'package:flock_sense/features/health/presentation/widgets/ai_health_assessment_card.dart';
import 'package:flock_sense/features/health/presentation/widgets/explainable_risk_breakdown_card.dart';
import 'package:flock_sense/features/health/presentation/widgets/lab_diagnostic_workflow_card.dart';
import 'package:flock_sense/features/health/presentation/widgets/outbreak_cluster_alert_card.dart';

/// Professional Web SaaS Veterinarian Priority Queue (SIH26128 Phase 5)
class VetPriorityQueueCard extends StatefulWidget {
  final String? vetId;
  final String? district;

  const VetPriorityQueueCard({
    super.key,
    this.vetId,
    this.district,
  });

  @override
  State<VetPriorityQueueCard> createState() => _VetPriorityQueueCardState();
}

class _VetPriorityQueueCardState extends State<VetPriorityQueueCard> {
  String _selectedFilter = 'all'; // 'all', 'critical', 'urgent', 'unassigned'

  @override
  Widget build(BuildContext context) {
    final districtName = widget.district ?? 'Nashik Division';

    return StreamBuilder<List<VetAssignmentModel>>(
      stream: EscalationService.streamVetPriorityQueue(
        vetId: widget.vetId,
        district: widget.district,
      ),
      builder: (context, snapshot) {
        final assignments = snapshot.data ?? [];
        final criticalCount = assignments.where((a) => a.priorityLevel == VetPriorityLevel.critical).length;
        final urgentCount = assignments.where((a) => a.priorityLevel == VetPriorityLevel.urgent).length;
        final unassignedCount = assignments.where((a) => a.isUnassigned).length;
        final assignedTodayCount = assignments.where((a) => a.assignedAt.day == DateTime.now().day).length;

        List<VetAssignmentModel> filteredList = assignments;
        if (_selectedFilter == 'critical') {
          filteredList = assignments.where((a) => a.priorityLevel == VetPriorityLevel.critical).toList();
        } else if (_selectedFilter == 'urgent') {
          filteredList = assignments.where((a) => a.priorityLevel == VetPriorityLevel.urgent).toList();
        } else if (_selectedFilter == 'unassigned') {
          filteredList = assignments.where((a) => a.isUnassigned).toList();
        }

        return Container(
          decoration: AppDesign.cardDecoration,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header & District Context
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.emergency_outlined, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Veterinarian Priority Queue & Triage Desk',
                            style: AppTypography.cardTitle,
                          ),
                          Row(
                            children: [
                              Text('Active Surveillance Zone: ', style: AppTypography.metadata),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.slate100,
                                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  districtName.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('• Phase 5 Automated Escalation', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.healthyBg,
                      borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                      border: Border.all(color: AppColors.healthy.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.healthy, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text(
                          'REAL-TIME QUEUE ACTIVE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.healthy),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. KPI Summary Bar (Specific to Triage & Escalation)
              Row(
                children: [
                  _buildKpiCard('Critical Triage Cases', criticalCount.toString(), 'Requires immediate action', AppColors.critical, AppColors.criticalBg, Icons.crisis_alert_rounded),
                  const SizedBox(width: 16),
                  _buildKpiCard('Urgent Review Cases', urgentCount.toString(), 'High risk anomaly reported', AppColors.warning, AppColors.warningBg, Icons.notification_important_outlined),
                  const SizedBox(width: 16),
                  _buildKpiCard('District Queue (Unassigned)', unassignedCount.toString(), 'Awaiting duty vet assignment', AppColors.info, AppColors.infoBg, Icons.inbox_outlined),
                  const SizedBox(width: 16),
                  _buildKpiCard('Cases Assigned Today', assignedTodayCount.toString(), 'Rolling 24h escalation count', AppColors.primary, AppColors.primaryLight.withOpacity(0.3), Icons.assignment_turned_in_outlined),
                ],
              ),
              const SizedBox(height: 20),

              // 2B. Regional Outbreak Early Warning Banner (Phase 8 Cluster Engine)
              OutbreakClusterAlertCard(district: districtName, isFarmerView: false),
              const SizedBox(height: 24),

              // 3. Filter Bar & Search
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildFilterChip('All Active Queue (${assignments.length})', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Critical ($criticalCount)', 'critical', isCritical: true),
                      const SizedBox(width: 8),
                      _buildFilterChip('Urgent ($urgentCount)', 'urgent'),
                      const SizedBox(width: 8),
                      _buildFilterChip('District Queue ($unassignedCount)', 'unassigned'),
                    ],
                  ),
                  const Text(
                    'Sorted by Priority Score & Oldest Waiting Time',
                    style: TextStyle(fontSize: 12, color: AppColors.slate500, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Data Table
              if (filteredList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.healthy),
                      SizedBox(height: 12),
                      Text('No pending escalated cases in this filter.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.slate700)),
                      SizedBox(height: 4),
                      Text('All health reports in Nashik Division are currently triaged or under active management.', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                    ],
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                    ),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(AppColors.slate100),
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.slate700),
                      dataRowColor: MaterialStateProperty.resolveWith((states) => Colors.white),
                      horizontalMargin: 16,
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(label: Text('TRIAGE PRIORITY')),
                        DataColumn(label: Text('CASE ID')),
                        DataColumn(label: Text('FARM & FLOCK')),
                        DataColumn(label: Text('RISK SCORE')),
                        DataColumn(label: Text('MORTALITY / AFFECTED')),
                        DataColumn(label: Text('WAITING TIME')),
                        DataColumn(label: Text('ASSIGNMENT STATUS')),
                        DataColumn(label: Text('ACTION')),
                      ],
                      rows: filteredList.map((assignment) {
                        return DataRow(
                          cells: [
                            // 1. Triage Priority Badge
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: assignment.priorityLevel.bg,
                                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                                  border: Border.all(color: assignment.priorityLevel.color.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(color: assignment.priorityLevel.color, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${assignment.priorityLevel.name.toUpperCase()} (${assignment.priorityScore})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: assignment.priorityLevel.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 2. Case ID
                            DataCell(
                              Text(
                                assignment.caseNumber ?? (assignment.caseId.length > 10 ? assignment.caseId.substring(0, 10) : assignment.caseId),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.slate900),
                              ),
                            ),

                            // 3. Farm & Flock
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    assignment.farmName ?? 'Poultry Farm',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.slate900),
                                  ),
                                  Text(
                                    assignment.flockName ?? 'Batch B07',
                                    style: AppTypography.metadata,
                                  ),
                                ],
                              ),
                            ),

                            // 4. Risk Score
                            DataCell(
                              Row(
                                children: [
                                  Text(
                                    '${assignment.priority.name.toUpperCase()} ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: assignment.priority == HealthRiskLevel.critical ? AppColors.critical : AppColors.warning,
                                    ),
                                  ),
                                  Text(
                                    '(${assignment.priorityScore}/100)',
                                    style: const TextStyle(fontSize: 11, color: AppColors.slate600),
                                  ),
                                ],
                              ),
                            ),

                            // 5. Mortality / Affected
                            DataCell(
                              Text(
                                '${assignment.mortalityCount} dead • ${assignment.affectedCount} affected',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: assignment.mortalityCount > 10 ? FontWeight.w700 : FontWeight.w500,
                                  color: assignment.mortalityCount > 10 ? AppColors.critical : AppColors.slate800,
                                ),
                              ),
                            ),

                            // 6. Dynamic Waiting Time
                            DataCell(
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.slate400),
                                  const SizedBox(width: 6),
                                  Text(
                                    EscalationService.formatWaitingTime(assignment.assignedAt),
                                    style: const TextStyle(fontSize: 12, color: AppColors.slate700, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),

                            // 7. Assignment Status
                            DataCell(
                              assignment.isUnassigned
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.infoBg,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.info.withOpacity(0.3)),
                                      ),
                                      child: const Text('District Queue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.info)),
                                    )
                                  : Row(
                                      children: [
                                        const Icon(Icons.person_pin_circle_outlined, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(assignment.vetName ?? 'Assigned Vet', style: const TextStyle(fontSize: 12, color: AppColors.slate800)),
                                      ],
                                    ),
                            ),

                            // 8. Action Button
                            DataCell(
                              AppButton(
                                label: 'View Dossier',
                                icon: Icons.visibility_outlined,
                                size: AppButtonSize.small,
                                onPressed: () {
                                  _openCaseDossierPreview(context, assignment);
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, Color color, Color bg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                  const SizedBox(height: 2),
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate800)),
                  Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.slate500), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {bool isCritical = false}) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(AppDesign.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (isCritical ? AppColors.critical : AppColors.primary) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDesign.radiusSm),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.slate700,
          ),
        ),
      ),
    );
  }

  void _openCaseDossierPreview(BuildContext context, VetAssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (ctx) => _VetCaseDossierPreviewModal(assignment: assignment),
    );
  }
}

/// Authoritative Veterinarian Clinical Investigation & Triage Dossier (SIH26128 Phase 6)
class _VetCaseDossierPreviewModal extends StatefulWidget {
  final VetAssignmentModel assignment;

  const _VetCaseDossierPreviewModal({required this.assignment});

  @override
  State<_VetCaseDossierPreviewModal> createState() => _VetCaseDossierPreviewModalState();
}

class _VetCaseDossierPreviewModalState extends State<_VetCaseDossierPreviewModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleAcceptCase(HealthCaseModel healthCase) async {
    setState(() => _isActionInProgress = true);
    final vetName = (widget.assignment.vetName?.isNotEmpty ?? false) ? widget.assignment.vetName! : 'Dr. Ramesh Patil';
    final result = await HealthCaseWorkflowService.acceptCase(
      caseId: healthCase.id,
      vetId: widget.assignment.vetId.isNotEmpty ? widget.assignment.vetId : 'vet_district_01',
      vetName: vetName,
    );

    if (mounted) {
      setState(() => _isActionInProgress = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppColors.primary : AppColors.critical,
        ),
      );
    }
  }

  void _openAssessmentDialog(HealthCaseModel healthCase) {
    final vetName = (widget.assignment.vetName?.isNotEmpty ?? false) ? widget.assignment.vetName! : 'Dr. Ramesh Patil';
    showDialog(
      context: context,
      builder: (ctx) => _AssessmentFormDialog(
        healthCase: healthCase,
        vetId: widget.assignment.vetId.isNotEmpty ? widget.assignment.vetId : 'vet_district_01',
        vetName: vetName,
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _openLabRequestDialog(HealthCaseModel healthCase) {
    final vetName = (widget.assignment.vetName?.isNotEmpty ?? false) ? widget.assignment.vetName! : 'Dr. Ramesh Patil';
    showDialog(
      context: context,
      builder: (ctx) => _LabRequestDialog(
        healthCase: healthCase,
        vetId: widget.assignment.vetId.isNotEmpty ? widget.assignment.vetId : 'vet_district_01',
        vetName: vetName,
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _openTreatmentPlanDialog(HealthCaseModel healthCase) {
    showDialog(
      context: context,
      builder: (ctx) => _TreatmentPlanDialog(
        healthCase: healthCase,
        vetId: widget.assignment.vetId.isNotEmpty ? widget.assignment.vetId : 'vet_district_01',
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _openAIFeedbackDialog(HealthCaseModel healthCase) {
    showDialog(
      context: context,
      builder: (ctx) => _AIFeedbackDialog(
        caseId: healthCase.id,
        vetId: widget.assignment.vetId.isNotEmpty ? widget.assignment.vetId : 'vet_district_01',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
      child: Container(
        width: 960,
        height: 780,
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<HealthCaseModel?>(
          stream: HealthService.streamCaseById(widget.assignment.caseId),
          builder: (context, snapshot) {
            final healthCase = snapshot.data ??
                HealthCaseModel(
                  id: widget.assignment.caseId,
                  caseNumber: widget.assignment.caseNumber ?? 'HC-2026-00128',
                  farmId: widget.assignment.farmId,
                  farmName: widget.assignment.farmName ?? 'Poultry Facility',
                  flockId: widget.assignment.flockId ?? 'Batch',
                  flockName: widget.assignment.flockName ?? 'Flock',
                  district: widget.assignment.district ?? 'Nashik',
                  affectedCount: widget.assignment.affectedCount,
                  mortalityCount: widget.assignment.mortalityCount,
                  symptoms: widget.assignment.symptoms,
                  riskScore: widget.assignment.priorityScore,
                  riskLevel: widget.assignment.priority,
                  status: HealthCaseStatus.vet_required,
                  notes: widget.assignment.notes ?? '',
                  reportedAt: widget.assignment.assignedAt,
                  updatedAt: widget.assignment.assignedAt,
                );

            final isAccepted = healthCase.status != HealthCaseStatus.reported &&
                healthCase.status != HealthCaseStatus.risk_assessed &&
                healthCase.status != HealthCaseStatus.vet_required;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Banner
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: widget.assignment.priorityLevel.bg,
                            borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                            border: Border.all(color: widget.assignment.priorityLevel.color.withOpacity(0.35)),
                          ),
                          child: Icon(Icons.medical_services_rounded, color: widget.assignment.priorityLevel.color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Clinical Dossier • ${healthCase.caseNumber}', style: AppTypography.sectionTitle),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: widget.assignment.priorityLevel.bg,
                                    borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                                    border: Border.all(color: widget.assignment.priorityLevel.color),
                                  ),
                                  child: Text(
                                    '${widget.assignment.priorityLevel.name.toUpperCase()} (PRIORITY: ${widget.assignment.priorityScore})',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: widget.assignment.priorityLevel.color),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge.fromStatus(healthCase.status.name),
                              ],
                            ),
                            Text(
                              '${healthCase.farmName} • ${healthCase.flockName} (${widget.assignment.district ?? "Nashik"})',
                              style: AppTypography.metadata,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (!isAccepted)
                          AppButton(
                            label: 'Accept Case',
                            icon: Icons.check_circle_outline,
                            size: AppButtonSize.small,
                            onPressed: _isActionInProgress ? null : () => _handleAcceptCase(healthCase),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified, size: 14, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text('Case Accepted / In Investigation', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Clinical Tabs
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.slate600,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: const [
                    Tab(icon: Icon(Icons.dashboard_outlined, size: 16), text: 'Triage & AI Insights'),
                    Tab(icon: Icon(Icons.rate_review_outlined, size: 16), text: 'Veterinary Assessment'),
                    Tab(icon: Icon(Icons.biotech_outlined, size: 16), text: 'Diagnostic Lab'),
                    Tab(icon: Icon(Icons.assignment_turned_in_outlined, size: 16), text: 'Management & Treatment'),
                    Tab(icon: Icon(Icons.timeline_outlined, size: 16), text: 'Follow-Up & Timeline'),
                  ],
                ),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 14),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Triage & AI Insights
                      _buildTriageTab(healthCase),

                      // Tab 2: Veterinary Clinical Assessment
                      _buildAssessmentTab(healthCase, isAccepted),

                      // Tab 3: Diagnostic Lab
                      _buildLabTab(healthCase, isAccepted),

                      // Tab 4: Treatment & Management
                      _buildTreatmentTab(healthCase, isAccepted),

                      // Tab 5: Follow-Up & Timeline
                      _buildTimelineTab(healthCase),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),

                // Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.feedback_outlined, size: 14),
                          label: const Text('AI Decision Feedback'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () => _openAIFeedbackDialog(healthCase),
                        ),
                        const SizedBox(width: 8),
                        if (healthCase.status == HealthCaseStatus.treatment_started)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.monitor_heart_outlined, size: 14),
                            label: const Text('Move to Monitoring'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () async {
                              await HealthCaseWorkflowService.moveToMonitoring(
                                caseId: healthCase.id,
                                vetId: widget.assignment.vetId,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Case transitioned to post-treatment monitoring.'), backgroundColor: AppColors.primary),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                    AppButton(
                      label: 'Close Dossier',
                      size: AppButtonSize.medium,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTriageTab(HealthCaseModel healthCase) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExplainableRiskBreakdownCard(healthCase: healthCase),
          const SizedBox(height: 18),
          AIHealthAssessmentCard(healthCase: healthCase),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(AppDesign.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Farmer Incident Details & Telemetry', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.slate900)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMetricChip('Affected Birds', '${healthCase.affectedCount}', AppColors.critical),
                    const SizedBox(width: 12),
                    _buildMetricChip('Mortality Today', '${healthCase.mortalityCount}', AppColors.critical),
                    const SizedBox(width: 12),
                    _buildMetricChip('Feed Drop', healthCase.feedReductionPercent != null ? '${healthCase.feedReductionPercent!.toStringAsFixed(1)}%' : 'N/A', AppColors.warning),
                    const SizedBox(width: 12),
                    _buildMetricChip('Water Drop', healthCase.waterReductionPercent != null ? '${healthCase.waterReductionPercent!.toStringAsFixed(1)}%' : 'N/A', AppColors.warning),
                  ],
                ),
                if (healthCase.symptoms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Reported Symptoms:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.slate600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: healthCase.symptoms.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate800)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentTab(HealthCaseModel healthCase, bool isAccepted) {
    return StreamBuilder<VetClinicalAssessmentModel?>(
      stream: HealthCaseWorkflowService.streamClinicalAssessment(healthCase.id),
      builder: (context, snap) {
        final assessment = snap.data;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Veterinary Clinical Findings & Diagnosis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate900)),
                  AppButton(
                    label: assessment == null ? 'Record Clinical Assessment' : 'Edit Assessment',
                    icon: Icons.edit_note_rounded,
                    size: AppButtonSize.small,
                    onPressed: isAccepted ? () => _openAssessmentDialog(healthCase) : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (assessment == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                    border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.assignment_late_outlined, size: 36, color: AppColors.slate400),
                        const SizedBox(height: 10),
                        const Text('No clinical veterinary assessment recorded yet.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.slate700)),
                        const SizedBox(height: 4),
                        Text(
                          isAccepted
                              ? 'Click "Record Clinical Assessment" to log your findings and preliminary diagnosis.'
                              : 'Accept this case first to initiate clinical assessment.',
                          style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text('Preliminary Diagnosis: ${assessment.preliminaryDiagnosis}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.slate900)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(assessment.diagnosisStatus.label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Primary Syndrome: ${assessment.primarySyndrome.label} • Severity: ${assessment.severity.toUpperCase()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate700)),
                      const Divider(height: 20, color: AppColors.divider),
                      const Text('Clinical Observations:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.slate600)),
                      const SizedBox(height: 4),
                      Text(assessment.clinicalObservations, style: const TextStyle(fontSize: 13, color: AppColors.slate800)),
                      if (assessment.internalNotes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                            border: Border.all(color: AppColors.slate300),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lock_outline, size: 14, color: AppColors.slate600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Internal Vet Team Notes (Private): "${assessment.internalNotes}"',
                                  style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.slate700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabTab(HealthCaseModel healthCase, bool isAccepted) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Diagnostic Sample & Laboratory Tests', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate900)),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.do_not_disturb_on_outlined, size: 14),
                    label: const Text('Lab Not Required'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    onPressed: isAccepted
                        ? () async {
                            await HealthCaseWorkflowService.setNoLabRequired(
                              caseId: healthCase.id,
                              vetId: widget.assignment.vetId,
                              rationale: 'Sufficient clinical evidence for supportive management.',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Marked as lab test not required.'), backgroundColor: AppColors.primary),
                              );
                            }
                          }
                        : null,
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: 'Request Lab Test',
                    icon: Icons.add_circle_outline,
                    size: AppButtonSize.small,
                    onPressed: isAccepted ? () => _openLabRequestDialog(healthCase) : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          LabDiagnosticWorkflowCard(
            healthCase: healthCase,
            isVeterinarian: isAccepted,
            onStatusUpdated: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentTab(HealthCaseModel healthCase, bool isAccepted) {
    return StreamBuilder<TreatmentPlanModel?>(
      stream: HealthCaseWorkflowService.streamTreatmentPlan(healthCase.id),
      builder: (context, snap) {
        final plan = snap.data;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Clinical Management & Biosecurity Plan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate900)),
                  AppButton(
                    label: plan == null ? 'Create Management Plan' : 'Update Plan',
                    icon: Icons.post_add_rounded,
                    size: AppButtonSize.small,
                    onPressed: isAccepted ? () => _openTreatmentPlanDialog(healthCase) : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (plan == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text('No management plan published yet. Click "Create Management Plan" to publish guidance.', style: TextStyle(fontSize: 12.5, color: AppColors.slate600)),
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Active Clinical Plan: ${plan.diagnosis}', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.slate900)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                            child: const Text('PUBLISHED TO FARMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Supportive Instructions:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.slate600)),
                      const SizedBox(height: 6),
                      ...plan.instructions.map((inst) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Expanded(child: Text(inst, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.slate800))),
                              ],
                            ),
                          )),
                      const SizedBox(height: 12),
                      const Text('Mandatory Biosecurity Actions:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.slate600)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: plan.biosecurityActions.map((action) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.warningBg.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                            ),
                            child: Text(action, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.slate800)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineTab(HealthCaseModel healthCase) {
    return StreamBuilder<List<CaseFollowUpModel>>(
      stream: HealthCaseWorkflowService.streamFollowUps(healthCase.id),
      builder: (context, snap) {
        final followUps = snap.data ?? [];

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Live Clinical Case Timeline & Follow-Ups', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate900)),
              const SizedBox(height: 14),
              _buildTimelineStep('1', 'Farmer Incident Reported', 'Case ${healthCase.caseNumber} created with ${healthCase.mortalityCount} deaths and ${healthCase.affectedCount} affected.', true),
              _buildTimelineStep('2', 'Deterministic Risk Assessment', 'Risk score calculated at ${healthCase.riskScore}/100 (${healthCase.riskLevel.label.toUpperCase()}).', true),
              _buildTimelineStep('3', 'Automatic Veterinary Escalation', 'Disease alert and priority assignment generated.', true),
              _buildTimelineStep('4', 'Veterinarian Accepted Case', healthCase.assignedVetId != null ? 'Dr. Assigned Veterinarian took clinical ownership.' : 'Pending acceptance by attending veterinarian.', healthCase.assignedVetId != null),
              _buildTimelineStep('5', 'Clinical Assessment & Plan Published', healthCase.treatmentPlanId != null ? 'Official management plan active.' : 'In preparation.', healthCase.treatmentPlanId != null),
              if (followUps.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Farmer Follow-Up Progression Submissions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate900)),
                const SizedBox(height: 8),
                ...followUps.map((fu) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${fu.condition.label} • Mort: ${fu.currentMortalityCount} | Affected: ${fu.currentAffectedCount}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                            if (fu.notes.isNotEmpty) Text('"${fu.notes}"', style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.slate600)),
                          ],
                        ),
                        Text(DateFormat('dd MMM, hh:mm a').format(fu.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.slate500)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String step, String title, String desc, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: isDone ? AppColors.primary : AppColors.slate300,
            child: Text(step, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.slate900)),
                Text(desc, style: const TextStyle(fontSize: 11.5, color: AppColors.slate600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Clinical Assessment Form Dialog (SIH26128 Phase 6)
class _AssessmentFormDialog extends StatefulWidget {
  final HealthCaseModel healthCase;
  final String vetId;
  final String vetName;
  final VoidCallback onSaved;

  const _AssessmentFormDialog({
    required this.healthCase,
    required this.vetId,
    required this.vetName,
    required this.onSaved,
  });

  @override
  State<_AssessmentFormDialog> createState() => _AssessmentFormDialogState();
}

class _AssessmentFormDialogState extends State<_AssessmentFormDialog> {
  final _observationsCtrl = TextEditingController(text: 'Audible rales, nasal discharge, lethargy, reduced feed consumption.');
  final _diagnosisCtrl = TextEditingController(text: 'Suspected Newcastle Disease (ND)');
  final _guidanceCtrl = TextEditingController(text: 'Immediately isolate affected flock in Shed 2. Restrict visitor access.');
  final _internalNotesCtrl = TextEditingController(text: 'Sample to be dispatched to Pune reference lab if mortality spikes tomorrow.');

  PrimarySyndrome _syndrome = PrimarySyndrome.respiratory;
  DiagnosisStatus _diagStatus = DiagnosisStatus.suspected;
  String _severity = 'severe';
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final assessment = VetClinicalAssessmentModel(
      id: '${widget.healthCase.id}_assessment-v1',
      caseId: widget.healthCase.id,
      vetId: widget.vetId,
      vetName: widget.vetName,
      clinicalObservations: _observationsCtrl.text.trim(),
      severity: _severity,
      primarySyndrome: _syndrome,
      preliminaryDiagnosis: _diagnosisCtrl.text.trim(),
      diagnosisStatus: _diagStatus,
      farmerGuidance: _guidanceCtrl.text.trim(),
      internalNotes: _internalNotesCtrl.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await HealthCaseWorkflowService.addClinicalAssessment(
      caseId: widget.healthCase.id,
      vetId: widget.vetId,
      vetName: widget.vetName,
      assessment: assessment,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veterinary assessment and preliminary diagnosis recorded.'), backgroundColor: AppColors.primary),
        );
        widget.onSaved();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
      child: Container(
        width: 620,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Record Veterinary Clinical Assessment', style: AppTypography.titleLarge),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),

              // Preliminary Diagnosis
              TextFormField(
                controller: _diagnosisCtrl,
                decoration: const InputDecoration(
                  labelText: 'Preliminary Clinical Diagnosis *',
                  hintText: 'e.g. Suspected Newcastle Disease',
                ),
              ),
              const SizedBox(height: 14),

              // Status & Syndrome dropdowns
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<DiagnosisStatus>(
                      value: _diagStatus,
                      decoration: const InputDecoration(labelText: 'Diagnosis Certainty'),
                      items: DiagnosisStatus.values.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s.label));
                      }).toList(),
                      onChanged: (val) => setState(() => _diagStatus = val ?? _diagStatus),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<PrimarySyndrome>(
                      value: _syndrome,
                      decoration: const InputDecoration(labelText: 'Primary Syndrome'),
                      items: PrimarySyndrome.values.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s.label));
                      }).toList(),
                      onChanged: (val) => setState(() => _syndrome = val ?? _syndrome),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Clinical Observations
              TextFormField(
                controller: _observationsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Clinical Examination & Observations *',
                ),
              ),
              const SizedBox(height: 14),

              // Farmer-visible Guidance
              TextFormField(
                controller: _guidanceCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Farmer-Visible Guidance & Immediate Advisory',
                ),
              ),
              const SizedBox(height: 14),

              // Internal Vet Notes (Private)
              TextFormField(
                controller: _internalNotesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Internal Veterinary Notes (Private to Vet Team)',
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'Save Assessment',
                    icon: Icons.save_rounded,
                    size: AppButtonSize.small,
                    onPressed: _isSaving ? null : _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lab Request Dialog (SIH26128 Phase 6)
class _LabRequestDialog extends StatefulWidget {
  final HealthCaseModel healthCase;
  final String vetId;
  final String vetName;
  final VoidCallback onSaved;

  const _LabRequestDialog({
    required this.healthCase,
    required this.vetId,
    required this.vetName,
    required this.onSaved,
  });

  @override
  State<_LabRequestDialog> createState() => _LabRequestDialogState();
}

class _LabRequestDialogState extends State<_LabRequestDialog> {
  String _sampleType = 'Tracheal & Cloacal Swabs';
  String _testRequested = 'RT-PCR Viral Panel';
  String _labName = 'Central Poultry Disease Diagnostic Lab, Pune';
  final _notesCtrl = TextEditingController(text: 'Testing for Newcastle Disease Virus (NDV) & Avian Influenza (H5/H7/H9).');
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final labTest = LabTestModel(
      id: 'lt_${widget.healthCase.id}_${DateTime.now().millisecondsSinceEpoch}',
      caseId: widget.healthCase.id,
      sampleId: 'SMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      sampleType: _sampleType,
      requestedBy: widget.vetName,
      requestedAt: DateTime.now(),
      labName: _labName,
      status: LabTestStatus.requested,
      resultNotes: _notesCtrl.text.trim(),
    );

    final success = await HealthCaseWorkflowService.requestLabTest(
      caseId: widget.healthCase.id,
      vetId: widget.vetId,
      labTest: labTest,
      farmerId: widget.healthCase.farmerId,
      caseNumber: widget.healthCase.caseNumber,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diagnostic laboratory test requested.'), backgroundColor: AppColors.primary),
        );
        widget.onSaved();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Request Diagnostic Laboratory Test', style: AppTypography.titleLarge),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _sampleType,
              decoration: const InputDecoration(labelText: 'Sample Type'),
              items: const [
                DropdownMenuItem(value: 'Tracheal & Cloacal Swabs', child: Text('Tracheal & Cloacal Swabs')),
                DropdownMenuItem(value: 'Whole Blood / Serum', child: Text('Whole Blood / Serum')),
                DropdownMenuItem(value: 'Tissue Biopsy', child: Text('Tissue Biopsy')),
                DropdownMenuItem(value: 'Fecal / Dropping Sample', child: Text('Fecal / Dropping Sample')),
              ],
              onChanged: (val) => setState(() => _sampleType = val ?? _sampleType),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _testRequested,
              decoration: const InputDecoration(labelText: 'Test Requested'),
              items: const [
                DropdownMenuItem(value: 'RT-PCR Viral Panel', child: Text('RT-PCR Viral Panel (NDV/AIV)')),
                DropdownMenuItem(value: 'ELISA Serology', child: Text('ELISA Serology')),
                DropdownMenuItem(value: 'Bacterial Culture & AST', child: Text('Bacterial Culture & AST')),
                DropdownMenuItem(value: 'Histopathology', child: Text('Histopathology')),
              ],
              onChanged: (val) => setState(() => _testRequested = val ?? _testRequested),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Diagnostic Rationale & Notes'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                AppButton(
                  label: 'Transmit Lab Order',
                  icon: Icons.send_rounded,
                  size: AppButtonSize.small,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Treatment & Biosecurity Plan Dialog (SIH26128 Phase 6)
class _TreatmentPlanDialog extends StatefulWidget {
  final HealthCaseModel healthCase;
  final String vetId;
  final VoidCallback onSaved;

  const _TreatmentPlanDialog({
    required this.healthCase,
    required this.vetId,
    required this.onSaved,
  });

  @override
  State<_TreatmentPlanDialog> createState() => _TreatmentPlanDialogState();
}

class _TreatmentPlanDialogState extends State<_TreatmentPlanDialog> {
  final _diagCtrl = TextEditingController(text: 'Suspected Newcastle Disease (ND) Management Protocol');
  final _instCtrl = TextEditingController(text: 'Isolate Shed 2 immediately.\nProvide electrolyte & multivitamin supportive hydration in water line.\nIncrease exhaust fan ventilation.');
  final _bioCtrl = TextEditingController(text: 'Boot dip disinfectant station at shed entry.\nNo farm visitors permitted.\nSeparate feed equipment for Shed 2.');
  bool _isPublishing = false;

  Future<void> _publish() async {
    setState(() => _isPublishing = true);
    final instructions = _instCtrl.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final biosecurity = _bioCtrl.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    final plan = TreatmentPlanModel(
      id: 'plan_${widget.healthCase.id}_${DateTime.now().millisecondsSinceEpoch}',
      caseId: widget.healthCase.id,
      vetId: widget.vetId,
      farmId: widget.healthCase.farmId,
      batchId: widget.healthCase.flockId,
      diagnosis: _diagCtrl.text.trim(),
      instructions: instructions,
      biosecurityActions: biosecurity,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 3)),
      status: TreatmentPlanStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await HealthCaseWorkflowService.publishTreatmentPlan(
      caseId: widget.healthCase.id,
      vetId: widget.vetId,
      plan: plan,
      farmerId: widget.healthCase.farmerId,
      caseNumber: widget.healthCase.caseNumber,
    );

    if (mounted) {
      setState(() => _isPublishing = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Management plan published to farmer in real time.'), backgroundColor: AppColors.primary),
        );
        widget.onSaved();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Create & Publish Clinical Management Plan', style: AppTypography.titleLarge),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _diagCtrl,
                decoration: const InputDecoration(labelText: 'Plan Title / Diagnosis Target'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _instCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Supportive & Clinical Management Instructions (1 per line)',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mandatory Biosecurity Barrier Actions (1 per line)',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'Publish to Farmer',
                    icon: Icons.publish_rounded,
                    size: AppButtonSize.small,
                    onPressed: _isPublishing ? null : _publish,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AI Feedback Dialog (SIH26128 Phase 6)
class _AIFeedbackDialog extends StatefulWidget {
  final String caseId;
  final String vetId;

  const _AIFeedbackDialog({required this.caseId, required this.vetId});

  @override
  State<_AIFeedbackDialog> createState() => _AIFeedbackDialogState();
}

class _AIFeedbackDialogState extends State<_AIFeedbackDialog> {
  AIFeedbackRating _rating = AIFeedbackRating.helpful;
  final _notesCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AI Clinical Decision Feedback', style: AppTypography.titleLarge),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<AIFeedbackRating>(
              value: _rating,
              decoration: const InputDecoration(labelText: 'Helpfulness Rating'),
              items: AIFeedbackRating.values.map((r) {
                return DropdownMenuItem(value: r, child: Text(r.label));
              }).toList(),
              onChanged: (val) => setState(() => _rating = val ?? _rating),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Clinical Notes / Discrepancy details'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                AppButton(
                  label: 'Submit Feedback',
                  size: AppButtonSize.small,
                  onPressed: () async {
                    await HealthCaseWorkflowService.recordAIFeedback(
                      caseId: widget.caseId,
                      vetId: widget.vetId,
                      rating: _rating,
                      notes: _notesCtrl.text.trim(),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('AI feedback recorded.'), backgroundColor: AppColors.primary),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
