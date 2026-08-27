import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/health/data/risk_assessment_service.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/risk_assessment_model.dart';

/// Comprehensive Explainable Risk Breakdown Card for FlockSense SaaS (SIH26128)
class ExplainableRiskBreakdownCard extends StatefulWidget {
  final HealthCaseModel healthCase;
  final VoidCallback? onRecalculated;

  const ExplainableRiskBreakdownCard({
    super.key,
    required this.healthCase,
    this.onRecalculated,
  });

  @override
  State<ExplainableRiskBreakdownCard> createState() =>
      _ExplainableRiskBreakdownCardState();
}

class _ExplainableRiskBreakdownCardState
    extends State<ExplainableRiskBreakdownCard> {
  bool _isRecalculating = false;

  Color _getRiskColor(HealthRiskLevel level) {
    switch (level) {
      case HealthRiskLevel.critical:
        return AppColors.critical;
      case HealthRiskLevel.high:
        return AppColors.highRisk;
      case HealthRiskLevel.moderate:
        return AppColors.warning;
      case HealthRiskLevel.low:
        return AppColors.healthy;
    }
  }

  Color _getRiskBg(HealthRiskLevel level) {
    switch (level) {
      case HealthRiskLevel.critical:
        return AppColors.criticalBg;
      case HealthRiskLevel.high:
        return AppColors.highRiskBg;
      case HealthRiskLevel.moderate:
        return AppColors.warningBg;
      case HealthRiskLevel.low:
        return AppColors.healthyBg;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppColors.critical;
      case 'warning':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  Future<void> _handleRecalculate() async {
    setState(() => _isRecalculating = true);
    try {
      await RiskAssessmentService.evaluateAndPersistRisk(
        healthCase: widget.healthCase,
        forceRecalculate: true,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Risk Assessment recalculated successfully with live baseline.'),
            backgroundColor: AppColors.primary,
          ),
        );
        widget.onRecalculated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recalculation error: $e'),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRecalculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RiskAssessmentModel?>(
      stream: RiskAssessmentService.streamAssessmentForCase(widget.healthCase.id),
      builder: (context, snapshot) {
        final assessment = snapshot.data;
        final riskLevel = assessment?.riskLevel ?? widget.healthCase.riskLevel;
        final score = assessment?.score ?? widget.healthCase.riskScore;
        final riskColor = _getRiskColor(riskLevel);
        final riskBg = _getRiskBg(riskLevel);

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
              // 1. Header Banner with Score & Risk Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: riskBg.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDesign.radiusLg),
                    topRight: Radius.circular(AppDesign.radiusLg),
                  ),
                  border: Border(
                    bottom: BorderSide(color: riskColor.withOpacity(0.2), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                      ),
                      child: Icon(
                        riskLevel == HealthRiskLevel.critical
                            ? Icons.warning_rounded
                            : (riskLevel == HealthRiskLevel.high
                                ? Icons.error_outline_rounded
                                : Icons.health_and_safety_outlined),
                        color: riskColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                riskLevel.label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: riskColor,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              AppDesign.statusChip(
                                'SCORE: $score / 100',
                                riskColor.withOpacity(0.15),
                                textColor: riskColor,
                                borderColor: riskColor.withOpacity(0.4),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Authoritative Rule + Historical Anomaly Engine (${assessment?.engineVersion ?? "risk-v1"})',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Data Quality Badge
                    if (assessment != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDesign.radiusFull),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              assessment.dataQuality == 'Good'
                                  ? Icons.check_circle_outline
                                  : Icons.info_outline,
                              size: 13,
                              color: assessment.dataQuality == 'Good'
                                  ? AppColors.healthy
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Data Quality: ${assessment.dataQuality}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Recalculate Button
                    IconButton(
                      icon: _isRecalculating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded, size: 20),
                      color: AppColors.slate600,
                      tooltip: 'Recalculate risk against live baseline',
                      onPressed: _isRecalculating ? null : _handleRecalculate,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Concise Veterinary Interpretation Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                        border: Border.all(color: AppColors.slate200, width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 18,
                            color: AppColors.slate700,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CLINICAL INTERPRETATION',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: AppColors.slate500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  assessment?.interpretation ??
                                      'Risk assessment is computed by evaluating historical mortality, feed/water reduction, and clinical symptoms.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.slate800,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Explainable Risk Signal Breakdown List
                    const Text(
                      'WHY THIS CASE WAS FLAGGED (EXPLAINABLE SIGNALS)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.slate500,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (assessment != null &&
                        assessment.structuredReasons.isNotEmpty) ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: assessment.structuredReasons.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 12, color: AppColors.divider),
                        itemBuilder: (context, idx) {
                          final reason = assessment.structuredReasons[idx];
                          final color = _getSeverityColor(reason.severity);

                          return Row(
                            children: [
                              // Points Added Badge
                              Container(
                                width: 44,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppDesign.radiusXs),
                                  border: Border.all(
                                    color: color.withOpacity(0.35),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    reason.points > 0
                                        ? '+${reason.points}'
                                        : '0',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Signal Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reason.label,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.slate800,
                                      ),
                                    ),
                                    if (reason.value.isNotEmpty)
                                      Text(
                                        reason.value,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.slate500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Severity Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppDesign.radiusFull),
                                ),
                                child: Text(
                                  reason.severity.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ] else if (widget.healthCase.riskReasons.isNotEmpty) ...[
                      // Enhanced fallback rendering for string reasons
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.healthCase.riskReasons.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 12, color: AppColors.divider),
                        itemBuilder: (context, idx) {
                          final text = widget.healthCase.riskReasons[idx];
                          final lower = text.toLowerCase();
                          
                          int points = 5;
                          String severity = 'info';
                          if (lower.contains('mortality') || lower.contains('spike') || lower.contains('death') || lower.contains('4.1')) {
                            points = 25;
                            severity = 'critical';
                          } else if (lower.contains('respiratory') || lower.contains('sneezing') || lower.contains('clicking')) {
                            points = 14;
                            severity = 'critical';
                          } else if (lower.contains('feed') || lower.contains('18%')) {
                            points = 12;
                            severity = 'warning';
                          } else if (lower.contains('water')) {
                            points = 8;
                            severity = 'warning';
                          } else if (lower.contains('temp') || lower.contains('heat')) {
                            points = 5;
                            severity = 'warning';
                          }

                          final color = _getSeverityColor(severity);

                          return Row(
                            children: [
                              Container(
                                width: 44,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(AppDesign.radiusXs),
                                  border: Border.all(
                                    color: color.withOpacity(0.35),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '+$points',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate800,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppDesign.radiusFull),
                                ),
                                child: Text(
                                  severity.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No major abnormal clinical signals identified. Biosecurity parameters appear optimal.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.slate500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 14),

                    // 4. Telemetry Baseline Comparison Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildTelemetryMetric(
                            label: 'Mortality Spike',
                            value: assessment != null &&
                                    assessment.mortalityBaseline > 0
                                ? '${assessment.mortalityRatio.toStringAsFixed(1)}x'
                                : '${widget.healthCase.mortalityCount} birds',
                            sublabel: assessment != null &&
                                    assessment.mortalityBaseline > 0
                                ? 'vs ${assessment.mortalityBaseline.toStringAsFixed(1)}/day avg'
                                : 'Daily record',
                            icon: Icons.sick_outlined,
                            isCritical: (assessment?.mortalityRatio ?? 1.0) > 2.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTelemetryMetric(
                            label: 'Feed Reduction',
                            value: widget.healthCase.feedReductionPercent != null
                                ? '-${widget.healthCase.feedReductionPercent!.toStringAsFixed(0)}%'
                                : 'Normal',
                            sublabel: 'Daily intake target',
                            icon: Icons.grass_outlined,
                            isCritical:
                                (widget.healthCase.feedReductionPercent ?? 0) >
                                    15,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTelemetryMetric(
                            label: 'Water Reduction',
                            value: widget.healthCase.waterReductionPercent != null
                                ? '-${widget.healthCase.waterReductionPercent!.toStringAsFixed(0)}%'
                                : 'Normal',
                            sublabel: 'Consumption volume',
                            icon: Icons.water_drop_outlined,
                            isCritical:
                                (widget.healthCase.waterReductionPercent ?? 0) >
                                    15,
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
      },
    );
  }

  Widget _buildTelemetryMetric({
    required String label,
    required String value,
    required String sublabel,
    required IconData icon,
    required bool isCritical,
  }) {
    final color = isCritical ? AppColors.critical : AppColors.slate700;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        border: Border.all(
          color: isCritical
              ? AppColors.criticalBorder
              : AppColors.slate200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isCritical ? AppColors.critical : AppColors.slate900,
            ),
          ),
          Text(
            sublabel,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }
}
