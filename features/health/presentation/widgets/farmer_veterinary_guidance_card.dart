import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/health/data/health_case_workflow_service.dart';
import 'package:flock_sense/features/health/domain/case_follow_up_model.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/treatment_plan_model.dart';
import 'package:flock_sense/features/health/domain/vet_clinical_assessment_model.dart';

/// Professional Web SaaS Clinical Guidance Card for Farmer Portal (SIH26128 Phase 6)
class FarmerVeterinaryGuidanceCard extends StatefulWidget {
  final HealthCaseModel healthCase;
  final VoidCallback? onFollowUpSubmitted;

  const FarmerVeterinaryGuidanceCard({
    super.key,
    required this.healthCase,
    this.onFollowUpSubmitted,
  });

  @override
  State<FarmerVeterinaryGuidanceCard> createState() => _FarmerVeterinaryGuidanceCardState();
}

class _FarmerVeterinaryGuidanceCardState extends State<FarmerVeterinaryGuidanceCard> {
  bool _isAcknowledged = false;

  void _openFollowUpModal() {
    showDialog(
      context: context,
      builder: (ctx) => _FarmerFollowUpModal(
        healthCase: widget.healthCase,
        onSubmitted: () {
          widget.onFollowUpSubmitted?.call();
          if (mounted) setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VetClinicalAssessmentModel?>(
      stream: HealthCaseWorkflowService.streamClinicalAssessment(widget.healthCase.id),
      builder: (context, assessSnap) {
        final assessment = assessSnap.data;

        return StreamBuilder<TreatmentPlanModel?>(
          stream: HealthCaseWorkflowService.streamTreatmentPlan(widget.healthCase.id),
          builder: (context, planSnap) {
            final plan = planSnap.data;
            final hasGuidance = assessment != null || plan != null || widget.healthCase.veterinarianAssessment != null;

            if (!hasGuidance && widget.healthCase.status != HealthCaseStatus.under_investigation && widget.healthCase.status != HealthCaseStatus.vet_assigned) {
              return const SizedBox.shrink();
            }

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDesign.radiusLg),
                border: Border.all(color: AppColors.primary.withOpacity(0.35), width: 1.5),
                boxShadow: AppDesign.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Banner
                  _buildHeader(assessment),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. Preliminary Clinical Diagnosis
                        if (assessment != null || widget.healthCase.diagnosis != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_outlined, size: 22, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'OFFICIAL VETERINARY CLINICAL ASSESSMENT',
                                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.primary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        assessment != null
                                            ? '${assessment.preliminaryDiagnosis} (${assessment.diagnosisStatus.label.toUpperCase()})'
                                            : widget.healthCase.diagnosis!,
                                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.slate900),
                                      ),
                                      if (assessment != null && assessment.clinicalObservations.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          assessment.farmerGuidance.isNotEmpty ? assessment.farmerGuidance : assessment.clinicalObservations,
                                          style: const TextStyle(fontSize: 12.5, color: AppColors.slate700, height: 1.35),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 3. Treatment & Management Instructions
                        if (plan != null && plan.instructions.isNotEmpty) ...[
                          const Text(
                            'PRESCRIBED MANAGEMENT & SUPPORTIVE ACTIONS',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.slate500),
                          ),
                          const SizedBox(height: 8),
                          ...plan.instructions.map((inst) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(inst, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.slate800))),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 14),
                        ],

                        // 4. Biosecurity Instructions
                        if (plan != null && plan.biosecurityActions.isNotEmpty) ...[
                          const Text(
                            'MANDATORY BIOSECURITY BARRIERS',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.slate500),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: plan.biosecurityActions.map((action) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.warningBg.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.shield_outlined, size: 12, color: AppColors.warning),
                                    const SizedBox(width: 6),
                                    Text(action, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.slate800)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 5. Follow-Up Schedule & Action Buttons
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event_available_outlined, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  plan != null
                                      ? 'Scheduled Follow-Up: ${DateFormat("dd MMM yyyy").format(plan.endDate)}'
                                      : 'Veterinary Follow-Up: Scheduled in 48h',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate700),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (!_isAcknowledged) ...[
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.done_all_rounded, size: 14),
                                    label: const Text('Acknowledge Guidance'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                    onPressed: () {
                                      setState(() => _isAcknowledged = true);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Guidance acknowledged by farm manager.'),
                                          backgroundColor: AppColors.primary,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                AppButton(
                                  label: 'Submit Follow-Up Report',
                                  icon: Icons.add_chart_rounded,
                                  size: AppButtonSize.small,
                                  onPressed: _openFollowUpModal,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(VetClinicalAssessmentModel? assessment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDesign.radiusLg),
          topRight: Radius.circular(AppDesign.radiusLg),
        ),
        border: const Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppDesign.radiusSm)),
                child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Veterinary Clinical Guidance & Plan',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.slate900),
                  ),
                  Text(
                    assessment != null ? 'Attending Clinician: ${assessment.vetName}' : 'Attending Clinician: Dr. Assigned District Veterinarian',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.slate600),
                  ),
                ],
              ),
            ],
          ),
          StatusBadge.fromStatus(widget.healthCase.status.name),
        ],
      ),
    );
  }
}

