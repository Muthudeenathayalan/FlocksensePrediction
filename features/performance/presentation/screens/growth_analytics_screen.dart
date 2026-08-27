import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/shared/analytics/animated_chart_container.dart';
import 'package:flock_sense/shared/analytics/animated_kpi_card.dart';
import 'package:flock_sense/shared/analytics/animated_line_chart.dart';
import 'package:flock_sense/shared/analytics/biosecurity_score_bar.dart';

/// Growth, Performance & Epidemiological FCR Analytics Screen (SIH26128)
class GrowthAnalyticsScreen extends StatefulWidget {
  const GrowthAnalyticsScreen({super.key});

  @override
  State<GrowthAnalyticsScreen> createState() => _GrowthAnalyticsScreenState();
}

class _GrowthAnalyticsScreenState extends State<GrowthAnalyticsScreen> {
  String _selectedTimeframe = '30D';
  String _fcrTimeframe = '30D';

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          WebPageHeader(
            title: 'Growth, Health & FCR Analytics',
            subtitle: 'Deep epidemiological telemetry, Feed Conversion Ratio curves, and bio-security benchmarks.',
            actions: [
              AppButton(
                label: 'Export Analytics PDF',
                icon: Icons.download_rounded,
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.small,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting analytics charts to PDF...')),
                  );
                },
              ),
            ],
          ),

          // 2. 4 Top Analytics Animated KPIs
          Row(
            children: const [
              Expanded(
                child: AnimatedKpiCard(
                  title: 'Average Flock FCR',
                  numericValue: 1.48,
                  decimalDigits: 2,
                  suffix: 'FCR',
                  delta: '-0.04 (Better)',
                  isPositiveDelta: true,
                  subtitle: 'Breed standard: 1.52',
                  icon: Icons.speed_outlined,
                  accentColor: AppColors.healthy,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: AnimatedKpiCard(
                  title: 'European Production Index (EPEF)',
                  numericValue: 382,
                  suffix: 'EPEF',
                  delta: '+14 pts',
                  isPositiveDelta: true,
                  subtitle: 'Top 10% Industry Tier',
                  icon: Icons.star_outline_rounded,
                  accentColor: AppColors.primary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: AnimatedKpiCard(
                  title: 'Flock Uniformity %',
                  numericValue: 88.4,
                  decimalDigits: 1,
                  suffix: '%',
                  delta: 'Optimal (>85%)',
                  isPositiveDelta: true,
                  subtitle: 'Sample size: 100 birds',
                  icon: Icons.balance_outlined,
                  accentColor: AppColors.info,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: AnimatedKpiCard(
                  title: 'Mortality Rate',
                  numericValue: 1.60,
                  decimalDigits: 2,
                  suffix: '%',
                  delta: 'Standard: < 3.0%',
                  isPositiveDelta: true,
                  subtitle: 'Target harvest day 38',
                  icon: Icons.health_and_safety_outlined,
                  accentColor: AppColors.slate700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Two Interactive Animated Chart Columns
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Weight Progression Curve & FCR Trend
                  Expanded(
                    flex: isWide ? 6 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 3A. Body Weight Progression vs Cobb 500 Standard
                        AnimatedChartContainer(
                          title: 'Body Weight Progression vs Cobb 500 Standard',
                          subtitle: 'Weekly average bird weight (grams) vs genetic breed standard curve',
                          selectedTimeRange: _selectedTimeframe,
                          onTimeRangeChanged: (val) => setState(() => _selectedTimeframe = val),
                          legendItems: const [
                            LegendItemData(label: 'Actual Flock Weight (g)', color: AppColors.primary),
                            LegendItemData(label: 'Cobb 500 Genetic Standard', color: AppColors.slate400, isDashed: true),
                          ],
                          height: 250,
                          child: AnimatedLineChart(
                            yUnit: 'g',
                            maxY: 2400,
                            series: [
                              LineChartSeriesData(
                                name: 'Actual Weight',
                                color: AppColors.primary,
                                hasAreaFill: true,
                                strokeWidth: 2.8,
                                points: const [
                                  ChartDataPoint(x: 0, y: 185, label: 'Day 7'),
                                  ChartDataPoint(x: 1, y: 460, label: 'Day 14'),
                                  ChartDataPoint(x: 2, y: 890, label: 'Day 21'),
                                  ChartDataPoint(x: 3, y: 1420, label: 'Day 28'),
                                  ChartDataPoint(x: 4, y: 2010, label: 'Day 35'),
                                ],
                              ),
                              LineChartSeriesData(
                                name: 'Breed Standard',
                                color: AppColors.slate400,
                                isDashed: true,
                                hasAreaFill: false,
                                strokeWidth: 1.8,
                                points: const [
                                  ChartDataPoint(x: 0, y: 180, label: 'Day 7'),
                                  ChartDataPoint(x: 1, y: 450, label: 'Day 14'),
                                  ChartDataPoint(x: 2, y: 875, label: 'Day 21'),
                                  ChartDataPoint(x: 3, y: 1390, label: 'Day 28'),
                                  ChartDataPoint(x: 4, y: 1980, label: 'Day 35'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3B. Feed & Water Telemetry Intake Curve
                        AnimatedChartContainer(
                          title: 'Daily Feed & Water Intake Telemetry',
                          subtitle: 'Daily feed consumption (kg) and water intake (L) with abnormal drop detection',
                          selectedTimeRange: _fcrTimeframe,
                          onTimeRangeChanged: (val) => setState(() => _fcrTimeframe = val),
                          legendItems: const [
                            LegendItemData(label: 'Feed Intake (kg)', color: AppColors.info),
                            LegendItemData(label: 'Water Intake (L)', color: AppColors.healthy),
                          ],
                          height: 230,
                          child: AnimatedLineChart(
                            yUnit: '',
                            maxY: 600,
                            series: [
                              LineChartSeriesData(
                                name: 'Feed Intake',
                                color: AppColors.info,
                                hasAreaFill: false,
                                strokeWidth: 2.2,
                                points: const [
                                  ChartDataPoint(x: 0, y: 420, label: 'D24'),
                                  ChartDataPoint(x: 1, y: 440, label: 'D25'),
                                  ChartDataPoint(x: 2, y: 460, label: 'D26'),
                                  ChartDataPoint(x: 3, y: 480, label: 'D27'),
                                  ChartDataPoint(x: 4, y: 410, label: 'D28', isSpike: true, payload: 'FEED_DROP'),
                                  ChartDataPoint(x: 5, y: 470, label: 'D29'),
                                  ChartDataPoint(x: 6, y: 490, label: 'D30'),
                                ],
                              ),
                              LineChartSeriesData(
                                name: 'Water Intake',
                                color: AppColors.healthy,
                                hasAreaFill: false,
                                strokeWidth: 2.2,
                                points: const [
                                  ChartDataPoint(x: 0, y: 520, label: 'D24'),
                                  ChartDataPoint(x: 1, y: 540, label: 'D25'),
                                  ChartDataPoint(x: 2, y: 560, label: 'D26'),
                                  ChartDataPoint(x: 3, y: 580, label: 'D27'),
                                  ChartDataPoint(x: 4, y: 480, label: 'D28'),
                                  ChartDataPoint(x: 5, y: 570, label: 'D29'),
                                  ChartDataPoint(x: 6, y: 590, label: 'D30'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isWide) const SizedBox(width: 20),

                  // Right Column: Biosecurity & Shed Health Distribution
                  if (isWide)
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BiosecurityScoreBar(
                            score: 92,
                            previousScore: 84,
                            ratingText: 'Tier-1 High Integrity',
                            categories: [
                              BiosecurityCategoryItem(title: 'Shed #1 (Broiler North)', scorePercent: 96, color: AppColors.healthy),
                              BiosecurityCategoryItem(title: 'Shed #2 (Broiler South)', scorePercent: 78, color: AppColors.warning),
                              BiosecurityCategoryItem(title: 'Shed #3 (Grower Unit)', scorePercent: 94, color: AppColors.healthy),
                              BiosecurityCategoryItem(title: 'Shed #4 (Finisher Unit)', scorePercent: 92, color: AppColors.healthy),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Container(
                            decoration: AppDesign.cardDecoration,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.tips_and_updates_outlined, size: 20, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Text('AI Growth & Efficiency Insights', style: AppTypography.cardTitle),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '• Flock is tracking +30g above standard weight curve at Day 35.\n'
                                  '• FCR of 1.48 outperforms breed benchmark by 2.6%, saving estimated 480 kg feed.\n'
                                  '• Shed #2 temporary water drop resolved following drinker nipple sanitation.',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.slate800, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
