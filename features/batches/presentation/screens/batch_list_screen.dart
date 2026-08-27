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

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(batchListProvider(widget.farmId));

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Web Page Header
          WebPageHeader(
            title: widget.farmName != null ? '${widget.farmName} — Flocks & Batches' : 'Flocks & Batches',
            subtitle: 'Track flock lifecycle, placement age, mortality anomalies, and harvest schedules.',
            actions: [
              AppButton(
                label: 'Add New Batch',
                icon: Icons.add_rounded,
                size: AppButtonSize.small,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BatchFormScreen(
                        farmId: widget.farmId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // 2. Batches Data Table
          batchesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, _) => AppEmptyState(
              title: 'Unable to load batches',
              message: '$e',
              buttonLabel: 'Retry',
              onButtonPressed: () => ref.invalidate(batchListProvider(widget.farmId)),
            ),
            data: (batches) {
              final filtered = batches.where((b) {
                return b.batchName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    b.breed.toLowerCase().contains(_searchQuery.toLowerCase());
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
                      Text('${NumberFormat("#,###").format(batch.currentBirdCount)} / ${NumberFormat("#,###").format(batch.initialChicksCount)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      StatusBadge.fromStatus(batch.status),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
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
