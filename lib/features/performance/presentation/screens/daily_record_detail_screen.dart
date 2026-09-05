import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/metric_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/performance/domain/performance_calculator.dart';

class DailyRecordDetailScreen extends StatelessWidget {
  const DailyRecordDetailScreen({
    super.key,
    required this.record,
    required this.batchName,
  });

  final DailyRecordModel record;
  final String batchName;

  @override
  Widget build(BuildContext context) {
    final openingBirds = record.openingBirds;
    final closingBirds = record.closingBirds;
    final standardWeight =
        PerformanceCalculator.skmBodyWeightStd[record.batchAgeDay];
    final diff = standardWeight != null
        ? record.avgWeightGrams - standardWeight
        : null;

    final dateStr = DateFormat('dd MMMM yyyy').format(record.date);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Day ${record.batchAgeDay} • $batchName',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            WebPageHeader(
              title: 'Daily Telemetry Detail — Day ${record.batchAgeDay}',
              subtitle: '$batchName • Observation Date: $dateStr',
              breadcrumb: 'Daily Records / $batchName / Day ${record.batchAgeDay}',
            ),

            // 2. Summary Metric Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 768;
                return GridView.count(
                  crossAxisCount: isDesktop ? 4 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 2.5 : 2.0,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    MetricCard(
                      title: 'Live Closing Birds',
                      value: NumberFormat.decimalPattern().format(closingBirds),
                      subtitle: 'Opening: $openingBirds birds',
                      icon: Icons.pets_rounded,
                      iconColor: AppColors.primary,
                    ),
                    MetricCard(
                      title: 'Daily Mortality',
                      value: '${record.mortalityCount} birds',
                      subtitle: '${((record.mortalityCount / (openingBirds > 0 ? openingBirds : 1)) * 100).toStringAsFixed(2)}% of flock',
                      icon: Icons.error_outline_rounded,
                      iconColor: record.mortalityCount > 5 ? AppColors.danger : AppColors.slate700,
                    ),
                    MetricCard(
                      title: 'Feed Consumed',
                      value: '${record.feedConsumedKg.toStringAsFixed(1)} kg',
                      subtitle: '${(record.feedConsumedKg * 1000 / (closingBirds > 0 ? closingBirds : 1)).toStringAsFixed(0)} g / bird',
                      icon: Icons.grass_rounded,
                      iconColor: AppColors.amber,
                    ),
                    MetricCard(
                      title: 'Water Consumed',
                      value: '${record.waterConsumedLiters.toStringAsFixed(0)} L',
                      subtitle: '${(record.waterConsumedLiters * 1000 / (closingBirds > 0 ? closingBirds : 1)).toStringAsFixed(0)} ml / bird',
                      icon: Icons.water_drop_rounded,
                      iconColor: AppColors.teal,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // 3. Detailed Parameter Sections
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;
                return isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildSection(
                              'Flock Demographics & Mortality',
                              Icons.pets_rounded,
                              AppColors.primary,
                              [
                                _row('Opening Bird Count', '$openingBirds birds'),
                                _row('Daily Mortality', '${record.mortalityCount} birds'),
                                _row('Cull / Rejected Birds', '${record.cullCount} birds'),
                                _row('Closing Bird Count', '$closingBirds birds', isHighlight: true),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildSection(
                              'Growth & Weight Gain',
                              Icons.trending_up_rounded,
                              AppColors.purple,
                              [
                                _row('Sampled Average Weight', '${record.avgWeightGrams.toStringAsFixed(0)} g/bird'),
                                _row('Breed Target Standard', standardWeight != null ? '${standardWeight.toStringAsFixed(0)} g/bird' : '–'),
                                _row('Standard Weight Variance', diff != null ? '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(0)} g' : '–'),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildSection(
                            'Flock Demographics & Mortality',
                            Icons.pets_rounded,
                            AppColors.primary,
                            [
                              _row('Opening Bird Count', '$openingBirds birds'),
                              _row('Daily Mortality', '${record.mortalityCount} birds'),
                              _row('Cull / Rejected Birds', '${record.cullCount} birds'),
                              _row('Closing Bird Count', '$closingBirds birds', isHighlight: true),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            'Growth & Weight Gain',
                            Icons.trending_up_rounded,
                            AppColors.purple,
                            [
                              _row('Sampled Average Weight', '${record.avgWeightGrams.toStringAsFixed(0)} g/bird'),
                              _row('Breed Target Standard', standardWeight != null ? '${standardWeight.toStringAsFixed(0)} g/bird' : '–'),
                              _row('Standard Weight Variance', diff != null ? '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(0)} g' : '–'),
                            ],
                          ),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTypography.h3.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.slate500)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? AppColors.primary : AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }
}
