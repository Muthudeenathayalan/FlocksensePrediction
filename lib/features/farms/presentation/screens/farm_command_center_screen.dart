import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/responsive_data_table.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_command_center_screen.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_form_screen.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

class FarmCommandCenterScreen extends StatefulWidget {
  const FarmCommandCenterScreen({
    super.key,
    required this.farm,
  });

  final FarmModel farm;

  @override
  State<FarmCommandCenterScreen> createState() => _FarmCommandCenterScreenState();
}

class _FarmCommandCenterScreenState extends State<FarmCommandCenterScreen>
    with SingleTickerProviderStateMixin {
  late FarmModel _farm;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _farm = widget.farm;
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = _farm.district != null && _farm.district!.isNotEmpty
        ? '${_farm.district}, ${_farm.state ?? "Maharashtra"}'
        : _farm.address;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_farm.farmName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        elevation: 0,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Facility Header Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppDesign.cardDecoration,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                        ),
                        child: const Icon(Icons.storefront_outlined, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _farm.farmName,
                                  style: AppTypography.pageTitle.copyWith(fontSize: 22),
                                ),
                                const SizedBox(width: 12),
                                StatusBadge.fromStatus(_farm.status),
                                const SizedBox(width: 8),
                                StatusBadge.fromStatus('Biosecurity: Verified'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$location • ${_farm.farmType} • Capacity: ${NumberFormat("#,###").format(_farm.capacity)} birds • ${_farm.totalSheds} Sheds',
                              style: AppTypography.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          AppButton(
                            label: 'Log Daily Record',
                            icon: Icons.edit_note_rounded,
                            size: AppButtonSize.small,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DailyRecordsDashboardScreen(
                                    initialFarmId: _farm.id,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          AppButton(
                            label: 'Add Flock Batch',
                            icon: Icons.add_rounded,
                            variant: AppButtonVariant.outlined,
                            size: AppButtonSize.small,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BatchFormScreen(
                                    farmId: _farm.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.divider),

                  // 2. Navigation Tabs
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Facility Overview'),
                      Tab(text: 'Active Flocks'),
                      Tab(text: 'Daily Operations'),
                      Tab(text: 'Health & Biosecurity'),
                      Tab(text: 'Vaccination Schedules'),
                      Tab(text: 'Medical Treatments'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Tab Contents
            SizedBox(
              height: 600,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildFlocksTab(),
                  _buildDailyRecordsTab(),
                  _buildHealthTab(),
                  _buildVaccinationsTab(),
                  _buildTreatmentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Specs
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: AppDesign.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Facility Specifications', style: AppTypography.cardTitle),
                    const SizedBox(height: 14),
                    AppDesign.infoRow('Farm ID', _farm.id),
                    AppDesign.infoRow('Owner/Operator', _farm.ownerName ?? 'Primary Operator'),
                    AppDesign.infoRow('Contact Phone', _farm.ownerPhone ?? '+91 98765 43210'),
                    AppDesign.infoRow('Registered Sheds', '${_farm.totalSheds} Active Units'),
                    AppDesign.infoRow('Max Capacity', '${_farm.capacity} birds'),
                    AppDesign.infoRow('Bio-Security Level', 'Tier-1 Certified'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Shed Environment & Equipment
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: AppDesign.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Shed Infrastructure & Equipment', style: AppTypography.cardTitle),
                    const SizedBox(height: 14),
                    AppDesign.infoRow('Ventilation System', 'Tunnel Ventilation with Cooling Pads'),
                    AppDesign.infoRow('Feeding Line', 'Automated Pan Feeder System'),
                    AppDesign.infoRow('Water Source', 'Deep Borewell with In-line Chlorination'),
                    AppDesign.infoRow('Backup Power', '62.5 kVA Kirloskar Diesel Generator'),
                    AppDesign.infoRow('Disinfection Gate', 'Automated Wheel Sprayer Active'),
                    AppDesign.infoRow('CCTV Surveillance', '8 Camera NVR Online'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlocksTab() {
    return StreamBuilder<List<BatchModel>>(
      stream: BatchService.watchBatches(_farm.id),
      builder: (context, snapshot) {
        final batches = snapshot.data ?? [];
        return ResponsiveDataTable(
          emptyMessage: 'No active batches currently in this facility',
          columns: const [
            ResponsiveDataColumn(label: 'Batch Name', flex: 3),
            ResponsiveDataColumn(label: 'Breed', flex: 2),
            ResponsiveDataColumn(label: 'Placement Date', flex: 2),
            ResponsiveDataColumn(label: 'Initial Birds', flex: 2),
            ResponsiveDataColumn(label: 'Current Live', flex: 2),
            ResponsiveDataColumn(label: 'Status', flex: 2),
            ResponsiveDataColumn(label: 'Actions', flex: 1, align: TextAlign.right),
          ],
          rows: batches.map((b) {
            return ResponsiveDataRow(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BatchCommandCenterScreen(
                      farmId: _farm.id,
                      batchId: b.id,
                      batchName: b.batchName,
                    ),
                  ),
                );
              },
              cells: [
                Text(b.batchName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900)),
                Text(b.breed),
                Text(DateFormat('dd MMM yyyy').format(b.placementDate)),
                Text(b.initialChicksCount.toString()),
                Text(b.currentBirdCount.toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                StatusBadge.fromStatus(b.status),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.slate400),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDailyRecordsTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDesign.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Operational Logs', style: AppTypography.cardTitle),
              AppButton(
                label: 'Add Today\'s Entry',
                size: AppButtonSize.small,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DailyRecordsDashboardScreen(initialFarmId: _farm.id),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ResponsiveDataTable(
              columns: const [
                ResponsiveDataColumn(label: 'Date', flex: 2),
                ResponsiveDataColumn(label: 'Flock', flex: 2),
                ResponsiveDataColumn(label: 'Mortality', flex: 2),
                ResponsiveDataColumn(label: 'Feed (kg)', flex: 2),
                ResponsiveDataColumn(label: 'Water (L)', flex: 2),
                ResponsiveDataColumn(label: 'Status', flex: 2),
              ],
              rows: [
                ResponsiveDataRow(
                  cells: [
                    Text(DateFormat('dd MMM yyyy').format(DateTime.now())),
                    const Text('Batch B07'),
                    const Text('3 birds', style: TextStyle(color: AppColors.slate800)),
                    const Text('480 kg'),
                    const Text('860 L'),
                    StatusBadge.fromStatus('Normal'),
                  ],
                ),
                ResponsiveDataRow(
                  cells: [
                    Text(DateFormat('dd MMM yyyy').format(DateTime.now().subtract(const Duration(days: 1)))),
                    const Text('Batch B07'),
                    const Text('4 birds', style: TextStyle(color: AppColors.slate800)),
                    const Text('475 kg'),
                    const Text('850 L'),
                    StatusBadge.fromStatus('Normal'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDesign.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Health & Biosecurity Incidents', style: AppTypography.cardTitle),
          const SizedBox(height: 12),
          ResponsiveDataTable(
            columns: const [
              ResponsiveDataColumn(label: 'Case ID', flex: 2),
              ResponsiveDataColumn(label: 'Flock Affected', flex: 2),
              ResponsiveDataColumn(label: 'Suspected Symptoms', flex: 3),
              ResponsiveDataColumn(label: 'Risk Level', flex: 2),
              ResponsiveDataColumn(label: 'Status', flex: 2),
            ],
            rows: [
              ResponsiveDataRow(
                cells: [
                  const Text('HC-2026-081', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Text('Batch B07'),
                  const Text('Mild Sneezing & Feed Reduction'),
                  StatusBadge.fromStatus('Warning'),
                  StatusBadge.fromStatus('Under Vet Review'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationsTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDesign.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Immunization & Vaccination Schedule', style: AppTypography.cardTitle),
          const SizedBox(height: 12),
          ResponsiveDataTable(
            columns: const [
              ResponsiveDataColumn(label: 'Vaccine Name', flex: 3),
              ResponsiveDataColumn(label: 'Flock', flex: 2),
              ResponsiveDataColumn(label: 'Target Day', flex: 2),
              ResponsiveDataColumn(label: 'Admin Route', flex: 2),
              ResponsiveDataColumn(label: 'Status', flex: 2),
            ],
            rows: [
              ResponsiveDataRow(
                cells: [
                  const Text('Marek’s Disease (HVT)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Text('Batch B07'),
                  const Text('Day 1 (Hatchery)'),
                  const Text('Subcutaneous'),
                  StatusBadge.fromStatus('Completed'),
                ],
              ),
              ResponsiveDataRow(
                cells: [
                  const Text('Newcastle Disease (LaSota)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Text('Batch B07'),
                  const Text('Day 7'),
                  const Text('Drinking Water'),
                  StatusBadge.fromStatus('Completed'),
                ],
              ),
              ResponsiveDataRow(
                cells: [
                  const Text('Infectious Bursal Disease (IBD Gumboro)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Text('Batch B07'),
                  const Text('Day 14'),
                  const Text('Drinking Water'),
                  StatusBadge.fromStatus('Completed'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentsTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDesign.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prescribed Veterinary Medications', style: AppTypography.cardTitle),
          const SizedBox(height: 12),
          ResponsiveDataTable(
            columns: const [
              ResponsiveDataColumn(label: 'Medication', flex: 3),
              ResponsiveDataColumn(label: 'Flock', flex: 2),
              ResponsiveDataColumn(label: 'Dosage / Duration', flex: 3),
              ResponsiveDataColumn(label: 'Prescribing Vet', flex: 2),
              ResponsiveDataColumn(label: 'Status', flex: 2),
            ],
            rows: [
              ResponsiveDataRow(
                cells: [
                  const Text('Electrolyte & Vit C Solution', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Text('Batch B07'),
                  const Text('1g/L for 3 days (Heat Stress)'),
                  const Text('Dr. V. Sharma (VAS)'),
                  StatusBadge.fromStatus('Active'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
