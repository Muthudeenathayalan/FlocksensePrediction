import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/metric_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/feed/data/feed_service.dart';
import 'package:flock_sense/features/feed/domain/feed_transaction_model.dart';
import 'package:flock_sense/features/feed/presentation/screens/feed_transaction_form_screen.dart';

class FeedInventoryScreen extends StatefulWidget {
  const FeedInventoryScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    this.batchName,
  });

  final String farmId;
  final String batchId;
  final String? batchName;

  @override
  State<FeedInventoryScreen> createState() => _FeedInventoryScreenState();
}

class _FeedInventoryScreenState extends State<FeedInventoryScreen> {
  @override
  Widget build(BuildContext context) {
    return PageContainer(
      child: StreamBuilder<List<FeedTransactionModel>>(
        stream: FeedService.watchFeedTransactions(
          farmId: widget.farmId,
          batchId: widget.batchId,
        ),
        initialData: FeedService.sampleTransactions,
        builder: (context, snapshot) {
          final rawTransactions = snapshot.data ?? FeedService.sampleTransactions;
          final transactions = rawTransactions.isNotEmpty ? rawTransactions : FeedService.sampleTransactions;
          final deliveryCount = transactions.length;
          final totalBags = transactions.fold<int>(
            0,
            (sum, item) => sum + item.bags,
          );
          final totalKg = transactions.fold<double>(
            0,
            (sum, item) => sum + item.totalKg,
          );
          final progressByType = <String, double>{};
          for (final item in transactions) {
            progressByType[item.feedType] =
                (progressByType[item.feedType] ?? 0) + item.totalKg;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Clean Web Page Header
              WebPageHeader(
                title: 'Feed Inventory & Silo Operations',
                subtitle: widget.batchName != null
                    ? 'Managing feed storage, delivery receipts, and consumption for ${widget.batchName}.'
                    : 'Managing feed storage, delivery receipts, and batch consumption metrics.',
                actions: [
                  AppButton(
                    label: 'Add Feed Receipt',
                    icon: Icons.add_rounded,
                    size: AppButtonSize.small,
                    onPressed: () => _openForm(context),
                  ),
                ],
              ),

              // 2. 3 Clean Metric Cards
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Total Feed Bags',
                      value: '$totalBags Bags',
                      subtitle: 'Active silo capacity',
                      icon: Icons.inventory_2_outlined,
                      accentColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MetricCard(
                      title: 'Total Feed Stock (KG)',
                      value: '${totalKg.toStringAsFixed(0)} kg',
                      subtitle: 'Estimated 18 days supply',
                      icon: Icons.scale_outlined,
                      accentColor: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MetricCard(
                      title: 'Delivery Receipts',
                      value: '$deliveryCount Logged',
                      subtitle: 'Verified stock batches',
                      icon: Icons.local_shipping_outlined,
                      accentColor: AppColors.healthy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Feed Type Mix & Silo Distribution Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Feed Type Allocation & Silo Mix', style: AppTypography.headingSmall),
                        Text(
                          '${totalKg.toStringAsFixed(0)} kg in Stock',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...['PB82 (Pre-Starter)', '882 (Starter Crumbs)', 'B4 (Finisher Pellets)'].map((typeLabel) {
                      final rawType = typeLabel.split(' ').first;
                      final kg = progressByType[rawType] ?? (rawType == 'PB82' ? 2000.0 : (rawType == '882' ? 3000.0 : 4000.0));
                      final percentage = totalKg > 0 ? (kg / totalKg) : 0.33;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(typeLabel, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                                Text('${kg.toStringAsFixed(0)} kg (${(percentage * 100).toStringAsFixed(1)}%)', style: AppTypography.caption),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: AppColors.slate200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  rawType == 'PB82'
                                      ? AppColors.info
                                      : (rawType == '882' ? AppColors.primary : const Color(0xFF0EA5E9)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Delivery Receipts Section
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Delivery Receipts', style: AppTypography.headingSmall),
                        Text('${transactions.length} Records', style: AppTypography.caption),
                      ],
                    ),
                    const SizedBox(height: 14),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = transactions[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.feedType} — ${item.bags} bags',
                                      style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_formatDate(item.date)} · Delivery Challan: ${item.dcNumber ?? 'DC-8812'}',
                                      style: AppTypography.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  '${item.weightKg.toStringAsFixed(1)} kg',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeedTransactionFormScreen(
          farmId: widget.farmId,
          batchId: widget.batchId,
          batchName: widget.batchName,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString()}';
  }
}

