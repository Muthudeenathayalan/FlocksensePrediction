import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/health/data/prevention_service.dart';
import 'package:flock_sense/features/health/domain/biosecurity_assessment_model.dart';
import 'package:flock_sense/features/health/domain/prevention_recommendation_model.dart';
import 'package:flock_sense/features/health/presentation/widgets/farm_biosecurity_assessment_modal.dart';

/// Comprehensive Farm Biosecurity, Vaccination Vulnerability & Prevention Dashboard (SIH26128 Phase 10)
class FarmPreventionDashboardCard extends StatefulWidget {
  final String farmId;
  final String farmName;

  const FarmPreventionDashboardCard({
    super.key,
    this.farmId = 'farm_gv_01',
    this.farmName = 'Green Valley Poultry Farm',
  });

  @override
  State<FarmPreventionDashboardCard> createState() => _FarmPreventionDashboardCardState();
}

class _FarmPreventionDashboardCardState extends State<FarmPreventionDashboardCard> {
  String? _expandedRecId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BiosecurityAssessmentModel?>(
      stream: PreventionService.streamLatestAssessment(widget.farmId),
      builder: (context, bioSnap) {
        final assessment = bioSnap.data;
        if (assessment == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<PreventionRecommendationModel>>(
          stream: PreventionService.streamActiveRecommendations(widget.farmId),
          builder: (context, recSnap) {
            final recommendations = recSnap.data ?? [];

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppDesign.subtleShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header & Reassessment Trigger
                  _buildHeader(assessment),
                  const SizedBox(height: 16),

                  // 2. Score Summary & Category Progress Grid
                  _buildScoreBreakdown(assessment),
                  const SizedBox(height: 20),

                  // 3. Priority Protective Actions Checklist
                  _buildPriorityActionsSection(recommendations),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. HEADER
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BiosecurityAssessmentModel assessment) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Biosecurity & Prevention Intelligence',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Last assessed: ${DateFormat('dd MMM yyyy, hh:mm a').format(assessment.assessedAt)} • Version: ${assessment.assessmentVersion}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => FarmBiosecurityAssessmentModal.show(
            context,
            farmId: widget.farmId,
            farmName: widget.farmName,
            initialAssessment: assessment,
          ),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Reassess Biosecurity'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. SCORE BREAKDOWN & CATEGORY PROGRESS BARS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildScoreBreakdown(BiosecurityAssessmentModel assessment) {
    final strengthColor = _getStrengthColor(assessment.strength);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Score Box
                  Container(
                    width: 140,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: strengthColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: strengthColor, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${assessment.score} / 100',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: strengthColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          assessment.strength.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: strengthColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Progress Bars for 6 Categories
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 16,
                          runSpacing: 10,
                          children: [
                            _buildCategoryBar('Visitor Control', assessment.categoryScores['visitor_control'] ?? 60, isWide ? 220 : 180),
                            _buildCategoryBar('Flock Isolation', assessment.categoryScores['flock_isolation'] ?? 50, isWide ? 220 : 180),
                            _buildCategoryBar('Cleaning & Sanitation', assessment.categoryScores['cleaning_disinfection'] ?? 75, isWide ? 220 : 180),
                            _buildCategoryBar('Water & Feed Safety', assessment.categoryScores['water_feed'] ?? 75, isWide ? 220 : 180),
                            _buildCategoryBar('Waste Management', assessment.categoryScores['waste_management'] ?? 50, isWide ? 220 : 180),
                            _buildCategoryBar('Vaccination & Health', assessment.categoryScores['vaccination_health'] ?? 75, isWide ? 220 : 180),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 13, color: AppColors.textSecondary),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'A strong biosecurity score reduces preventable exposure risk but does not guarantee disease prevention.',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryBar(String label, int score, double width) {
    Color color;
    if (score >= 80) {
      color = AppColors.success;
    } else if (score >= 60) {
      color = AppColors.info;
    } else if (score >= 40) {
      color = AppColors.warning;
    } else {
      color = AppColors.critical;
    }

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text('$score%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 5,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. PRIORITY PROTECTIVE ACTIONS CHECKLIST
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildPriorityActionsSection(List<PreventionRecommendationModel> recs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Priority Protective Actions',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${recs.where((r) => r.status != PreventionActionStatus.completed).length} Pending',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const Text(
              'Actions prioritized by proximity & risk severity',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (recs.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.success, size: 22),
                SizedBox(width: 10),
                Text(
                  'No High-Priority Prevention Actions. Continue routine biosecurity maintenance.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        else
          ...recs.map((rec) => _buildActionCard(rec)),
      ],
    );
  }

  Widget _buildActionCard(PreventionRecommendationModel rec) {
    final isExpanded = _expandedRecId == rec.id;
    final isCompleted = rec.status == PreventionActionStatus.completed;

    Color priorityColor;
    switch (rec.priority) {
      case PreventionPriority.critical:
        priorityColor = AppColors.critical;
        break;
      case PreventionPriority.high:
        priorityColor = AppColors.highRisk;
        break;
      case PreventionPriority.medium:
        priorityColor = AppColors.warning;
        break;
      case PreventionPriority.low:
        priorityColor = AppColors.info;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.surfaceVariant.withOpacity(0.25) : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCompleted ? AppColors.border : priorityColor.withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expandedRecId = isExpanded ? null : rec.id),
            leading: Icon(
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: isCompleted ? AppColors.success : priorityColor,
              size: 22,
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: priorityColor),
                  ),
                  child: Text(
                    rec.priority.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: priorityColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (rec.isNearbyClusterTriggered) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.critical.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'NEARBY OUTBREAK',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.critical),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (rec.isVeterinarianRecommended) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'VET RECOMMENDED',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.info),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    rec.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                rec.recommendedAction,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusPill(rec.status),
                const SizedBox(width: 6),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withOpacity(0.4),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WHY THIS ACTION IS REQUIRED:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Text(rec.reason, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  if (rec.evidenceNote != null && rec.evidenceNote!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Farmer Evidence: ${rec.evidenceNote}',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Action Status Trigger Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (rec.status == PreventionActionStatus.recommended)
                        OutlinedButton(
                          onPressed: () => _updateStatus(rec.id, PreventionActionStatus.in_progress),
                          child: const Text('Mark In Progress'),
                        ),
                      const SizedBox(width: 8),
                      if (rec.status != PreventionActionStatus.completed)
                        ElevatedButton.icon(
                          onPressed: () => _showCompletionDialog(rec),
                          icon: const Icon(Icons.check, size: 15),
                          label: const Text('Mark Completed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(PreventionActionStatus status) {
    Color color;
    switch (status) {
      case PreventionActionStatus.recommended:
        color = AppColors.highRisk;
        break;
      case PreventionActionStatus.acknowledged:
      case PreventionActionStatus.in_progress:
        color = AppColors.info;
        break;
      case PreventionActionStatus.completed:
        color = AppColors.success;
        break;
      case PreventionActionStatus.dismissed:
        color = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Future<void> _updateStatus(String recId, PreventionActionStatus status, {String? note}) async {
    await PreventionService.updateRecommendationStatus(recId, status, evidenceNote: note);
    setState(() {});
  }

  void _showCompletionDialog(PreventionRecommendationModel rec) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Complete Action: ${rec.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add completion evidence or operational notes (Optional):',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'e.g. Disinfectant footbaths filled at Shed A & B.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(rec.id, PreventionActionStatus.completed, note: noteController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Action marked completed! Biosecurity record updated.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
            child: const Text('Confirm Completed'),
          ),
        ],
      ),
    );
  }

  Color _getStrengthColor(BiosecurityStrength strength) {
    switch (strength) {
      case BiosecurityStrength.strong:
        return AppColors.success;
      case BiosecurityStrength.good:
        return AppColors.info;
      case BiosecurityStrength.needs_improvement:
        return AppColors.warning;
      case BiosecurityStrength.high_vulnerability:
        return AppColors.critical;
    }
  }
}
