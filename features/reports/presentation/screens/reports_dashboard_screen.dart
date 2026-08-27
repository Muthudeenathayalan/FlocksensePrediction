import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/responsive_data_table.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';

class ReportsDashboardScreen extends ConsumerStatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  ConsumerState<ReportsDashboardScreen> createState() =>
      _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState
    extends ConsumerState<ReportsDashboardScreen> {
  String _selectedReportType = 'Flock Health & Mortality Audit';
  String _selectedFormat = 'PDF Document (.pdf)';
  String _selectedFarm = 'All Facilities';
  bool _isGenerating = false;

  final List<String> _reportTypes = [
    'Flock Health & Mortality Audit',
    'Veterinary Clinical Incident Report',
    'Vaccination & Bio-security Compliance',
    'Feed Conversion Ratio (FCR) & Costing',
    'Government Surveillance Summary (SIH26128)',
  ];

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_selectedReportType generated successfully! Starting download...'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final farms = ref.watch(farmListProvider).value ?? [];

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          const WebPageHeader(
            title: 'Reports & Export Center',
            subtitle: 'Generate verifiable audit logs, veterinary certificates, and official government surveillance summaries.',
          ),

          // 2. Report Generation Studio Panel
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppDesign.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Generate New Audit Report', style: AppTypography.cardTitle),
                const SizedBox(height: 4),
                const Text(
                  'Select report parameters to compile telemetry, clinical incident records, and production charts.',
                  style: AppTypography.metadata,
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 20),

                // Form Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 1: Report Type
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Report Template', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedReportType,
                            decoration: const InputDecoration(isDense: true),
                            items: _reportTypes
                                .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedReportType = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Column 2: Facility Filter
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Poultry Facility', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedFarm,
                            decoration: const InputDecoration(isDense: true),
                            items: [
                              const DropdownMenuItem(value: 'All Facilities', child: Text('All Facilities', style: TextStyle(fontSize: 13))),
                              ...farms.map((f) => DropdownMenuItem(value: f.farmName, child: Text(f.farmName, style: const TextStyle(fontSize: 13)))),
                            ],
                            onChanged: (v) => setState(() => _selectedFarm = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Column 3: Output Format
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Export Format', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedFormat,
                            decoration: const InputDecoration(isDense: true),
                            items: const [
                              DropdownMenuItem(value: 'PDF Document (.pdf)', child: Text('PDF Document (.pdf)', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'Excel Spreadsheet (.xlsx)', child: Text('Excel Spreadsheet (.xlsx)', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'Raw CSV Table (.csv)', child: Text('Raw CSV Table (.csv)', style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (v) => setState(() => _selectedFormat = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Submit Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: 'Generate & Export Report',
                      icon: Icons.file_download_outlined,
                      size: AppButtonSize.medium,
                      isLoading: _isGenerating,
                      onPressed: _generateReport,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Recent Reports Table
          const Text('Generated Reports History', style: AppTypography.sectionTitle),
          const SizedBox(height: 12),

          ResponsiveDataTable(
            columns: const [
              ResponsiveDataColumn(label: 'Report Title', flex: 3),
              ResponsiveDataColumn(label: 'Target Facility', flex: 2),
              ResponsiveDataColumn(label: 'Generated On', flex: 2),
              ResponsiveDataColumn(label: 'File Format', flex: 2),
              ResponsiveDataColumn(label: 'Status', flex: 2),
              ResponsiveDataColumn(label: 'Download', flex: 1, align: TextAlign.right),
            ],
            rows: [
              ResponsiveDataRow(
                cells: [
                  const Text('Weekly Flock Mortality & Health Audit', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900)),
                  const Text('Green Valley (Nashik)'),
                  Text(DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now().subtract(const Duration(hours: 2)))),
                  const Text('PDF (1.8 MB)'),
                  StatusBadge.fromStatus('Completed'),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, size: 18, color: AppColors.primary),
                    tooltip: 'Download PDF',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading report...')),
                      );
                    },
                  ),
                ],
              ),
              ResponsiveDataRow(
                cells: [
                  const Text('Disease Anomaly Incident Report (HC-128)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900)),
                  const Text('Green Valley • Shed 2'),
                  Text(DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now().subtract(const Duration(hours: 5)))),
                  const Text('PDF (840 KB)'),
                  StatusBadge.fromStatus('Completed'),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, size: 18, color: AppColors.primary),
                    tooltip: 'Download PDF',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading Disease Anomaly Incident Report (HC-128)...')),
                      );
                    },
                  ),
                ],
              ),
              ResponsiveDataRow(
                cells: [
                  const Text('Monthly FCR & Feed Intake Log', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900)),
                  const Text('All Facilities'),
                  Text(DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now().subtract(const Duration(days: 1)))),
                  const Text('Excel (.xlsx)'),
                  StatusBadge.fromStatus('Completed'),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, size: 18, color: AppColors.primary),
                    tooltip: 'Download Excel',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading Monthly FCR & Feed Intake Log (.xlsx)...')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
