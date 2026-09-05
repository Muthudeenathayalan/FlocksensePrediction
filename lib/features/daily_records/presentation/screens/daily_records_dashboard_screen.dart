import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/metric_card.dart';
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
  final DateTime _selectedDate = DateTime.now();

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
          const SnackBar(
            content: Text('Daily operational record saved successfully!'),
            backgroundColor: AppColors.healthy,
          ),
        );
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save error: $e'),
            backgroundColor: AppColors.critical,
          ),
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
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  ),
                  labelColor: AppColors.primaryDark,
                  unselectedLabelColor: AppColors.slate600,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Log Today\'s Record'),
                    Tab(text: 'Historical Records Table'),
                  ],
                ),
              ),
            ],
          ),

          // 2. 3 Clean Top KPI Metric Cards
          Row(
            children: const [
              Expanded(
                child: MetricCard(
                  title: 'Today\'s Mortality',
                  value: '0 Dead',
                  subtitle: '0.00% daily loss (Optimal <0.05%)',
                  icon: Icons.favorite_outline_rounded,
                  accentColor: AppColors.healthy,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  title: 'Feed Distributed Today',
                  value: '480 kg',
                  subtitle: 'Standard Broiler Starter 882',
                  icon: Icons.inventory_2_outlined,
                  accentColor: AppColors.warning,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  title: 'Water Intake',
                  value: '860 Liters',
                  subtitle: 'Ratio 1.79 (Normal hydration range)',
                  icon: Icons.water_drop_outlined,
                  accentColor: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3. Tab Contents
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
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('New Daily Operational Log Entry', style: AppTypography.headingSmall),
                          const SizedBox(height: 4),
                          Text(
                            'High-speed multi-metric recording for feed, water, and flock mortality.',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 20),

                  // Row 1: Farm & Batch Selectors
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Poultry Facility', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
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
                            Text('Active Flock / Batch', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
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
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Row 2: Mortality & Feed & Water
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dead Birds (Mortality Count)', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
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
                            Text('Feed Consumed (kg)', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
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
                            Text('Water Usage (Liters)', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
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
                            Text('Shed Temperature (°C)', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
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
                            Text('Relative Humidity (%)', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
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
                  Text('Observed Clinical Signs & Symptoms', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
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
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primaryDark : AppColors.slate700,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Row 5: Notes
                  Text('Operational Remarks & Silo Notes', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Add remarks on flock behavior, ventilation changes, or feed delivery...',
                    ),
                  ),
                  const SizedBox(height: 24),

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
    return AppCard(
      child: ResponsiveDataTable(
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
              Text(DateFormat('dd MMM yyyy').format(DateTime.now()), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900)),
              const Text('Primary Farm'),
              const Text('Batch B07'),
              const Text('0 dead', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.healthy)),
              const Text('480 kg'),
              const Text('860 L'),
              const Text('None (Normal Activity)'),
              StatusBadge.fromStatus('Healthy'),
            ],
          ),
          ResponsiveDataRow(
            cells: [
              Text(DateFormat('dd MMM yyyy').format(DateTime.now().subtract(const Duration(days: 1))), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900)),
              const Text('Primary Farm'),
              const Text('Batch B07'),
              const Text('2 dead', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate800)),
              const Text('475 kg'),
              const Text('850 L'),
              const Text('None'),
              StatusBadge.fromStatus('Healthy'),
            ],
          ),
          ResponsiveDataRow(
            cells: [
              Text(DateFormat('dd MMM yyyy').format(DateTime.now().subtract(const Duration(days: 2))), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate900)),
              const Text('Primary Farm'),
              const Text('Batch B07'),
              const Text('4 dead', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate800)),
              const Text('470 kg'),
              const Text('840 L'),
              const Text('Mild Sneezing'),
              StatusBadge.fromStatus('Warning'),
            ],
          ),
        ],
      ),
    );
  }
}
