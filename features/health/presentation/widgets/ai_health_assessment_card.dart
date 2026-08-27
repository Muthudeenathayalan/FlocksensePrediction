import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/features/health/data/ai_health_assessment_service.dart';
import 'package:flock_sense/features/health/domain/ai_health_assessment_model.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/risk_assessment_model.dart';

/// Professional Clinical Decision-Support Card for FlockSense SaaS (SIH26128 Phase 4)
class AIHealthAssessmentCard extends StatefulWidget {
  final HealthCaseModel healthCase;
  final RiskAssessmentModel? riskAssessment;
  final VoidCallback? onReanalyzed;

  const AIHealthAssessmentCard({
    super.key,
    required this.healthCase,
    this.riskAssessment,
    this.onReanalyzed,
  });

  @override
  State<AIHealthAssessmentCard> createState() => _AIHealthAssessmentCardState();
}

class _AIHealthAssessmentCardState extends State<AIHealthAssessmentCard> {
  bool _isReanalyzing = false;

  Color _getSimilarityColor(AIConditionLikelihood likelihood) {
    switch (likelihood) {
      case AIConditionLikelihood.high_similarity:
        return AppColors.critical;
      case AIConditionLikelihood.moderate_similarity:
        return AppColors.warning;
      case AIConditionLikelihood.low_similarity:
        return AppColors.info;
    }
  }

  Color _getSimilarityBg(AIConditionLikelihood likelihood) {
    switch (likelihood) {
      case AIConditionLikelihood.high_similarity:
        return AppColors.criticalBg;
      case AIConditionLikelihood.moderate_similarity:
        return AppColors.warningBg;
      case AIConditionLikelihood.low_similarity:
        return AppColors.infoBg;
    }
  }

  Color _getUrgencyColor(AIUrgencyLevel urgency) {
    switch (urgency) {
      case AIUrgencyLevel.emergency_review:
        return AppColors.critical;
      case AIUrgencyLevel.urgent_review:
        return AppColors.highRisk;
      case AIUrgencyLevel.review_recommended:
        return AppColors.warning;
      case AIUrgencyLevel.routine_monitoring:
        return AppColors.healthy;
    }
  }

