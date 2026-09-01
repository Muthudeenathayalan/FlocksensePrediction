import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/shared/analytics/chart_animation_config.dart';

class BarChartItemData {
  final String label;
  final double value;
  final Color color;
  final String? subtitle;
  final dynamic payload;

  const BarChartItemData({
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
    this.payload,
  });
}

/// Animated Bar Chart supporting Vertical Staggered Bars & Horizontal Ranking Bars
class AnimatedBarChart extends StatefulWidget {
  final List<BarChartItemData> items;
  final bool isHorizontal;
  final double? maxY;
  final String? unit;
  final Function(dynamic payload)? onItemSelected;

  const AnimatedBarChart({
    super.key,
    required this.items,
    this.isHorizontal = false,
    this.maxY,
    this.unit,
    this.onItemSelected,
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _growthController;
  late Animation<double> _growthAnimation;

  @override
  void initState() {
    super.initState();
    _growthController = AnimationController(
      vsync: this,
      duration: ChartAnimationConfig.initialLoad,
    );

    _growthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _growthController,
        curve: ChartAnimationConfig.defaultCurve,
      ),
    );

    _growthController.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _growthController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _growthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReduced = ChartAnimationConfig.isReducedMotion(context);

    if (widget.items.isEmpty) {
      return const Center(
        child: Text(
          'No bar records available',
          style: TextStyle(color: AppColors.slate400, fontSize: 12),
        ),
      );
    }

    if (widget.isHorizontal) {
      return _buildHorizontalBars(isReduced);
    }

    return _buildVerticalBars(isReduced);
  }

  Widget _buildVerticalBars(bool isReduced) {
    final computedMax = widget.items.fold<double>(
          5.0,
          (max, p) => p.value > max ? p.value : max,
        ) * 1.25;
    final safeMaxY = widget.maxY ?? (computedMax > 1.0 ? computedMax : 5.0);
    final bottomInterval = (widget.items.length / 6).clamp(1.0, 10.0);

    return AnimatedBuilder(
      animation: _growthAnimation,
      builder: (context, child) {
        final progress = isReduced ? 1.0 : _growthAnimation.value;

        return BarChart(
          BarChartData(
            maxY: safeMaxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
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
                  reservedSize: 28,
                  getTitlesWidget: (val, meta) {
                    return Text(
                      '${val.toInt()}${widget.unit ?? ''}',
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
                    final idx = val.toInt();
                    if (idx >= 0 && idx < widget.items.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          widget.items[idx].label,
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
            barTouchData: BarTouchData(
              enabled: true,
              touchCallback: (event, response) {
                if (event is FlTapUpEvent && response != null && response.spot != null) {
                  final idx = response.spot!.touchedBarGroupIndex;
                  if (idx >= 0 && idx < widget.items.length) {
                    final item = widget.items[idx];
                    if (widget.onItemSelected != null && item.payload != null) {
                      widget.onItemSelected!(item.payload);
                    }
                  }
                }
              },
            ),
            barGroups: widget.items.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.value * progress,
                    color: e.value.color,
                    width: widget.items.length > 15 ? 8 : 16,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalBars(bool isReduced) {
    final maxVal = widget.items.fold<double>(
      10.0,
      (max, item) => item.value > max ? item.value : max,
    );

    return AnimatedBuilder(
      animation: _growthAnimation,
      builder: (context, child) {
        final progress = isReduced ? 1.0 : _growthAnimation.value;

        return ListView.separated(
          itemCount: widget.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final item = widget.items[idx];
            final ratio = (item.value / maxVal).clamp(0.0, 1.0) * progress;

            return InkWell(
              onTap: () {
                if (widget.onItemSelected != null && item.payload != null) {
                  widget.onItemSelected!(item.payload);
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.slate900),
                        ),
                        Text(
                          '${item.value.toStringAsFixed(0)}${widget.unit ?? ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: item.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 8,
                        width: double.infinity,
                        color: AppColors.slate100,
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: ratio,
                          child: Container(
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
