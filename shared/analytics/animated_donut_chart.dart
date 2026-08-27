import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/shared/analytics/chart_animation_config.dart';

class DonutSegmentData {
  final String label;
  final double value;
  final Color color;
  final dynamic payload;

  const DonutSegmentData({
    required this.label,
    required this.value,
    required this.color,
    this.payload,
  });
}

/// Interactive Animated Donut Chart with Arc Sweep & Animated Center Counter
class AnimatedDonutChart extends StatefulWidget {
  final List<DonutSegmentData> segments;
  final String? centerLabel;
  final String? centerValue;
  final double centerValueNumber;
  final String? centerValueSuffix;
  final double radius;
  final double centerHoleRadius;
  final Function(dynamic payload)? onSegmentSelected;

  const AnimatedDonutChart({
    super.key,
    required this.segments,
    this.centerLabel,
    this.centerValue,
    this.centerValueNumber = 0.0,
    this.centerValueSuffix = '%',
    this.radius = 45,
    this.centerHoleRadius = 40,
    this.onSegmentSelected,
  });

  @override
  State<AnimatedDonutChart> createState() => _AnimatedDonutChartState();
}

class _AnimatedDonutChartState extends State<AnimatedDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;
  late Animation<double> _sweepAnimation;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _sweepAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sweepController,
        curve: ChartAnimationConfig.defaultCurve,
      ),
    );

    _sweepController.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments.length != widget.segments.length ||
        oldWidget.centerValueNumber != widget.centerValueNumber) {
      _sweepController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = ChartAnimationConfig.isReducedMotion(context);

    if (widget.segments.isEmpty || widget.segments.every((s) => s.value <= 0)) {
      return const Center(
        child: Text(
          'No distribution data available',
          style: TextStyle(color: AppColors.slate400, fontSize: 12),
        ),
      );
    }

    final total = widget.segments.fold<double>(0, (sum, s) => sum + s.value);

    return AnimatedBuilder(
      animation: _sweepAnimation,
      builder: (context, child) {
        final progress = isReduced ? 1.0 : _sweepAnimation.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                startDegreeOffset: -90,
                borderData: FlBorderData(show: false),
                sectionsSpace: 3,
                centerSpaceRadius: widget.centerHoleRadius,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = response.touchedSection!.touchedSectionIndex;
                    });
                    if (event is FlTapUpEvent && _touchedIndex >= 0 && _touchedIndex < widget.segments.length) {
                      final segment = widget.segments[_touchedIndex];
                      if (widget.onSegmentSelected != null && segment.payload != null) {
                        widget.onSegmentSelected!(segment.payload);
                      }
                    }
                  },
                ),
                sections: widget.segments.asMap().entries.map((e) {
                  final idx = e.key;
                  final s = e.value;
                  final isTouched = idx == _touchedIndex;
                  final radius = isTouched ? widget.radius + 6 : widget.radius;

                  return PieChartSectionData(
                    color: s.color,
                    value: s.value * progress,
                    title: total > 0 ? '${((s.value / total) * 100).round()}%' : '',
                    radius: radius,
                    titleStyle: TextStyle(
                      fontSize: isTouched ? 12 : 10.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),

            // Center Animated Number & Label
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.centerValue != null)
                  Text(
                    widget.centerValue!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  )
                else if (widget.centerValueNumber > 0)
                  Text(
                    '${(widget.centerValueNumber * progress).round()}${widget.centerValueSuffix ?? ''}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                if (widget.centerLabel != null)
                  Text(
                    widget.centerLabel!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
