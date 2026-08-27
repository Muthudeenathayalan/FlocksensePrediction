import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/health/data/prevention_service.dart';
import 'package:flock_sense/features/health/domain/biosecurity_assessment_model.dart';
import 'package:flock_sense/features/health/domain/prevention_recommendation_model.dart';

/// Veterinarian Biosecurity Review & Preventive Action Card (SIH26128 Phase 10)
class VetPreventionGuidanceCard extends StatelessWidget {
  final String farmId;
  final String farmName;
  final String caseId;
  final String vetName;

  const VetPreventionGuidanceCard({
    super.key,
    required this.farmId,
    this.farmName = 'Green Valley Poultry Farm',
    required this.caseId,
    this.vetName = 'Dr. Rajesh Sharma',
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BiosecurityAssessmentModel?>(
      stream: PreventionService.streamLatestAssessment(farmId),
      builder: (context, snapshot) {
        final bio = snapshot.data;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: AppDesign.subtleShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Farm Biosecurity & Preventive Status ($farmName)',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ],
                  ),
                  if (bio != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bio.score >= 80 ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: bio.score >= 80 ? AppColors.success : AppColors.warning),
                      ),
                      child: Text(
                        '${bio.score}/100 (${bio.strength.label})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: bio.score >= 80 ? AppColors.success : AppColors.highRisk,
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(height: 20),

              if (bio != null && bio.riskFactors.isNotEmpty) ...[
                const Text(
                  'IDENTIFIED BIOSECURITY GAPS:',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                ...bio.riskFactors.take(3).map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
                          const SizedBox(width: 6),
                          Expanded(child: Text(f.title, style: const TextStyle(fontSize: 11))),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],

              // Add Vet Recommendation Button
              OutlinedButton.icon(
                onPressed: () => _showAddVetActionDialog(context),
                icon: const Icon(Icons.add_task, size: 14),
                label: const Text('Add Vet Preventive Action'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddVetActionDialog(BuildContext context) {
    final titleController = TextEditingController();
    final actionController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.medication_liquid_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add Veterinary Preventive Instruction'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Instruction Title',
                  hintText: 'e.g. Increase Virucidal Shed Spraying',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: actionController,
                decoration: const InputDecoration(
                  labelText: 'Recommended Action',
                  hintText: 'e.g. Mist sheds twice daily with Glutaraldehyde solution.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Clinical Justification',
                  hintText: 'e.g. Suppresses airborne viral load during outbreak window.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || actionController.text.isEmpty) return;
              Navigator.pop(ctx);

              final now = DateTime.now();
              final rec = PreventionRecommendationModel(
                id: 'vet_rec_${farmId}_${now.millisecondsSinceEpoch}',
                farmId: farmId,
                caseId: caseId,
                source: 'veterinarian',
                category: 'veterinary_triage',
                priority: PreventionPriority.high,
                title: titleController.text.trim(),
                description: 'Prescribed by $vetName during clinical investigation.',
                recommendedAction: actionController.text.trim(),
                reason: reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : 'Attending veterinarian prescribed preventive biosecurity measure.',
                ruleCode: 'vet_clinical_instruction',
                createdBy: vetName,
                createdAt: now,
                updatedAt: now,
              );

              await PreventionService.addVetRecommendation(rec);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veterinary preventive instruction dispatched to farmer!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Dispatch Instruction'),
          ),
        ],
      ),
    );
  }
}
