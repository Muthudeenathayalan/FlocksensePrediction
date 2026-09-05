import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/metric_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/inventory/data/inventory_service.dart';
import 'package:flock_sense/features/inventory/domain/inventory_item_model.dart';
import 'package:flock_sense/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:flock_sense/features/inventory/presentation/screens/inventory_item_detail_screen.dart';
import 'package:flock_sense/features/inventory/presentation/screens/inventory_item_form_screen.dart';
import 'package:flock_sense/features/inventory/presentation/widgets/inventory_item_tile.dart';
import 'package:flock_sense/features/inventory/presentation/widgets/stock_movement_dialog.dart';
import 'package:flock_sense/features/inventory/services/inventory_export_service.dart';

class InventoryDashboardScreen extends ConsumerWidget {
  const InventoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryStreamProvider);
    final filteredItems = ref.watch(filteredInventoryListProvider);
    final stats = ref.watch(inventoryStatsProvider);

    final selectedCategory = ref.watch(inventoryCategoryFilterProvider);
    final selectedSort = ref.watch(inventorySortProvider);
    final searchQuery = ref.watch(inventorySearchQueryProvider);

    final rawItems = inventoryAsync.value ?? InventoryService.sampleInventoryItems;
    final allRawItems = rawItems.isNotEmpty ? rawItems : InventoryService.sampleInventoryItems;
    final displayItems = filteredItems.isNotEmpty ? filteredItems : (searchQuery.isEmpty && selectedCategory == 'All' ? allRawItems : filteredItems);

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Web Page Header
          WebPageHeader(
            title: 'Inventory Stock & Supplies',
            subtitle: 'Real-time tracking for feed storage, medicine, vaccines, and equipment valuations.',
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Export Stock Reports',
                onSelected: (val) {
                  switch (val) {
                    case 'pdf':
                      InventoryExportService.printOrPreviewPdf(
                        context: context,
                        items: displayItems,
                        stats: stats,
                        title: 'Inventory Summary Report',
                      );
                      break;
                    case 'csv':
                      _showCsvDialog(context, displayItems);
                      break;
                    case 'share':
                      InventoryExportService.shareReport(
                        context: context,
                        items: displayItems,
                        stats: stats,
                        title: 'Inventory Data',
                      );
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf_outlined, color: AppColors.critical, size: 18),
                        SizedBox(width: 10),
                        Text('Export PDF Report'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'csv',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart_outlined, color: AppColors.healthy, size: 18),
                        SizedBox(width: 10),
                        Text('Export CSV Spreadsheet'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined, color: AppColors.info, size: 18),
                        SizedBox(width: 10),
                        Text('Share Summary'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.download_rounded, size: 16, color: AppColors.slate700),
                      SizedBox(width: 6),
                      Text('Export', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate700)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 16, color: AppColors.slate500),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'Add Stock Item',
                icon: Icons.add_rounded,
                size: AppButtonSize.small,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InventoryItemFormScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // 2. 4 Clean SaaS KPI Metric Cards
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Feed In Stock',
                  value: '${stats.totalFeedStockKg.toStringAsFixed(0)} kg',
                  subtitle: '2 active silo batches',
                  icon: Icons.inventory_2_outlined,
                  accentColor: AppColors.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  title: 'Medicine & Vaccines',
                  value: '${(stats.totalMedicineStockUnits + stats.totalVaccineStockDoses).toStringAsFixed(0)} Doses',
                  subtitle: 'Cold storage optimal',
                  icon: Icons.medical_services_outlined,
                  accentColor: AppColors.info,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  title: 'Total Stock Valuation',
                  value: '₹${stats.totalInventoryValue.toStringAsFixed(0)}',
                  subtitle: 'Estimated asset value',
                  icon: Icons.account_balance_wallet_outlined,
                  accentColor: AppColors.healthy,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  title: 'Stock Health Alert',
                  value: stats.lowStockCount == 0 ? 'Optimal' : '${stats.lowStockCount} Low',
                  subtitle: stats.expiredCount == 0 ? '0 Expired items' : '${stats.expiredCount} Expired',
                  delta: stats.lowStockCount == 0 ? 'Good' : 'Restock',
                  isPositiveDelta: stats.lowStockCount == 0,
                  icon: Icons.shield_outlined,
                  accentColor: stats.lowStockCount == 0 ? AppColors.primary : AppColors.critical,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Search & Filter Bar Toolbar inside AppCard
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) {
                          ref.read(inventorySearchQueryProvider.notifier).state = val;
                        },
                        decoration: InputDecoration(
                          hintText: 'Search stock items, suppliers, active ingredients...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    ref.read(inventorySearchQueryProvider.notifier).state = '';
                                  },
                                )
                              : null,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<InventorySortOption>(
                          value: selectedSort,
                          icon: const Icon(Icons.sort_rounded, color: AppColors.primary, size: 20),
                          items: const [
                            DropdownMenuItem(value: InventorySortOption.newest, child: Text('Newest First', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                            DropdownMenuItem(value: InventorySortOption.oldest, child: Text('Oldest First', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                            DropdownMenuItem(value: InventorySortOption.quantity, child: Text('Highest Quantity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                            DropdownMenuItem(value: InventorySortOption.expiryDate, child: Text('Expiring Soonest', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                            DropdownMenuItem(value: InventorySortOption.alphabetical, child: Text('Alphabetical (A-Z)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(inventorySortProvider.notifier).state = val;
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _categoryChip(ref, 'All', selectedCategory == 'All'),
                      const SizedBox(width: 8),
                      _categoryChip(ref, 'Feed', selectedCategory == 'Feed'),
                      const SizedBox(width: 8),
                      _categoryChip(ref, 'Medicine', selectedCategory == 'Medicine'),
                      const SizedBox(width: 8),
                      _categoryChip(ref, 'Vaccines', selectedCategory == 'Vaccines'),
                      const SizedBox(width: 8),
                      _categoryChip(ref, 'Equipment', selectedCategory == 'Equipment'),
                      const SizedBox(width: 8),
                      _categoryChip(
                        ref,
                        'Low Stock',
                        selectedCategory == 'Low Stock',
                        badgeCount: stats.lowStockCount,
                        badgeColor: AppColors.critical,
                      ),
                      const SizedBox(width: 8),
                      _categoryChip(
                        ref,
                        'Expired',
                        selectedCategory == 'Expired',
                        badgeCount: stats.expiredCount,
                        badgeColor: AppColors.critical,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Stock Items Grid / List
          if (displayItems.isEmpty)
            _buildEmptyState(context, allRawItems.isEmpty)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = displayItems[index];
                return InventoryItemTile(
                  item: item,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InventoryItemDetailScreen(item: item),
                      ),
                    );
                  },
                  onIncreaseStock: () => _openStockModal(context, item, 'increase'),
                  onReduceStock: () => _openStockModal(context, item, 'reduce'),
                  onTransferStock: () => _openStockModal(context, item, 'transfer'),
                );
              },
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _categoryChip(
    WidgetRef ref,
    String label,
    bool selected, {
    int badgeCount = 0,
    Color? badgeColor,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (badgeCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white : (badgeColor ?? AppColors.primary),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: selected ? (badgeColor ?? AppColors.primaryDark) : Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: selected,
      onSelected: (_) {
        ref.read(inventoryCategoryFilterProvider.notifier).state = label;
      },
      selectedColor: AppColors.primaryLight,
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? AppColors.primaryDark : AppColors.slate700,
      ),
    );
  }

  void _openStockModal(BuildContext context, InventoryItemModel item, String action) {
    showDialog(
      context: context,
      builder: (_) => StockMovementDialog(item: item, action: action),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isTotalEmpty) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: AppDesign.cardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 28, color: AppColors.slate600),
            ),
            const SizedBox(height: 16),
            Text(
              isTotalEmpty ? 'No inventory items registered' : 'No matching items found',
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: 6),
            Text(
              isTotalEmpty
                  ? 'Add your feed, medicine, vaccine, or equipment stock to start automated inventory tracking.'
                  : 'Try adjusting your search keywords or active category filters.',
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Add Stock Item',
              icon: Icons.add_rounded,
              size: AppButtonSize.medium,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryItemFormScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCsvDialog(BuildContext context, List<InventoryItemModel> items) {
    final csv = InventoryExportService.generateInventoryCsvReport(items);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV Export Preview', style: AppTypography.titleLarge),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              csv,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          AppButton(
            label: 'Close',
            variant: AppButtonVariant.outlined,
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(ctx),
          ),
          AppButton(
            label: 'Share CSV',
            icon: Icons.share_rounded,
            size: AppButtonSize.small,
            onPressed: () {
              Navigator.pop(ctx);
              InventoryExportService.shareReport(
                context: context,
                items: items,
                stats: InventoryStats.empty,
                title: 'Inventory Data',
              );
            },
          ),
        ],
      ),
    );
  }
}
