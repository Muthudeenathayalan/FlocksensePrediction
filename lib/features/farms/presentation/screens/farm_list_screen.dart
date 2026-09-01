import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/core/widgets/app_empty_state.dart';
import 'package:flock_sense/core/widgets/app_loading_indicator.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/responsive_data_table.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_command_center_screen.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_setup_screen.dart';

class FarmListScreen extends ConsumerStatefulWidget {
  const FarmListScreen({super.key});

  @override
  ConsumerState<FarmListScreen> createState() => _FarmListScreenState();
}

class _FarmListScreenState extends ConsumerState<FarmListScreen> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  Future<void> _deleteFarm(BuildContext context, FarmModel farm) async {
    final ok = await AppDialog.confirm(
      context: context,
      title: 'Delete Facility',
      message: 'Are you sure you want to delete ${farm.farmName}? All linked batch records and telemetry will be archived.',
      confirmLabel: 'Delete Farm',
      isDanger: true,
    );
    if (!ok) return;

    try {
      await FarmService.deleteFarm(farm.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Farm deleted successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmsAsync = ref.watch(farmListProvider);

    return farmsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => AppEmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Unable to load facilities',
        message: 'Check your connection or verify database permissions.',
        buttonLabel: 'Retry',
        onButtonPressed: () => ref.invalidate(farmListProvider),
      ),
      data: (farms) {
        var filteredFarms = farms.where((f) {
          final matchesSearch = f.farmName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              f.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (f.district?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
          if (!matchesSearch) return false;
          if (_selectedStatusFilter == 'Active') return f.status == 'active';
          if (_selectedStatusFilter == 'Inactive') return f.status != 'active';
          return true;
        }).toList();

        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Web Page Header
              WebPageHeader(
                title: 'My Farms & Facilities',
                subtitle: 'Manage multi-shed poultry installations, bio-security compliance, and active flock units.',
                actions: [
                  AppButton(
                    label: 'Register New Farm',
                    icon: Icons.add_rounded,
                    size: AppButtonSize.small,
                    onPressed: () async {
                      final result = await Navigator.pushNamed(context, AppRoutes.farmSetup);
                      if (result != null && mounted) {
                        ref.invalidate(farmListProvider);
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
                    // Search Input
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, size: 16, color: AppColors.slate400),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (val) => setState(() => _searchQuery = val),
                                decoration: const InputDecoration(
                                  hintText: 'Search farm name, district, address...',
                                  hintStyle: TextStyle(fontSize: 12.5, color: AppColors.slate400),
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Status Filter
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatusFilter,
                          isDense: true,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.slate800, fontWeight: FontWeight.w600),
                          onChanged: (val) => setState(() => _selectedStatusFilter = val ?? 'All'),
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All Facilities')),
                            DropdownMenuItem(value: 'Active', child: Text('Active Only')),
                            DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Desktop SaaS Table of Farms
              ResponsiveDataTable(
                emptyMessage: 'No registered poultry farms found',
                columns: const [
                  ResponsiveDataColumn(label: 'Farm Name', flex: 3),
                  ResponsiveDataColumn(label: 'Location', flex: 2),
                  ResponsiveDataColumn(label: 'Type / Sheds', flex: 2),
                  ResponsiveDataColumn(label: 'Bird Capacity', flex: 2),
                  ResponsiveDataColumn(label: 'Health Index', flex: 2),
                  ResponsiveDataColumn(label: 'Status', flex: 2),
                  ResponsiveDataColumn(label: 'Actions', flex: 2, align: TextAlign.right),
                ],
                rows: filteredFarms.map((farm) {
                  final locationStr = farm.district != null && farm.district!.isNotEmpty
                      ? '${farm.district}, ${farm.state ?? "Maharashtra"}'
                      : farm.address;

                  return ResponsiveDataRow(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FarmCommandCenterScreen(farm: farm),
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
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                            ),
                            child: const Icon(Icons.storefront_outlined, size: 16, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  farm.farmName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900, fontSize: 13.5),
                                ),
                                Text('ID: ${farm.id.substring(0, farm.id.length > 8 ? 8 : farm.id.length)}', style: AppTypography.metadata),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(locationStr, style: const TextStyle(color: AppColors.slate700, fontSize: 13)),
                      Text('${farm.farmType} • ${farm.totalSheds} Sheds', style: const TextStyle(color: AppColors.slate700, fontSize: 13)),
                      Text('${farm.capacity.toString()} birds', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      StatusBadge.fromStatus('Healthy'),
                      StatusBadge.fromStatus(farm.status),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppButton(
                            label: 'Console',
                            size: AppButtonSize.small,
                            variant: AppButtonVariant.outlined,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FarmCommandCenterScreen(farm: farm),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.slate600),
                            tooltip: 'Edit Facility',
                            onPressed: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FarmSetupScreen(initialFarm: farm),
                                ),
                              );
                              if (updated != null && mounted) {
                                ref.invalidate(farmListProvider);
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                            tooltip: 'Delete Farm',
                            onPressed: () => _deleteFarm(context, farm),
                          ),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