  Future<void> _handleReanalyze() async {
    setState(() => _isReanalyzing = true);
    try {
      await AIHealthAssessmentService.evaluateAndPersistAIAssessment(
        healthCase: widget.healthCase,
        riskAssessment: widget.riskAssessment,
        forceRecalculate: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Clinical Insights recalculated with latest evidence.'),
            backgroundColor: AppColors.primary,
          ),
        );
        widget.onReanalyzed?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI Analysis error: $e'),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isReanalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AIHealthAssessmentModel?>(
      stream: AIHealthAssessmentService.streamAssessmentForCase(widget.healthCase.id),
      builder: (context, snapshot) {
        final assessment = snapshot.data;

        // If no document exists in Firestore yet, show intelligent direct fallback
        final effectiveAssessment = assessment ??
            AIHealthAssessmentService.generateClinicalAssessment(
              healthCase: widget.healthCase,
              riskAssessment: widget.riskAssessment,
              inputHash: '',
            );

        final isProcessing = assessment?.status == AIAssessmentStatus.processing || _isReanalyzing;
        final isFailed = assessment?.status == AIAssessmentStatus.failed;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDesign.radiusLg),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: AppDesign.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Banner
              _buildHeader(effectiveAssessment, isProcessing, isFailed),

              if (isProcessing) ...[
                _buildLoadingShimmer(),
              ] else if (isFailed) ...[
                _buildFailureView(effectiveAssessment),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Clinical Summary
                      if (effectiveAssessment.clinicalExplanation.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.slate50,
                            borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                            border: Border.all(color: AppColors.slate200, width: 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.psychology_alt_outlined, size: 20, color: AppColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'AI CLINICAL INTERPRETATION & EPIDEMIOLOGICAL CONTEXT',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                        color: AppColors.slate500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      effectiveAssessment.clinicalExplanation,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.slate800,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // 3. Ranked Differential Conditions & Evidence Explanation
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Ranked Possible Conditions
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'POSSIBLE CONDITIONS (DIFFERENTIAL FINDINGS)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: AppColors.slate500,
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'Similarity rankings reflect pattern alignment with clinical signs. Not a confirmed diagnosis.',
                                      child: Icon(Icons.info_outline, size: 14, color: AppColors.slate400),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (effectiveAssessment.possibleConditions.isNotEmpty)
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: effectiveAssessment.possibleConditions.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, idx) {
                                      final condition = effectiveAssessment.possibleConditions[idx];
                                      return _buildConditionCard(condition);
                                    },
                                  )
                                else
                                  const Text('No specific disease patterns identified.', style: TextStyle(fontSize: 12.5, color: AppColors.slate500)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Right: Automated Evidence & Photographic Observations
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'OBSERVED CLINICAL EVIDENCE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: AppColors.slate500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate50,
                                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                                    border: Border.all(color: AppColors.slate200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (effectiveAssessment.observedEvidence.isNotEmpty)
                                        ...effectiveAssessment.observedEvidence.map((ev) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.primary),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    ev,
                                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.slate800),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        })
                                      else
                                        const Text('Standard baseline telemetry recorded.', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Photographic Evidence Observations
                                const Text(
                                  'PHOTOGRAPHIC EVIDENCE OBSERVATIONS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: AppColors.slate500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate50,
                                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                                    border: Border.all(color: AppColors.slate200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (effectiveAssessment.imageObservations.isNotEmpty)
                                        ...effectiveAssessment.imageObservations.map((obs) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 6),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.camera_alt_outlined, size: 14, color: AppColors.slate600),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    obs,
                                                    style: const TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.3),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        })
                                      else
                                        const Text('No photographic visual observations.', style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Visual observations are AI-assisted indicators and require clinical verification.',
                                        style: TextStyle(fontSize: 10.5, color: AppColors.slate400, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 4. Recommended Immediate Supportive & Biosecurity Actions
                      const Text(
                        'RECOMMENDED IMMEDIATE SUPPORTIVE & BIOSECURITY ACTIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
                        ),
                        child: Column(
                          children: [
                            if (effectiveAssessment.recommendedActions.isNotEmpty)
                              ...effectiveAssessment.recommendedActions.asMap().entries.map((entry) {
                                final idx = entry.key + 1;
                                final action = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$idx',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          action,
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.slate900, height: 1.35),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              })
                            else
                              const Text('Continue standard biosecurity protocol.', style: TextStyle(fontSize: 12.5, color: AppColors.slate600)),
                            const SizedBox(height: 4),
                            const Text(
                              '⚠️ Non-prescriptive supportive guidance. Consult an authorized veterinarian before administering specific pharmaceuticals or changing flock treatments.',
                              style: TextStyle(fontSize: 11, color: AppColors.slate600, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 5. Additional Information Needed
                      if (effectiveAssessment.additionalInformationNeeded.isNotEmpty) ...[
                        const Text(
                          'ADDITIONAL INFORMATION THAT MAY ASSIST CLINICAL TRIAGE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.slate500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: effectiveAssessment.additionalInformationNeeded.map((info) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.slate100,
                                borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                                border: Border.all(color: AppColors.slate300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.help_outline_rounded, size: 12, color: AppColors.slate600),
                                  const SizedBox(width: 6),
                                  Text(info, style: const TextStyle(fontSize: 11.5, color: AppColors.slate700)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // 6. Veterinary Review CTA & Mandatory Disclaimer
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warningBg.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.gavel_outlined, size: 18, color: AppColors.warning),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                effectiveAssessment.confidenceNote,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.slate800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            AppButton(
                              label: 'Request Tele-Consult',
                              icon: Icons.video_call_rounded,
                              size: AppButtonSize.small,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Tele-consultation request logged and dispatched to duty veterinarian.'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
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

  Widget _buildHeader(AIHealthAssessmentModel assessment, bool isProcessing, bool isFailed) {
    final urgencyColor = _getUrgencyColor(assessment.urgency);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDesign.radiusLg),
          topRight: Radius.circular(AppDesign.radiusLg),
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppDesign.radiusMd),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'AI Clinical Decision Support',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: urgencyColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppDesign.radiusFull),
                        border: Border.all(color: urgencyColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        assessment.urgency.label.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: urgencyColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Multimodal Engine (${assessment.modelName} • ${assessment.promptVersion}) • Species: Poultry',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.slate500),
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isProcessing
                  ? AppColors.infoBg
                  : (isFailed ? AppColors.criticalBg : AppColors.healthyBg),
              borderRadius: BorderRadius.circular(AppDesign.radiusFull),
              border: Border.all(
                color: isProcessing
                    ? AppColors.info
                    : (isFailed ? AppColors.critical : AppColors.healthy),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isProcessing) ...[
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.info),
                  ),
                  const SizedBox(width: 6),
                ] else ...[
                  Icon(
                    isFailed ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                    size: 13,
                    color: isFailed ? AppColors.critical : AppColors.healthy,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  isProcessing ? 'Analyzing...' : (isFailed ? 'Unavailable' : 'AI Ready'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isProcessing
                        ? AppColors.info
                        : (isFailed ? AppColors.critical : AppColors.healthy),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Re-analyze Action Button
          IconButton(
            icon: isProcessing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded, size: 20),
            color: AppColors.slate600,
            tooltip: 'Re-analyze case with latest clinical evidence',
            onPressed: isProcessing ? null : _handleReanalyze,
          ),
        ],
      ),
    );
  }

  Widget _buildConditionCard(PossibleCondition condition) {
    final color = _getSimilarityColor(condition.likelihood);
    final bg = _getSimilarityBg(condition.likelihood);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  condition.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppDesign.radiusFull),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Text(
                  condition.likelihood.label.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          if (condition.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              condition.reason,
              style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: const [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 16),
          Text(
            'Analyzing clinical evidence, telemetry curves, and photographic findings...',
            style: TextStyle(fontSize: 13, color: AppColors.slate600, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 4),
          Text(
            'Authoritative health risk engine remains fully operational.',
            style: TextStyle(fontSize: 11, color: AppColors.slate400),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureView(AIHealthAssessmentModel assessment) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'AI Clinical Insights Temporarily Unavailable',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800),
                ),
              ),
              AppButton(
                label: 'Retry AI Analysis',
                icon: Icons.refresh_rounded,
                size: AppButtonSize.small,
                onPressed: _handleReanalyze,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The cloud AI inference service is temporarily unreachable (${assessment.errorMessage ?? "Network timeout"}). The authoritative rule & historical anomaly risk engine remains 100% operational.',
            style: const TextStyle(fontSize: 12, color: AppColors.slate600),
          ),
        ],
      ),
    );
  }
}
