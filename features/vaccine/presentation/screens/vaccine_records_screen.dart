import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/responsive_data_table.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/vaccine/presentation/screens/vaccine_form_screen.dart';

class VaccineRecordsScreen extends StatefulWidget {
  const VaccineRecordsScreen({super.key});

  @override
  State<VaccineRecordsScreen> createState() => _VaccineRecordsScreenState();
}

class _VaccineRecordsScreenState extends State<VaccineRecordsScreen>
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
          // 1. Web Page Header
          WebPageHeader(
            title: 'Immunization & Vaccination Management',
            subtitle: 'Schedule and verify viral and bacterial immunizations across all registered flocks.',
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
                    Tab(text: 'Upcoming Doses'),
                    Tab(text: 'Completed Immunizations'),
                    Tab(text: 'Overdue Doses'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'Schedule Vaccination',
                icon: Icons.add_rounded,
                size: AppButtonSize.small,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VaccineFormScreen(
                        farmId: 'farm_01',
                        batchId: 'flock_01',
                        currentBatchAge: 28,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // 2. Tab Contents
          SizedBox(
            height: 600,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingTable(),
                _buildCompletedTable(),
                _buildOverdueTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTable() {
    return ResponsiveDataTable(
      columns: const [
        ResponsiveDataColumn(label: 'Vaccine / Target Disease', flex: 3),
        ResponsiveDataColumn(label: 'Farm Facility', flex: 2),
        ResponsiveDataColumn(label: 'Flock Batch', flex: 2),
        ResponsiveDataColumn(label: 'Scheduled Due Date', flex: 2),
        ResponsiveDataColumn(label: 'Admin Route', flex: 2),
        ResponsiveDataColumn(label: 'Status', flex: 2),
        ResponsiveDataColumn(label: 'Action', flex: 1, align: TextAlign.right),
      ],
      rows: [
        ResponsiveDataRow(
          cells: [
            const Text('Newcastle Disease (LaSota Booster)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900)),
            const Text('Primary Farm (Nashik)'),
            const Text('Batch B07 (Day 28)'),
            Text(DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 1)))),
            const Text('Drinking Water / Oral'),
            StatusBadge.fromStatus('Pending'),
            AppButton(
              label: 'Mark Done',
              size: AppButtonSize.small,
              variant: AppButtonVariant.outlined,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vaccination recorded as completed!')),
                );
              },
            ),
          ],
        ),
        ResponsiveDataRow(
          cells: [
            const Text('Infectious Coryza Inactivated', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900)),
            const Text('Sunrise Farm (Pune)'),
            const Text('Batch B08 (Day 32)'),
            Text(DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 4)))),
            const Text('Intramuscular Injection'),
            StatusBadge.fromStatus('Scheduled'),
            AppButton(
              label: 'Mark Done',
              size: AppButtonSize.small,
              variant: AppButtonVariant.outlined,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vaccine dose marked as completed and logged in health register.'),
                    backgroundColor: AppColors.healthy,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletedTable() {
    return ResponsiveDataTable(
      columns: const [
        ResponsiveDataColumn(label: 'Vaccine Name', flex: 3),
        ResponsiveDataColumn(label: 'Facility & Flock', flex: 2),
        ResponsiveDataColumn(label: 'Date Administered', flex: 2),
        ResponsiveDataColumn(label: 'Batch # / Manufacturer', flex: 3),
        ResponsiveDataColumn(label: 'Flock Coverage', flex: 2),
        ResponsiveDataColumn(label: 'Status', flex: 2),
      ],
      rows: [
        ResponsiveDataRow(
          cells: [
            const Text('Marek’s Disease (HVT)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900)),
            const Text('Green Valley • B07'),
            const Text('28 Jul 2026 (Day 1)'),
            const Text('HVT-9281 / Hester Biosciences'),
            const Text('100% (5,000 doses)'),
            StatusBadge.fromStatus('Completed'),
          ],
        ),
        ResponsiveDataRow(
          cells: [
            const Text('Newcastle Disease (ND-B1)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900)),
            const Text('Green Valley • B07'),
            const Text('04 Aug 2026 (Day 7)'),
            const Text('ND-8172 / Indovax Pvt Ltd'),
            const Text('99.2% (4,960 doses)'),
            StatusBadge.fromStatus('Completed'),
          ],
        ),
        ResponsiveDataRow(
          cells: [
            const Text('Infectious Bursal Disease (IBD)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900)),
            const Text('Green Valley • B07'),
            const Text('11 Aug 2026 (Day 14)'),
            const Text('IBD-4410 / Hester Biosciences'),
            const Text('99.0% (4,950 doses)'),
            StatusBadge.fromStatus('Completed'),
          ],
        ),
      ],
    );
  }

  Widget _buildOverdueTable() {
    return ResponsiveDataTable(
      emptyMessage: 'No overdue immunizations. All active flocks are fully protected.',
      columns: const [
        ResponsiveDataColumn(label: 'Vaccine Name', flex: 3),
        ResponsiveDataColumn(label: 'Facility / Flock', flex: 2),
        ResponsiveDataColumn(label: 'Original Due Date', flex: 2),
        ResponsiveDataColumn(label: 'Days Overdue', flex: 2),
        ResponsiveDataColumn(label: 'Severity Risk', flex: 2),
        ResponsiveDataColumn(label: 'Action', flex: 2, align: TextAlign.right),
      ],
      rows: const [],
    );
  }
}
