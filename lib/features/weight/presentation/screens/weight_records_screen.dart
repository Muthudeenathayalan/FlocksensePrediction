import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/core/widgets/app_empty_state.dart';
import 'package:flock_sense/core/widgets/app_loading_indicator.dart';
import 'package:flock_sense/core/widgets/metric_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/weight/data/weight_record_service.dart';
import 'package:flock_sense/features/weight/domain/weight_record_model.dart';
import 'package:flock_sense/features/weight/presentation/screens/weight_record_form_screen.dart';

class WeightRecordsScreen extends StatefulWidget {
  const WeightRecordsScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    required this.batchName,
  });

  final String farmId;
  final String batchId;
  final String batchName;

  @override
  State<WeightRecordsScreen> createState() => _WeightRecordsScreenState();
}

class _WeightRecordsScreenState extends State<WeightRecordsScreen> {
  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: canPop
          ? AppBar(
              title: Text('Weight Records • ${widget.batchName}',
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
            // 1. Web Header
            WebPageHeader(
              title: '${widget.batchName} — Weight Records & Sampling',
              subtitle:
                  'Track average body mass velocity, sample distributions, and uniformity index against standard growth curves.',
              breadcrumb: 'Batches / ${widget.batchName} / Weight Sampling',
              actions: [
                AppButton(
                  label: 'Add Weight Sample',
                  icon: Icons.add_rounded,
                  size: AppButtonSize.small,
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WeightRecordFormScreen(
                          farmId: widget.farmId,
                          batchId: widget.batchId,
                        ),
                      ),
                    );
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
                ),
              ],
            ),

            // 2. Stream Data
            StreamBuilder<List<WeightRecordModel>>(
              stream: WeightRecordService.watchWeightRecords(
                farmId: widget.farmId,
                batchId: widget.batchId,
              ),
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
                      title: 'Error Loading Weight Samples',
                      message: '${snapshot.error}',
                    ),
                  );
                }

                final records = snapshot.data ?? [];

                if (records.isEmpty) {
                  return AppCard(
                    padding: const EdgeInsets.all(48),
                    child: AppEmptyState(
                      icon: Icons.scale_outlined,
                      title: 'No sample weights recorded yet',
                      message: 'Record the first batch weight sampling to measure growth velocity and flock uniformity.',
                      buttonLabel: 'Record First Sample',
                      onButtonPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WeightRecordFormScreen(
                              farmId: widget.farmId,
                              batchId: widget.batchId,
                            ),
                          ),
                        );
                        if (result == true && mounted) {
                          setState(() {});
                        }
                      },
                    ),
                  );
                }

                // KPIs
                final latestRecord = records.first;
                final totalSamples = records.fold<int>(
                  0,
                  (sum, r) => sum + (r.sampleCount ?? 0),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Summary Row
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
                              title: 'Latest Avg Weight',
                              value: '${latestRecord.averageWeight.toStringAsFixed(0)} ${latestRecord.unit == "kilograms" ? "kg" : "g"}',
                              subtitle: DateFormat('dd MMM yyyy').format(latestRecord.recordDate),
                              icon: Icons.scale_rounded,
                              accentColor: AppColors.primary,
                            ),
                            MetricCard(
                              title: 'Flock Uniformity',
                              value: '86.4%',
                              subtitle: 'Target: > 85% uniformity',
                              icon: Icons.auto_graph_rounded,
                              accentColor: AppColors.emerald,
                            ),
                            MetricCard(
                              title: 'Total Sampled Birds',
                              value: totalSamples > 0 ? totalSamples.toString() : '${records.length} samples',
                              subtitle: 'Across ${records.length} sampling sessions',
                              icon: Icons.pets_rounded,
                              accentColor: AppColors.indigo,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    AppDesign.sectionTitle('Recorded Weight Samples (${records.length})'),

                    // Weight Record Cards
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return _WeightCard(
                          record: record,
                          onEdit: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WeightRecordFormScreen(
                                  farmId: widget.farmId,
                                  batchId: widget.batchId,
                                  existingRecord: record,
                                ),
                              ),
                            );
                            if (result == true && mounted) {
                              setState(() {});
                            }
                          },
                          onDelete: () async {
                            final ok = await AppDialog.confirm(
                              context: context,
                              title: 'Delete Weight Record',
                              message: 'Delete sample record for ${DateFormat("dd MMM").format(record.recordDate)}? This cannot be undone.',
                              confirmLabel: 'Delete',
                              isDanger: true,
                            );
                            if (ok == true && mounted) {
                              try {
                                await WeightRecordService.deleteWeightRecord(
                                  farmId: widget.farmId,
                                  batchId: widget.batchId,
                                  recordDate: record.recordDate,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Weight record deleted'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Delete failed: $e')),
                                  );
                                }
                              }
                            }
                          },
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

class _WeightCard extends StatelessWidget {
  const _WeightCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final WeightRecordModel record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppDesign.radiusMd),
            ),
            child: const Icon(Icons.scale_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Sample • ${DateFormat("dd MMM yyyy").format(record.recordDate)}',
                      style: AppTypography.cardTitle,
                    ),
                    if (record.sampleCount != null) ...[
                      const SizedBox(width: 8),
                      AppDesign.statusChip(
                        '${record.sampleCount} BIRDS SAMPLED',
                        AppColors.slate100,
                        textColor: AppColors.slate700,
                      ),
                    ],
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
                        const Icon(Icons.fitness_center_rounded,
                            size: 13, color: AppColors.slate400),
                        const SizedBox(width: 4),
                        Text(
                          '${record.averageWeight.toStringAsFixed(1)} ${record.unit}',
                          style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (record.notes != null && record.notes!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notes_rounded,
                              size: 13, color: AppColors.slate400),
                          const SizedBox(width: 4),
                          Text(
                            record.notes!,
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          AppButton(
            label: 'Edit',
            icon: Icons.edit_outlined,
            variant: AppButtonVariant.outlined,
            size: AppButtonSize.small,
            onPressed: onEdit,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger, size: 20),
            tooltip: 'Delete Sample',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
