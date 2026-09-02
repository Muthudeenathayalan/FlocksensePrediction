import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_empty_state.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/responsive_data_table.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/presentation/providers/batch_providers.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_command_center_screen.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_form_screen.dart';

class BatchListScreen extends ConsumerStatefulWidget {
  const BatchListScreen({
    super.key,
    required this.farmId,
    this.farmName,
    this.shedId,
  });

  final String farmId;
  final String? farmName;
  final String? shedId;

  @override
  ConsumerState<BatchListScreen> createState() => _BatchListScreenState();
}

class _BatchListScreenState extends ConsumerState<BatchListScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(batchListProvider(widget.farmId));

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Web Page Header
          WebPageHeader(
            title: widget.farmName != null
                ? '${widget.farmName} — Flocks & Batches'
                : 'Flocks & Batches',
            subtitle:
                'Track flock lifecycle, placement age, mortality anomalies, and harvest schedules.',
            actions: [
              AppButton(
                label: 'Add New Batch',
                icon: Icons.add_rounded,
                size: AppButtonSize.small,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BatchFormScreen(
                        farmId: widget.farmId,
                      ),
                    ),
                  );
                  if (mounted) {
                    ref.invalidate(batchListProvider(widget.farmId));
                  }
                },
              ),
            ],
          ),

          // 2. Filter & Search Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppDesign.cardDecorationFlat,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 18, color: AppColors.slate400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: const TextStyle(fontSize: 13, color: AppColors.slate800),
                            decoration: const InputDecoration(
                              hintText: 'Search batch name, breed, or strain...',
                              hintStyle: TextStyle(fontSize: 13, color: AppColors.slate400),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Wrap(
                  spacing: 6,
                  children: ['All', 'Active', 'Completed'].map((status) {
                    final isSelected = _selectedStatus == status;
                    return ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.slate700,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedStatus = status),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Batches Data Table
          Builder(
            builder: (context) {
              final rawBatches = batchesAsync.value ?? BatchService.inMemoryBatches;
              final fallbackBatches = BatchService.inMemoryBatches.where((b) => b.farmId == widget.farmId || widget.farmId.isEmpty).toList();
              final batches = rawBatches.isNotEmpty ? rawBatches : (fallbackBatches.isNotEmpty ? fallbackBatches : BatchService.inMemoryBatches);

              final filtered = batches.where((b) {
                final matchesSearch = b.batchName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    b.breed.toLowerCase().contains(_searchQuery.toLowerCase());
                if (!matchesSearch) return false;
                if (_selectedStatus == 'Active') return b.status == 'active';
                if (_selectedStatus == 'Completed') return b.status != 'active';
                return true;
              }).toList();

              return ResponsiveDataTable(
                emptyMessage: 'No batches registered for this facility yet',
                columns: const [
                  ResponsiveDataColumn(label: 'Batch Name', flex: 3),
                  ResponsiveDataColumn(label: 'Breed & Strain', flex: 2),
                  ResponsiveDataColumn(label: 'Placement Date', flex: 2),
                  ResponsiveDataColumn(label: 'Flock Age', flex: 1),
                  ResponsiveDataColumn(label: 'Current Live Birds', flex: 2),
                  ResponsiveDataColumn(label: 'Status', flex: 2),
                  ResponsiveDataColumn(label: 'Actions', flex: 1, align: TextAlign.right),
                ],
                rows: filtered.map((batch) {
                  final ageDays = DateTime.now().difference(batch.placementDate).inDays;
                  return ResponsiveDataRow(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BatchCommandCenterScreen(
                            farmId: widget.farmId,
                            batchId: batch.id,
                            batchName: batch.batchName,
                          ),
                        ),
                      );
                    },
                    cells: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.infoBg,
                              borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                            ),
                            child: const Icon(Icons.grid_view_outlined, size: 16, color: AppColors.info),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              batch.batchName,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900),
                            ),
                          ),
                        ],
                      ),
                      Text(batch.breed, style: const TextStyle(color: AppColors.slate700)),
                      Text(DateFormat('dd MMM yyyy').format(batch.placementDate)),
                      Text('$ageDays d', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${NumberFormat("#,###").format(batch.currentBirdCount)} / ${NumberFormat("#,###").format(batch.initialChicksCount)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      StatusBadge.fromStatus(batch.status),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        tooltip: 'Open Batch Console',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BatchCommandCenterScreen(
                                farmId: widget.farmId,
                                batchId: batch.id,
                                batchName: batch.batchName,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
