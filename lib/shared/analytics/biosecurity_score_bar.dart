import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/shared/analytics/chart_animation_config.dart';

class BiosecurityCategoryItem {
  final String title;
  final double scorePercent;
  final Color color;

  const BiosecurityCategoryItem({
    required this.title,
    required this.scorePercent,
    this.color = AppColors.primary,
  });
}

/// Animated Biosecurity Score Card with Progress Bars & Category Breakdown
class BiosecurityScoreBar extends StatefulWidget {
  final double score; // 0 to 100
  final double? previousScore;
  final String? ratingText;
  final List<BiosecurityCategoryItem> categories;
  final VoidCallback? onReassess;

  const BiosecurityScoreBar({
    super.key,
    required this.score,
    this.previousScore,
    this.ratingText,
    this.categories = const [],
    this.onReassess,
  });

  @override
  State<BiosecurityScoreBar> createState() => _BiosecurityScoreBarState();
}

class _BiosecurityScoreBarState extends State<BiosecurityScoreBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: ChartAnimationConfig.defaultCurve,
      ),
    );

    _progressController.forward();
  }

  @override
  void didUpdateWidget(covariant BiosecurityScoreBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _progressController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = ChartAnimationConfig.isReducedMotion(context);
    final delta = widget.previousScore != null ? (widget.score - widget.previousScore!) : null;

    Color statusColor = AppColors.primary;
    String statusLabel = widget.ratingText ?? 'Optimal Tier-1';
    if (widget.score < 50) {
      statusColor = AppColors.critical;
      statusLabel = widget.ratingText ?? 'Critical Vulnerability';
    } else if (widget.score < 75) {
      statusColor = AppColors.warning;
      statusLabel = widget.ratingText ?? 'Needs Improvement';
    } else {
      statusColor = AppColors.healthy;
      statusLabel = widget.ratingText ?? 'Tier-1 High Integrity';
    }

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final progress = isReduced ? 1.0 : _progressAnimation.value;
        final animatedScore = (widget.score * progress).round();

        return Container(
          decoration: AppDesign.cardDecoration,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Title & Overall Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Biosecurity & Prevention Score', style: AppTypography.cardTitle),
                      const SizedBox(height: 2),
                      Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$animatedScore',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                        ),
                      ),
                      const Text(
                        ' / 100',
                        style: TextStyle(fontSize: 13, color: AppColors.slate500, fontWeight: FontWeight.w600),
                      ),
                      if (delta != null && delta != 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: delta > 0 ? AppColors.healthyBg : AppColors.criticalBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: delta > 0 ? AppColors.healthy.withOpacity(0.4) : AppColors.critical.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            '${delta > 0 ? '+' : ''}${delta.round()} pts',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: delta > 0 ? AppColors.healthy : AppColors.critical,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Main Overall Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 10,
                  width: double.infinity,
                  color: AppColors.slate100,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: ((widget.score / 100).clamp(0.0, 1.0)) * progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),

              // Category Breakdown Bars
              if (widget.categories.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Biosecurity Dimension Audit',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate700),
                ),
                const SizedBox(height: 10),
                ...widget.categories.map((cat) {
                  final catProgress = ((cat.scorePercent / 100).clamp(0.0, 1.0)) * progress;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cat.title, style: const TextStyle(fontSize: 11.5, color: AppColors.slate700, fontWeight: FontWeight.w500)),
                            Text('${(cat.scorePercent * progress).round()}%', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: cat.color)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            height: 6,
                            width: double.infinity,
                            color: AppColors.slate100,
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: catProgress,
                              child: Container(color: cat.color),
                            ),
                          ),
                        ),
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
}
