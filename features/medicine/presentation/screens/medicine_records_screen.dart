import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/responsive_data_table.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/medicine/data/medicine_service.dart';
import 'package:flock_sense/features/medicine/domain/medicine_record_model.dart';
import 'package:flock_sense/features/medicine/presentation/screens/medicine_form_screen.dart';

class MedicineRecordsScreen extends StatefulWidget {
  const MedicineRecordsScreen({
    super.key,
    this.farmId,
    this.batchId,
    this.batchName,
  });

  final String? farmId;
  final String? batchId;
  final String? batchName;

  @override
  State<MedicineRecordsScreen> createState() => _MedicineRecordsScreenState();
}

class _MedicineRecordsScreenState extends State<MedicineRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          WebPageHeader(
            title: widget.batchName != null
                ? 'Treatments & Prescriptions • ${widget.batchName}'
                : 'Veterinary Treatments & Prescriptions',
            subtitle: 'Track prescribed antibiotics, supportive vitamins, withdrawal periods, and veterinary sign-offs.',
            actions: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Active Courses'),
                    Tab(text: 'Completed Courses'),
                    Tab(text: 'Medicine Inventory & Withdrawal Log'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'Log New Prescription',
                icon: Icons.add_rounded,
                size: AppButtonSize.small,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MedicineFormScreen(
                        farmId: widget.farmId ?? 'farm_01',
                        batchId: widget.batchId ?? 'flock_01',
                        currentBatchAge: 28,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // 2. Tab Views
          SizedBox(
            height: 600,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveTreatmentsTable(),
                _buildCompletedTreatmentsTable(),
                _buildWithdrawalTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTreatmentsTable() {
    return ResponsiveDataTable(
      columns: const [
        ResponsiveDataColumn(label: 'Medication / Treatment', flex: 3),
        ResponsiveDataColumn(label: 'Facility & Flock', flex: 2),
        ResponsiveDataColumn(label: 'Dosage / Water Dilution', flex: 3),
        ResponsiveDataColumn(label: 'Start Date & Duration', flex: 2),
        ResponsiveDataColumn(label: 'Prescribing Vet', flex: 2),
        ResponsiveDataColumn(label: 'Status', flex: 2),
        ResponsiveDataColumn(label: 'Action', flex: 1, align: TextAlign.right),
      ],
      rows: [
        ResponsiveDataRow(
          cells: [
            const Text('Electrolyte + Vitamin C Solution', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900)),
            const Text('Green Valley • B07'),
            const Text('1.0 g / Litre (Morning Water)'),
            const Text('22 Aug (3 Days course)'),
            const Text('Dr. V. Sharma (VAS)'),
            StatusBadge.fromStatus('Active'),
            AppButton(
              label: 'Complete',
              size: AppButtonSize.small,
              variant: AppButtonVariant.outlined,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Treatment marked as completed.')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedTreatmentsTable() {
    return ResponsiveDataTable(
      columns: const [
        ResponsiveDataColumn(label: 'Medication', flex: 3),
        ResponsiveDataColumn(label: 'Facility / Flock', flex: 2),
        ResponsiveDataColumn(label: 'Indication / Reason', flex: 3),
        ResponsiveDataColumn(label: 'Completed On', flex: 2),
        ResponsiveDataColumn(label: 'Outcome', flex: 2),
        ResponsiveDataColumn(label: 'Status', flex: 2),
      ],
      rows: [
        ResponsiveDataRow(
          cells: [
            const Text('Probiotic + Yeast Extract Booster', style: TextStyle(fontWeight: FontWeight.w600)),
            const Text('Green Valley • B07'),
            const Text('Gut health & Post-vaccine recovery'),
            const Text('15 Aug 2026'),
            const Text('Full Recovery (100%)'),
            StatusBadge.fromStatus('Completed'),
          ],
        ),
      ],
    );
  }

  Widget _buildWithdrawalTable() {
    return ResponsiveDataTable(
      emptyMessage: 'All current active flocks are cleared with zero active medication withdrawal restrictions.',
      columns: const [
        ResponsiveDataColumn(label: 'Medicine', flex: 3),
        ResponsiveDataColumn(label: 'Flock', flex: 2),
        ResponsiveDataColumn(label: 'Withdrawal Period (Days)', flex: 2),
        ResponsiveDataColumn(label: 'Earliest Harvest Date', flex: 2),
        ResponsiveDataColumn(label: 'Clearance Status', flex: 2),
      ],
      rows: const [],
    );
  }
}