/// Farmer Follow-Up Progress Submission Modal
class _FarmerFollowUpModal extends StatefulWidget {
  final HealthCaseModel healthCase;
  final VoidCallback onSubmitted;

  const _FarmerFollowUpModal({
    required this.healthCase,
    required this.onSubmitted,
  });

  @override
  State<_FarmerFollowUpModal> createState() => _FarmerFollowUpModalState();
}

class _FarmerFollowUpModalState extends State<_FarmerFollowUpModal> {
  final _mortalityController = TextEditingController(text: '3');
  final _affectedController = TextEditingController(text: '12');
  final _notesController = TextEditingController();
  ConditionProgression _progression = ConditionProgression.improving;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final followUp = CaseFollowUpModel(
      id: 'fu_${widget.healthCase.id}_${DateTime.now().millisecondsSinceEpoch}',
      caseId: widget.healthCase.id,
      farmerId: widget.healthCase.farmerId ?? 'farmer_01',
      farmId: widget.healthCase.farmId,
      batchId: widget.healthCase.flockId,
      currentAffectedCount: int.tryParse(_affectedController.text) ?? 0,
      currentMortalityCount: int.tryParse(_mortalityController.text) ?? 0,
      condition: _progression,
      notes: _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    final success = await HealthCaseWorkflowService.submitFarmerFollowUp(
      caseId: widget.healthCase.id,
      followUp: followUp,
      assignedVetId: widget.healthCase.assignedVetId,
      caseNumber: widget.healthCase.caseNumber,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Follow-up observations transmitted to veterinarian in real time.'),
            backgroundColor: AppColors.primary,
          ),
        );
        widget.onSubmitted();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Submit Flock Follow-Up Progress', style: AppTypography.titleLarge),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Record current morning telemetry and symptom progression to keep the attending veterinarian updated.',
              style: TextStyle(fontSize: 12, color: AppColors.slate600),
            ),
            const SizedBox(height: 16),

            // Mortality & Affected inputs
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _mortalityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Dead Birds Today', isDense: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _affectedController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Affected Birds Now', isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progression Radio Group
            const Text('Flock Condition Progression', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildProgressionChip(ConditionProgression.improving, 'Improving / Stabilized', AppColors.healthy),
                const SizedBox(width: 8),
                _buildProgressionChip(ConditionProgression.same, 'Same / Unchanged', AppColors.warning),
                const SizedBox(width: 8),
                _buildProgressionChip(ConditionProgression.worse, 'Deteriorating', AppColors.critical),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observations / Medication Response Notes',
                hintText: 'e.g. Birds resuming feed, water consumption normalized...',
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
                  label: 'Transmit to Vet',
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

  Widget _buildProgressionChip(ConditionProgression p, String label, Color color) {
    final isSelected = _progression == p;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _progression = p),
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.slate100,
            borderRadius: BorderRadius.circular(AppDesign.radiusSm),
            border: Border.all(color: isSelected ? color : AppColors.slate300),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.slate700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
