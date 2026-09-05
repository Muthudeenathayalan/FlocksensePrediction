import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/models/sync_status.dart';
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
import 'package:flock_sense/core/widgets/sync_status_banner.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/sheds/data/shed_service.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';
import 'package:flock_sense/features/sheds/presentation/providers/shed_providers.dart';
import 'package:flock_sense/features/sheds/presentation/screens/shed_form_screen.dart';

class ShedListScreen extends ConsumerWidget {
  const ShedListScreen({super.key, required this.farm});
  final FarmModel farm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shedsAsync = ref.watch(shedListProvider(farm.id));
    final syncStatus = ref
        .watch(shedSyncStatusProvider(farm.id))
        .maybeWhen(data: (s) => s, orElse: () => SyncStatus.synced);

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: canPop
          ? AppBar(
              title: Text('Sheds — ${farm.farmName}',
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
            SyncStatusBanner(syncStatus: syncStatus),

            // 1. Unified Web Header
            WebPageHeader(
              title: 'Shed Infrastructure — ${farm.farmName}',
              subtitle:
                  'Manage poultry house units, ventilation layout, dimensions, and bird capacity.',
              breadcrumb: 'Farms / ${farm.farmName} / Sheds',
              actions: [
                AppButton(
                  label: 'Add New Shed',
                  icon: Icons.add_rounded,
                  size: AppButtonSize.small,
                  onPressed: () => _openForm(context, farm.id),
                ),
              ],
            ),

            // 2. Main Content
            shedsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: AppLoadingIndicator(),
              ),
              error: (e, _) => AppEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load sheds',
                message: '$e',
                buttonLabel: 'Retry',
                onButtonPressed: () =>
                    ref.invalidate(shedListProvider(farm.id)),
              ),
              data: (sheds) {
                if (sheds.isEmpty) {
                  return AppCard(
                    padding: const EdgeInsets.all(48),
                    child: AppEmptyState(
                      icon: Icons.home_work_outlined,
                      title: 'No sheds configured yet',
                      message:
                          'Add your first poultry shed to start tracking batches, density, and flock placement.',
                      buttonLabel: 'Add First Shed',
                      onButtonPressed: () => _openForm(context, farm.id),
                    ),
                  );
                }

                // Calculate summary KPIs
                final totalCapacity =
                    sheds.fold<int>(0, (sum, s) => sum + s.physicalCapacity);
                final totalArea =
                    sheds.fold<double>(0.0, (sum, s) => sum + s.areaSqFt);

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
                              title: 'Total Shed Units',
                              value: sheds.length.toString(),
                              subtitle: '${farm.farmName} facility',
                              icon: Icons.home_work_rounded,
                              accentColor: AppColors.primary,
                            ),
                            MetricCard(
                              title: 'Total Bird Capacity',
                              value: totalCapacity > 0
                                  ? totalCapacity.toString()
                                  : 'Dynamic',
                              subtitle: 'Maximum stocking capacity',
                              icon: Icons.pets_rounded,
                              accentColor: AppColors.emerald,
                            ),
                            MetricCard(
                              title: 'Total Floor Space',
                              value:
                                  '${totalArea.toStringAsFixed(0)} sq.ft',
                              subtitle: 'Calculated covered area',
                              icon: Icons.square_foot_rounded,
                              accentColor: AppColors.primaryDark,
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),
                    AppDesign.sectionTitle('Configured Shed Units (${sheds.length})'),

                    // Shed Cards List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sheds.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _ShedCard(
                        shed: sheds[i],
                        farmId: farm.id,
                        onEdit: () =>
                            _openForm(context, farm.id, shed: sheds[i]),
                        onDelete: () => _delete(context, farm.id, sheds[i]),
                      ),
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

  void _openForm(BuildContext ctx, String farmId, {ShedModel? shed}) {
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => ShedFormScreen(farmId: farmId, existing: shed),
      ),
    );
  }

  Future<void> _delete(BuildContext ctx, String farmId, ShedModel shed) async {
    final ok = await AppDialog.confirm(
      context: ctx,
      title: 'Delete Shed',
      message: 'Delete "${shed.shedName}"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDanger: true,
    );
    if (ok && ctx.mounted) {
      try {
        await ShedService.deleteShed(farmId, shed.id);
      } catch (e) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx)
              .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }
}

class _ShedCard extends StatelessWidget {
  const _ShedCard({
    required this.shed,
    required this.farmId,
    required this.onEdit,
    required this.onDelete,
  });
  final ShedModel shed;
  final String farmId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        shed.status == 'active' ? AppColors.emerald : AppColors.slate500;

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
            child: const Icon(Icons.home_work_rounded,
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
                      shed.shedName,
                      style: AppTypography.cardTitle,
                    ),
                    const SizedBox(width: 10),
                    AppDesign.statusChip(
                      shed.status.toUpperCase(),
                      statusColor.withValues(alpha: 0.12),
                      textColor: statusColor,
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
                        const Icon(Icons.pets_outlined,
                            size: 14, color: AppColors.slate400),
                        const SizedBox(width: 4),
                        Text(
                          'Capacity: ${shed.physicalCapacity > 0 ? shed.physicalCapacity : "Not specified"} birds',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.square_foot_outlined,
                            size: 14, color: AppColors.slate400),
                        const SizedBox(width: 4),
                        Text(
                          'Floor Space: ${shed.lengthFt} × ${shed.widthFt} ft (${shed.areaSqFt.toStringAsFixed(0)} sq.ft)',
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
            tooltip: 'Delete Shed',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
