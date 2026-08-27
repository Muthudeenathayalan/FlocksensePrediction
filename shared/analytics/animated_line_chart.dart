import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/shared/analytics/chart_animation_config.dart';
import 'package:flock_sense/shared/analytics/chart_tooltip.dart';

class ChartDataPoint {
  final double x;
  final double y;
  final String label;
  final bool isSpike;
  final dynamic payload;

  const ChartDataPoint({
    required this.x,
    required this.y,
    required this.label,
    this.isSpike = false,
    this.payload,
  });
}

class LineChartSeriesData {
  final String name;
  final List<ChartDataPoint> points;
  final Color color;
  final bool isDashed;
  final bool hasAreaFill;
  final double strokeWidth;

  const LineChartSeriesData({
    required this.name,
    required this.points,
    required this.color,
    this.isDashed = false,
    this.hasAreaFill = true,
    this.strokeWidth = 2.4,
  });
}

/// High-Performance Animated Line Chart supporting Left-to-Right Draw, Spike Halos & Tooltips
class AnimatedLineChart extends StatefulWidget {
  final List<LineChartSeriesData> series;
  final double? minY;
  final double? maxY;
  final String? yUnit;
  final Function(dynamic payload)? onPointSelected;
  final AnalyticsTooltipData Function(LineChartSeriesData s, ChartDataPoint p)? tooltipBuilder;

  const AnimatedLineChart({
    super.key,
    required this.series,
    this.minY,
    this.maxY,
    this.yUnit,
    this.onPointSelected,
    this.tooltipBuilder,
  });

  @override
  State<AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _drawController;
  late Animation<double> _drawAnimation;

  @override
  void initState() {
    super.initState();
    _drawController = AnimationController(
      vsync: this,
      duration: ChartAnimationConfig.initialLoad,
    );

    _drawAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _drawController,
        curve: ChartAnimationConfig.defaultCurve,
      ),
    );

    _drawController.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart animation only when series data actually changes
    if (oldWidget.series.length != widget.series.length ||
        (oldWidget.series.isNotEmpty && widget.series.isNotEmpty &&
         oldWidget.series.first.points.length != widget.series.first.points.length)) {
      _drawController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _drawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = ChartAnimationConfig.isReducedMotion(context);

    if (widget.series.isEmpty || widget.series.every((s) => s.points.isEmpty)) {
      return const Center(
        child: Text(
          'No chart points recorded for this period',
          style: TextStyle(color: AppColors.slate400, fontSize: 12),
        ),
      );
    }

    // Determine min/max Y
    double calculatedMaxY = 10.0;
    double calculatedMinY = 0.0;
    for (final s in widget.series) {
      for (final p in s.points) {
        if (p.y > calculatedMaxY) calculatedMaxY = p.y;
        if (p.y < calculatedMinY) calculatedMinY = p.y;
      }
    }
    final safeMaxY = widget.maxY ?? (calculatedMaxY * 1.25);
    final safeMinY = widget.minY ?? (calculatedMinY < 0 ? calculatedMinY * 1.1 : 0.0);

    final referencePoints = widget.series.first.points;
    final bottomInterval = (referencePoints.length / 5).clamp(1.0, 10.0);

    return AnimatedBuilder(
      animation: _drawAnimation,
      builder: (context, child) {
        final progress = isReduced ? 1.0 : _drawAnimation.value;

        return LineChart(
          LineChartData(
            minY: safeMinY,
            maxY: safeMaxY > safeMinY ? safeMaxY : safeMinY + 10.0,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (safeMaxY - safeMinY) / 4 > 0 ? (safeMaxY - safeMinY) / 4 : 2.0,
              getDrawingHorizontalLine: (val) => FlLine(
                color: AppColors.slate200,
                strokeWidth: 0.8,
                dashArray: [4, 4],
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (val, meta) {
                    return Text(
                      '${val.round()}${widget.yUnit ?? ''}',
                      style: const TextStyle(fontSize: 10, color: AppColors.slate500),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: bottomInterval,
                  getTitlesWidget: (val, meta) {
                    final index = val.toInt();
                    if (index >= 0 && index < referencePoints.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          referencePoints[index].label,
                          style: const TextStyle(fontSize: 10.5, color: AppColors.slate500, fontWeight: FontWeight.w500),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => AppColors.slate900,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                tooltipMargin: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final s = widget.series[spot.barIndex];
                    if (spot.spotIndex >= s.points.length) return null;
                    final p = s.points[spot.spotIndex];

                    return LineTooltipItem(
                      '',
                      const TextStyle(),
                      children: [
                        TextSpan(
                          text: '${p.label}: ${p.y.toStringAsFixed(1)}${widget.yUnit ?? ''}\n',
                          style: TextStyle(
                            color: s.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
              touchCallback: (event, response) {
                if (event is FlTapUpEvent && response != null && response.lineBarSpots != null) {
                  final spot = response.lineBarSpots!.first;
                  final s = widget.series[spot.barIndex];
                  if (spot.spotIndex < s.points.length) {
                    final p = s.points[spot.spotIndex];
                    if (widget.onPointSelected != null && p.payload != null) {
                      widget.onPointSelected!(p.payload);
                    }
                  }
                }
              },
            ),
            lineBarsData: widget.series.map((s) {
              final visibleCount = (s.points.length * progress).clamp(0, s.points.length).toInt();
              final visiblePoints = s.points.take(visibleCount).toList();

              return LineChartBarData(
                spots: visiblePoints.map((p) => FlSpot(p.x, p.y)).toList(),
                isCurved: true,
                curveSmoothness: 0.25,
                color: s.color,
                barWidth: s.strokeWidth,
                isStrokeCapRound: true,
                dashArray: s.isDashed ? [6, 4] : null,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    final isSpike = index < s.points.length && s.points[index].isSpike;
                    if (isSpike) {
                      return FlDotCirclePainter(
                        radius: 5.5,
                        color: AppColors.critical,
                        strokeWidth: 2.5,
                        strokeColor: Colors.white,
                      );
                    }
                    return FlDotCirclePainter(
                      radius: 3.0,
                      color: s.color,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: s.hasAreaFill,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      s.color.withOpacity(0.20 * progress),
                      s.color.withOpacity(0.01 * progress),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
