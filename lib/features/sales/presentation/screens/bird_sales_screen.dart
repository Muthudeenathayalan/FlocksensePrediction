import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/app_empty_state.dart';
import 'package:flock_sense/core/widgets/app_loading_indicator.dart';
import 'package:flock_sense/core/widgets/metric_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/sales/data/sales_service.dart';
import 'package:flock_sense/features/sales/domain/sales_record_model.dart';
import 'package:flock_sense/features/sales/presentation/screens/sales_form_screen.dart';

class BirdSalesScreen extends StatefulWidget {
  const BirdSalesScreen({super.key, this.farmId, this.batchId, this.batchName});

  final String? farmId;
  final String? batchId;
  final String? batchName;

  @override
  State<BirdSalesScreen> createState() => _BirdSalesScreenState();
}

class _BirdSalesScreenState extends State<BirdSalesScreen> {
  bool get _hasContext =>
      (widget.farmId?.isNotEmpty ?? false) &&
      (widget.batchId?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    if (!_hasContext) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: canPop
            ? AppBar(
                title: const Text('Bird Sales Ledger',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                elevation: 0,
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              )
            : null,
        body: const PageContainer(
          child: AppCard(
            padding: EdgeInsets.all(48),
            child: AppEmptyState(
              icon: Icons.point_of_sale_rounded,
              title: 'No Active Batch Selected',
              message: 'Open bird sales from an active flock batch to view and record trade dispatches.',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: canPop
          ? AppBar(
              title: Text('Sales • ${widget.batchName ?? "Batch"}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              elevation: 0,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Web Page Header
            WebPageHeader(
              title: widget.batchName != null
                  ? '${widget.batchName} — Bird Sales Ledger'
                  : 'Bird Sales & Dispatches',
              subtitle:
                  'Record market transactions, customer dispatches, live harvest weights, and batch revenue realization.',
              breadcrumb: 'Batches / ${widget.batchName ?? "Sales"} / Transactions',
              actions: [
                AppButton(
                  label: 'Record New Sale',
                  icon: Icons.add_rounded,
                  size: AppButtonSize.small,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SalesFormScreen(
                        farmId: widget.farmId!,
                        batchId: widget.batchId!,
                        currentBatchAge: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Stream Content
            StreamBuilder<List<SalesRecordModel>>(
              stream: SalesService.watchSalesRecords(widget.farmId!, widget.batchId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: AppLoadingIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return AppCard(
                    padding: const EdgeInsets.all(32),
                    child: AppEmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Error Loading Sales Records',
                      message: '${snapshot.error}',
                    ),
                  );
                }

                final records = snapshot.data ?? <SalesRecordModel>[];
                if (records.isEmpty) {
                  return AppCard(
                    padding: const EdgeInsets.all(48),
                    child: AppEmptyState(
                      icon: Icons.point_of_sale_outlined,
                      title: 'No sales recorded for this batch yet',
                      message: 'Record the first bird dispatch, customer name, live bird weight, and price per bird.',
                      buttonLabel: 'Record First Sale',
                      onButtonPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SalesFormScreen(
                            farmId: widget.farmId!,
                            batchId: widget.batchId!,
                            currentBatchAge: 0,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Calculate KPIs
                final totalBirds = records.fold<int>(0, (sum, r) => sum + r.birdsSold);
                final totalRevenue = records.fold<double>(0.0, (sum, r) => sum + r.totalValue);
                final avgWeight = totalBirds > 0
                    ? records.fold<double>(0.0, (sum, r) => sum + (r.averageWeightKg * r.birdsSold)) / totalBirds
                    : 0.0;

                final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Row
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 768;
                        return GridView.count(
                          crossAxisCount: isDesktop ? 3 : 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isDesktop ? 3.0 : 4.0,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            MetricCard(
                              title: 'Total Birds Sold',
                              value: NumberFormat.decimalPattern().format(totalBirds),
                              subtitle: '${records.length} transactions recorded',
                              icon: Icons.pets_rounded,
                              accentColor: AppColors.primary,
                            ),
                            MetricCard(
                              title: 'Realized Revenue',
                              value: currencyFmt.format(totalRevenue),
                              subtitle: 'Cumulative sale revenue',
                              icon: Icons.account_balance_wallet_rounded,
                              accentColor: AppColors.emerald,
                            ),
                            MetricCard(
                              title: 'Avg Harvest Weight',
                              value: '${avgWeight.toStringAsFixed(2)} kg',
                              subtitle: 'Weighted average bird weight',
                              icon: Icons.scale_rounded,
                              accentColor: AppColors.indigo,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    AppDesign.sectionTitle('Sales Transactions (${records.length})'),

                    // Sales List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final record = records[index];
                        return AppCard(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                                ),
                                child: const Icon(Icons.sell_rounded,
                                    color: AppColors.emerald, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          record.customerName,
                                          style: AppTypography.cardTitle,
                                        ),
                                        const SizedBox(width: 8),
                                        AppDesign.statusChip(
                                          '${record.birdsSold} BIRDS',
                                          AppColors.primaryLight,
                                          textColor: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 4,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.calendar_today_outlined,
                                                size: 13, color: AppColors.slate400),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat('dd MMM yyyy').format(record.date),
                                              style: AppTypography.caption,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.scale_outlined,
                                                size: 13, color: AppColors.slate400),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Avg: ${record.averageWeightKg.toStringAsFixed(2)} kg',
                                              style: AppTypography.caption,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.currency_rupee_rounded,
                                                size: 13, color: AppColors.slate400),
                                            const SizedBox(width: 4),
                                            Text(
                                              '₹${record.pricePerBird.toStringAsFixed(1)} / bird',
                                              style: AppTypography.caption,
                                            ),
                                          ],
                                        ),
                                        if (record.vehicleNumber != null &&
                                            record.vehicleNumber!.isNotEmpty)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.local_shipping_outlined,
                                                  size: 13, color: AppColors.slate400),
                                              const SizedBox(width: 4),
                                              Text(
                                                record.vehicleNumber!,
                                                style: AppTypography.caption,
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFmt.format(record.totalValue),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.emerald,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Total Realized',
                                    style: TextStyle(fontSize: 11, color: AppColors.slate400),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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
}
