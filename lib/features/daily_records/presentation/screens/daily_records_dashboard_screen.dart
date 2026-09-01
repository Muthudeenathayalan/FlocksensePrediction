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
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/data/daily_record_service.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';

class DailyRecordsDashboardScreen extends ConsumerStatefulWidget {
  final String? initialFarmId;
  final String? initialBatchId;
  final DailyRecordModel? existingRecord;

  const DailyRecordsDashboardScreen({
    super.key,
    this.initialFarmId,
    this.initialBatchId,
    this.existingRecord,
  });

  @override
  ConsumerState<DailyRecordsDashboardScreen> createState() =>
      _DailyRecordsDashboardScreenState();
}

class _DailyRecordsDashboardScreenState
    extends ConsumerState<DailyRecordsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  String? _selectedFarmId;
  String? _selectedBatchId;
  DateTime _selectedDate = DateTime.now();

  // Controllers
  final _mortalityController = TextEditingController(text: '0');
  final _feedController = TextEditingController(text: '480');
  final _waterController = TextEditingController(text: '860');
  final _tempController = TextEditingController(text: '28.5');
  final _humidityController = TextEditingController(text: '62');
  final _notesController = TextEditingController();

  final Set<String> _selectedSymptoms = {};
  final List<String> _commonSymptoms = [
    'Sneezing',
    'Coughing',
    'Lethargy',
    'Reduced Feed Intake',
    'Diarrhoea',
    'Water Belly (Ascites)',
    'Leg Weakness',
    'Ruffled Feathers',
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedFarmId = widget.initialFarmId;
    _selectedBatchId = widget.initialBatchId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mortalityController.dispose();
    _feedController.dispose();
    _waterController.dispose();
    _tempController.dispose();
    _humidityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFarmId == null || _selectedBatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a facility and batch')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await DailyRecordService.createOrUpdateDailyRecord(
        farmId: _selectedFarmId!,
        batchId: _selectedBatchId!,
        recordDate: _selectedDate,
        batchAgeDay: 28,
        openingBirds: 5000,
        mortalityCount: int.tryParse(_mortalityController.text.trim()) ?? 0,
        cullCount: 0,
        feedConsumedKg: double.tryParse(_feedController.text.trim()) ?? 0.0,
        waterConsumedLiters: double.tryParse(_waterController.text.trim()) ?? 0.0,
        avgWeightGrams: 1420.0,
        medicineGiven: false,
        vaccineGiven: false,
        symptoms: _selectedSymptoms.join(', '),
        notes: _notesController.text.trim(),
        temperature: double.tryParse(_tempController.text.trim()),
        humidity: double.tryParse(_humidityController.text.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily operational record saved successfully!')),
        );
        _tabController.animateTo(1); // Switch to logs view
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farms = ref.watch(farmListProvider).value ?? [];
    final batches = ref.watch(allUserBatchesProvider).value ?? [];

    if (_selectedFarmId == null && farms.isNotEmpty) {
      _selectedFarmId = farms.first.id;
    }
    if (_selectedBatchId == null && batches.isNotEmpty) {
      _selectedBatchId = batches.first.id;
    }

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          WebPageHeader(
            title: 'Daily Operational Logs',
            subtitle: 'Log flock mortality, feed distribution, water consumption, and ambient shed conditions.',
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
                    Tab(text: 'Log Today\'s Record'),
                    Tab(text: 'Historical Records Table'),
                  ],
                ),
              ),
            ],
          ),

          // 2. Tab Contents
          SizedBox(
            height: 750,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEntryForm(farms, batches),
                _buildHistoryTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryForm(List<FarmModel> farms, List<BatchModel> batches) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppDesign.maxFormWidth),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: AppDesign.cardDecoration,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Daily Operational Log Entry', style: AppTypography.sectionTitle),
                  const SizedBox(height: 4),
                  const Text(
                    'High-speed multi-metric recording for feed, water, and flock mortality.',
                    style: AppTypography.metadata,
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 20),

                  // Row 1: Farm & Batch Selectors
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Poultry Facility', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedFarmId,
                              decoration: const InputDecoration(isDense: true),
                              items: farms.map((f) => DropdownMenuItem(value: f.id, child: Text(f.farmName))).toList(),
                              onChanged: (val) => setState(() => _selectedFarmId = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Active Flock / Batch', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedBatchId,
                              decoration: const InputDecoration(isDense: true),
                              items: batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.batchName))).toList(),
                              onChanged: (val) => setState(() => _selectedBatchId = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Record Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                                border: Border.all(color: AppColors.border, width: 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 13.5)),
                                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.slate500),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Row 2: Mortality & Affected
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dead Birds (Mortality Count)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _mortalityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '0',
                                prefixIcon: Icon(Icons.sick_outlined, size: 18, color: AppColors.critical),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Feed Consumed (kg)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _feedController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '480',
                                prefixIcon: Icon(Icons.restaurant_outlined, size: 18, color: AppColors.warning),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Water Usage (Liters)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _waterController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '860',
                                prefixIcon: Icon(Icons.water_drop_outlined, size: 18, color: AppColors.info),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Row 3: Environmental Telemetry
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Shed Temperature (°C)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _tempController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '28.5',
                                prefixIcon: Icon(Icons.thermostat_outlined, size: 18, color: AppColors.healthy),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Relative Humidity (%)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _humidityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '62',
                                prefixIcon: Icon(Icons.cloud_outlined, size: 18, color: AppColors.slate500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Row 4: Observed Symptoms
                  const Text('Observed Clinical Signs & Symptoms', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonSymptoms.map((sym) {
                      final isSelected = _selectedSymptoms.contains(sym);
                      return FilterChip(
                        label: Text(sym),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSymptoms.add(sym);
                            } else {
                              _selectedSymptoms.remove(sym);
                            }
                          });
                        },
                        selectedColor: AppColors.primaryLight,
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? AppColors.primaryDark : AppColors.slate700,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Row 5: Notes
                  const Text('Operational Remarks & Silo Notes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Add remarks on flock behavior, ventilation changes, or feed delivery...',
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        label: 'Reset Fields',
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.medium,
                        onPressed: () {
                          _mortalityController.text = '0';
                          _feedController.text = '480';
                          _waterController.text = '860';
                          _notesController.clear();
                          setState(() => _selectedSymptoms.clear());
                        },
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        label: 'Save Operational Log',
                        icon: Icons.check_circle_outline_rounded,
                        size: AppButtonSize.medium,
                        isLoading: _isSaving,
                        onPressed: _saveRecord,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTable() {
    return ResponsiveDataTable(
      columns: const [
        ResponsiveDataColumn(label: 'Log Date', flex: 2),
        ResponsiveDataColumn(label: 'Facility', flex: 2),
        ResponsiveDataColumn(label: 'Flock', flex: 2),
        ResponsiveDataColumn(label: 'Mortality', flex: 1),
        ResponsiveDataColumn(label: 'Feed (kg)', flex: 2),
        ResponsiveDataColumn(label: 'Water (L)', flex: 2),
        ResponsiveDataColumn(label: 'Symptoms Observed', flex: 3),
        ResponsiveDataColumn(label: 'Status', flex: 2),
      ],
      rows: [
        ResponsiveDataRow(
          cells: [
            Text(DateFormat('dd MMM yyyy').format(DateTime.now())),
            const Text('Primary Farm'),
            const Text('Batch B07'),
            const Text('3 dead', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate800)),
            const Text('480 kg'),
            const Text('860 L'),
            const Text('None (Normal Activity)'),
            StatusBadge.fromStatus('Healthy'),
          ],
        ),
        ResponsiveDataRow(
          cells: [
            Text(DateFormat('dd MMM yyyy').format(DateTime.now().subtract(const Duration(days: 1)))),
            const Text('Primary Farm'),
            const Text('Batch B07'),
            const Text('4 dead', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate800)),
            const Text('475 kg'),
            const Text('850 L'),
            const Text('None'),
            StatusBadge.fromStatus('Healthy'),
          ],
        ),
        ResponsiveDataRow(
          cells: [
            Text(DateFormat('dd MMM yyyy').format(DateTime.now().subtract(const Duration(days: 2)))),
            const Text('Primary Farm'),
            const Text('Batch B07'),
            const Text('2 dead', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate800)),
            const Text('470 kg'),
            const Text('840 L'),
            const Text('Mild Sneezing'),
            StatusBadge.fromStatus('Warning'),
          ],
        ),
      ],
    );
  }
}
