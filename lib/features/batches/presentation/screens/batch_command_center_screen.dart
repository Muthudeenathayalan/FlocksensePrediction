import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/metric_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/responsive_data_table.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';

class BatchCommandCenterScreen extends StatefulWidget {
  const BatchCommandCenterScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    required this.batchName,
  });

  final String farmId, batchId, batchName;

  @override
  State<BatchCommandCenterScreen> createState() => _BatchCommandCenterScreenState();
}

class _BatchCommandCenterScreenState extends State<BatchCommandCenterScreen>
    with SingleTickerProviderStateMixin {
  BatchModel? _batch;
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final b = await BatchService.getBatchById(widget.farmId, widget.batchId);
      if (mounted) {
        setState(() {
          _batch = b;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _ageDays => _batch != null
      ? DateTime.now().difference(_batch!.placementDate).inDays
      : 28;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.batchName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        elevation: 0,
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _load,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Flock Header Banner
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
                              child: const Icon(Icons.pets_outlined, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${_batch?.breed ?? "Broiler Cobb 500"} — ${widget.batchName}',
                                        style: AppTypography.pageTitle.copyWith(fontSize: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      StatusBadge.fromStatus(_batch?.status ?? 'active'),
                                      const SizedBox(width: 8),
                                      StatusBadge.fromStatus('Health: Moderate'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Flock Age: $_ageDays days • Live Count: ${NumberFormat("#,###").format(_batch?.currentBirdCount ?? 4920)} birds • Initial Placement: ${NumberFormat("#,###").format(_batch?.initialChicksCount ?? 5000)} chicks',
                                    style: AppTypography.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            AppButton(
                              label: 'Log Batch Telemetry',
                              icon: Icons.edit_note_rounded,
                              size: AppButtonSize.small,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DailyRecordsDashboardScreen(
                                      initialFarmId: widget.farmId,
                                      initialBatchId: widget.batchId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: AppColors.divider),

                        // Tabs
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabs: const [
                            Tab(text: 'Flock Overview'),
                            Tab(text: 'Growth & FCR'),
                            Tab(text: 'Feed & Water Intake'),
                            Tab(text: 'Mortality Tracking'),
                            Tab(text: 'Health & Symptoms'),
                            Tab(text: 'Vaccination History'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Tab Contents
                  SizedBox(
                    height: 600,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildGrowthTab(),
                        _buildFeedWaterTab(),
                        _buildMortalityTab(),
                        _buildHealthTab(),
                        _buildVaccinationTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewTab() {
    final b = _batch;
    final initial = b?.initialChicksCount ?? 5000;
    final live = b?.currentBirdCount ?? 4920;
    final mort = initial - live;
    final mortPct = ((mort / (initial > 0 ? initial : 1)) * 100).toStringAsFixed(2);

    return ListView(
      children: [
        // 4 KPI Summary
        Row(
          children: [
            Expanded(child: MetricCard(title: 'Placement Age', value: '$_ageDays Days', subtitle: 'Target Harvest: 38d', icon: Icons.calendar_today_outlined)),
            const SizedBox(width: 16),
            Expanded(child: MetricCard(title: 'Average Weight', value: '1,420 g', delta: '+65g vs Standard', isPositiveDelta: true, icon: Icons.monitor_weight_outlined, accentColor: AppColors.primary)),
            const SizedBox(width: 16),
            Expanded(child: MetricCard(title: 'Cumulative FCR', value: '1.48', delta: 'Optimal < 1.55', isPositiveDelta: true, icon: Icons.speed_outlined, accentColor: AppColors.healthy)),
            const SizedBox(width: 16),
            Expanded(child: MetricCard(title: 'Total Mortality', value: '$mort birds ($mortPct%)', delta: 'Under 3% cap', isPositiveDelta: true, icon: Icons.sick_outlined, accentColor: AppColors.slate700)),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: AppDesign.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Batch Parameters & Hatchery Traceability', style: AppTypography.cardTitle),
                    const SizedBox(height: 14),
                    AppDesign.infoRow('Batch ID', widget.batchId),
                    AppDesign.infoRow('Strain / Breed', b?.breed ?? 'Cobb 500 Slow Feathering'),
                    AppDesign.infoRow('Placement Date', b != null ? DateFormat('dd MMM yyyy').format(b.placementDate) : '28 Jul 2026'),
                    AppDesign.infoRow('Hatchery Source', 'Venky’s Hatchery Unit #4, Pune'),
                    AppDesign.infoRow('Chick Quality Index', '98.2% Grade-A Quality'),
                    AppDesign.infoRow('Initial Weight', '42.5 g / chick'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: AppDesign.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Environmental & Management Protocol', style: AppTypography.cardTitle),
                    const SizedBox(height: 14),
                    AppDesign.infoRow('Target Density', '1.2 sq.ft / bird'),
                    AppDesign.infoRow('Lighting Schedule', '20h Light / 4h Dark'),
                    AppDesign.infoRow('Target Harvest Day', 'Day 38–40 (2.20 kg Target)'),
                    AppDesign.infoRow('Current Feed Phase', 'Broiler Grower Pellets'),
                    AppDesign.infoRow('Shed Assigned', 'Shed Unit 02 (Tunnel Ventilated)'),
                    AppDesign.infoRow('Veterinarian Officer', 'Dr. V. Sharma (Nashik Sub-division)'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGrowthTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDesign.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Growth Curve & Body Weight Progression', style: AppTypography.cardTitle),
          const SizedBox(height: 16),
          Expanded(
            child: ResponsiveDataTable(
              columns: const [
                ResponsiveDataColumn(label: 'Week / Day', flex: 2),
                ResponsiveDataColumn(label: 'Actual Avg Weight', flex: 2),
                ResponsiveDataColumn(label: 'Breed Standard', flex: 2),
                ResponsiveDataColumn(label: 'Weekly Gain', flex: 2),
                ResponsiveDataColumn(label: 'Uniformity %', flex: 2),
                ResponsiveDataColumn(label: 'Status', flex: 2),
              ],
              rows: [
                ResponsiveDataRow(cells: [const Text('Day 7 (Week 1)'), const Text('185 g'), const Text('180 g'), const Text('+142 g'), const Text('88%'), StatusBadge.fromStatus('Healthy')]),
                ResponsiveDataRow(cells: [const Text('Day 14 (Week 2)'), const Text('460 g'), const Text('450 g'), const Text('+275 g'), const Text('89%'), StatusBadge.fromStatus('Healthy')]),
                ResponsiveDataRow(cells: [const Text('Day 21 (Week 3)'), const Text('890 g'), const Text('875 g'), const Text('+430 g'), const Text('87%'), StatusBadge.fromStatus('Healthy')]),
                ResponsiveDataRow(cells: [const Text('Day 28 (Week 4)'), const Text('1,420 g'), const Text('1,390 g'), const Text('+530 g'), const Text('86%'), StatusBadge.fromStatus('Healthy')]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedWaterTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDesign.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Intake & Water-to-Feed Ratio', style: AppTypography.cardTitle),
          const SizedBox(height: 16),
          Expanded(
            child: ResponsiveDataTable(
              columns: const [
                ResponsiveDataColumn(label: 'Date', flex: 2),
                ResponsiveDataColumn(label: 'Feed Type', flex: 2),
                ResponsiveDataColumn(label: 'Feed Consumed (kg)', flex: 2),
                ResponsiveDataColumn(label: 'Water Intake (L)', flex: 2),
                ResponsiveDataColumn(label: 'W:F Ratio', flex: 2),
                ResponsiveDataColumn(label: 'Status', flex: 2),
              ],
              rows: [
                ResponsiveDataRow(cells: [Text(DateFormat('dd MMM yyyy').format(DateTime.now())), const Text('Grower Pellets'), const Text('480 kg'), const Text('860 L'), const Text('1.79 (Normal)'), StatusBadge.fromStatus('Normal')]),
                ResponsiveDataRow(cells: [Text(DateFormat('dd MMM yyyy').format(DateTime.now().subtract(const Duration(days: 1)))), const Text('Grower Pellets'), const Text('475 kg'), const Text('850 L'), const Text('1.78 (Normal)'), StatusBadge.fromStatus('Normal')]),
                ResponsiveDataRow(cells: [Text(DateFormat('dd MMM yyyy').format(DateTime.now().subtract(const Duration(days: 2)))), const Text('Grower Pellets'), const Text('470 kg'), const Text('840 L'), const Text('1.78 (Normal)'), StatusBadge.fromStatus('Normal')]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMortalityTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDesign.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Flock Mortality & Cull Records', style: AppTypography.cardTitle),
          const SizedBox(height: 16),
          Expanded(
            child: ResponsiveDataTable(
              columns: const [
                ResponsiveDataColumn(label: 'Date', flex: 2),
                ResponsiveDataColumn(label: 'Dead Birds', flex: 2),
                ResponsiveDataColumn(label: 'Culls', flex: 2),
                ResponsiveDataColumn(label: 'Suspected Cause', flex: 3),
                ResponsiveDataColumn(label: 'Cumulative %', flex: 2),
                ResponsiveDataColumn(label: 'Risk Flag', flex: 2),
              ],
              rows: [
                ResponsiveDataRow(cells: [Text(DateFormat('dd MMM yyyy').format(DateTime.now())), const Text('3 birds'), const Text('0'), const Text('Natural / Sudden Death'), const Text('1.60%'), StatusBadge.fromStatus('Normal')]),
                ResponsiveDataRow(cells: [Text(DateFormat('dd MMM yyyy').format(DateTime.now().subtract(const Duration(days: 1)))), const Text('4 birds'), const Text('1'), const Text('Ascites / Water Belly'), const Text('1.54%'), StatusBadge.fromStatus('Normal')]),
                ResponsiveDataRow(cells: [Text(DateFormat('dd MMM yyyy').format(DateTime.now().subtract(const Duration(days: 2)))), const Text('2 birds'), const Text('0'), const Text('Weak chick syndrome'), const Text('1.46%'), StatusBadge.fromStatus('Normal')]),
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
          const Text('Clinical Observations & Symptoms', style: AppTypography.cardTitle),
          const SizedBox(height: 16),
          ResponsiveDataTable(
            columns: const [
              ResponsiveDataColumn(label: 'Log Date', flex: 2),
              ResponsiveDataColumn(label: 'Observed Signs', flex: 3),
              ResponsiveDataColumn(label: 'Affected Birds', flex: 2),
              ResponsiveDataColumn(label: 'AI Risk Rating', flex: 2),
              ResponsiveDataColumn(label: 'Veterinary Action', flex: 2),
            ],
            rows: [
              ResponsiveDataRow(cells: [Text(DateFormat('dd MMM yyyy').format(DateTime.now())), const Text('Slight coughing in south corner'), const Text('~15 birds'), StatusBadge.fromStatus('Warning'), const Text('Electrolytes Added')]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDesign.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vaccine Compliance History', style: AppTypography.cardTitle),
          const SizedBox(height: 16),
          ResponsiveDataTable(
            columns: const [
              ResponsiveDataColumn(label: 'Vaccine', flex: 3),
              ResponsiveDataColumn(label: 'Target Day', flex: 2),
              ResponsiveDataColumn(label: 'Date Administered', flex: 2),
              ResponsiveDataColumn(label: 'Batch # / Manufacturer', flex: 3),
              ResponsiveDataColumn(label: 'Status', flex: 2),
            ],
            rows: [
              ResponsiveDataRow(cells: [const Text('Marek’s (HVT)'), const Text('Day 1'), const Text('28 Jul 2026'), const Text('HVT-9281 / Hester'), StatusBadge.fromStatus('Completed')]),
              ResponsiveDataRow(cells: [const Text('Newcastle (LaSota)'), const Text('Day 7'), const Text('04 Aug 2026'), const Text('ND-8172 / Indovax'), StatusBadge.fromStatus('Completed')]),
              ResponsiveDataRow(cells: [const Text('IBD Gumboro'), const Text('Day 14'), const Text('11 Aug 2026'), const Text('IBD-4410 / Hester'), StatusBadge.fromStatus('Completed')]),
              ResponsiveDataRow(cells: [const Text('ND Booster (LaSota)'), const Text('Day 28'), const Text('Scheduled Today'), const Text('ND-9011 / Hester'), StatusBadge.fromStatus('Pending')]),
            ],
          ),
        ],
      ),
    );
  }
}
