import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/core/widgets/metric_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/responsive_data_table.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/health/data/health_service.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/presentation/widgets/ai_health_assessment_card.dart';
import 'package:flock_sense/features/health/presentation/widgets/explainable_risk_breakdown_card.dart';
import 'package:flock_sense/features/health/presentation/widgets/farm_prevention_dashboard_card.dart';
import 'package:flock_sense/features/health/presentation/widgets/farmer_veterinary_guidance_card.dart';
import 'package:flock_sense/features/health/presentation/widgets/lab_diagnostic_workflow_card.dart';
import 'package:flock_sense/features/health/presentation/widgets/outbreak_cluster_alert_card.dart';
import 'package:flock_sense/features/health/presentation/widgets/vet_priority_queue_card.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All Cases', 'High / Critical Risk', 'Under Treatment', 'Resolved'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openReportWizard() {
    AppDialog.show(
      context: context,
      child: const _ReportHealthIssueWizardModal(),
    );
  }

  void _openCaseDetailsModal(HealthCaseModel c) {
    AppDialog.show(
      context: context,
      child: _CaseDetailsDossierModal(healthCase: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HealthCaseModel>>(
      stream: HealthService.streamHealthCases(),
      initialData: HealthService.getSampleHealthCases(),
      builder: (context, snapshot) {
        final cases = (snapshot.data != null && snapshot.data!.isNotEmpty)
            ? snapshot.data!
            : HealthService.getSampleHealthCases();
        final activeCases = cases.where((c) => c.status != HealthCaseStatus.closed).toList();
        final criticalCases = cases.where((c) => c.riskLevel == HealthRiskLevel.critical || c.riskLevel == HealthRiskLevel.high).toList();
        final totalAffected = cases.fold<int>(0, (sum, c) => sum + c.affectedCount);

        List<HealthCaseModel> filteredCases = cases;
        if (_selectedFilterIndex == 1) {
          filteredCases = criticalCases;
        } else if (_selectedFilterIndex == 2) {
          filteredCases = cases.where((c) => c.status == HealthCaseStatus.treatment_started).toList();
        } else if (_selectedFilterIndex == 3) {
          filteredCases = cases.where((c) => c.status == HealthCaseStatus.closed).toList();
        }

        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              WebPageHeader(
                title: 'Animal Health & Disease Surveillance',
                subtitle: 'SIH26128 • Clinical triage, syndromic surveillance, AI decision support, and veterinary coordination.',
                actions: [
                  AppButton(
                    label: 'Report Health Incident',
                    icon: Icons.add_alert_rounded,
                    size: AppButtonSize.small,
                    onPressed: _openReportWizard,
                  ),
                ],
              ),

              // 2. 4 Top KPI Summary Cards
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Active Health Cases',
                      value: '${activeCases.length} Cases',
                      subtitle: 'Under observation',
                      icon: Icons.healing_outlined,
                      accentColor: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MetricCard(
                      title: 'Critical Triage',
                      value: '${criticalCases.length} Incidents',
                      subtitle: 'Urgent vet intervention',
                      delta: 'Priority-1',
                      isPositiveDelta: false,
                      icon: Icons.error_outline_rounded,
                      accentColor: AppColors.critical,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MetricCard(
                      title: 'Birds Affected',
                      value: NumberFormat('#,###').format(totalAffected),
                      subtitle: 'Clinical symptoms reported',
                      icon: Icons.sick_outlined,
                      accentColor: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MetricCard(
                      title: 'Surveillance Status',
                      value: 'Tier-1 Secure',
                      subtitle: '0 Regional Outbreaks',
                      delta: 'Clean',
                      isPositiveDelta: true,
                      icon: Icons.shield_outlined,
                      accentColor: AppColors.healthy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2B. Regional Disease Activity Advisory (Anonymized Farmer Early Warning)
              const OutbreakClusterAlertCard(district: 'Nashik', isFarmerView: true),
              const SizedBox(height: 16),

              // 2C. Farm Biosecurity & Prevention Intelligence (Phase 10)
              const FarmPreventionDashboardCard(farmId: 'farm_gv_01', farmName: 'Green Valley Poultry Farm'),
              const SizedBox(height: 24),

              // 3. Navigation Tabs
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Active Health Cases (Table)'),
                    Tab(text: 'AI Clinical Risk Assessment'),
                    Tab(text: 'GIS Outbreak & Risk Map'),
                    Tab(text: 'Veterinarian Priority Queue & Triage'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Tab Views
              SizedBox(
                height: 650,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCasesTableTab(filteredCases),
                    _buildAiDecisionSupportTab(criticalCases.isNotEmpty ? criticalCases.first : null),
                    _buildGisMapTab(),
                    _buildVetDossierTab(cases.isNotEmpty ? cases.first : null),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCasesTableTab(List<HealthCaseModel> cases) {
    return Column(
      children: [
        // Filter Chips Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: AppDesign.cardDecorationFlat,
          child: Row(
            children: [
              const Text('Filter by Severity:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate700)),
              const SizedBox(width: 12),
              ...List.generate(_filters.length, (idx) {
                final isSelected = _selectedFilterIndex == idx;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_filters[idx]),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilterIndex = idx),
                    selectedColor: AppColors.primaryLight,
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primaryDark : AppColors.slate700,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Table
        Expanded(
          child: ResponsiveDataTable(
            emptyMessage: 'No clinical health incidents recorded.',
            columns: const [
              ResponsiveDataColumn(label: 'Case ID', flex: 2),
              ResponsiveDataColumn(label: 'Facility / Shed', flex: 2),
              ResponsiveDataColumn(label: 'Flock', flex: 2),
              ResponsiveDataColumn(label: 'Suspected Condition', flex: 3),
              ResponsiveDataColumn(label: 'Risk Level', flex: 2),
              ResponsiveDataColumn(label: 'Birds Affected', flex: 2),
              ResponsiveDataColumn(label: 'Status', flex: 2),
              ResponsiveDataColumn(label: 'Actions', flex: 2, align: TextAlign.right),
            ],
            rows: cases.map((c) {
              return ResponsiveDataRow(
                onTap: () => _openCaseDetailsModal(c),
                cells: [
                  Text(c.id.substring(0, c.id.length > 10 ? 10 : c.id.length), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.slate900)),
                  Text(c.farmId),
                  Text(c.batchId),
                  Text(c.suspectedDisease.isNotEmpty ? c.suspectedDisease : 'Syndromic Anomaly', style: const TextStyle(fontWeight: FontWeight.w600)),
                  AppDesign.riskBadge(c.riskLevel.name),
                  Text('${c.affectedCount} birds (${c.mortalityCount} dead)'),
                  StatusBadge.fromStatus(c.status.name),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        label: 'Investigate',
                        size: AppButtonSize.small,
                        variant: AppButtonVariant.outlined,
                        onPressed: () => _openCaseDetailsModal(c),
                      ),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAiDecisionSupportTab(HealthCaseModel? c) {
    if (c == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: AppDesign.cardDecoration,
        child: const Center(
          child: Text(
            'No active health cases reported for AI clinical decision support.',
            style: TextStyle(color: AppColors.slate500, fontSize: 13),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExplainableRiskBreakdownCard(healthCase: c),
          const SizedBox(height: 20),
          AIHealthAssessmentCard(healthCase: c),
        ],
      ),
    );
  }

  Widget _buildGisMapTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDesign.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Maharashtra Regional Disease Surveillance GIS Map', style: AppTypography.cardTitle),
                  SizedBox(height: 2),
                  Text('Real-time geo-tagged outbreak clusters & bio-security containment zones', style: AppTypography.metadata),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem('Healthy (Tier-1)', AppColors.healthy),
                  const SizedBox(width: 12),
                  _buildLegendItem('Monitoring', AppColors.warning),
                  const SizedBox(width: 12),
                  _buildLegendItem('Critical Outbreak Zone', AppColors.critical),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interactive Map Simulation Canvas
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                border: Border.all(color: AppColors.slate800, width: 1),
              ),
              child: Stack(
                children: [
                  // Map Background Grid Lines
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GisGridPainter(),
                    ),
                  ),

                  // Simulated Farm Clusters with clickable nodes
                  _buildMapNode(120, 180, 'Green Valley Farm (Nashik)', 'CRITICAL (NDV Suspected)', AppColors.critical),
                  _buildMapNode(280, 240, 'Sunrise Farm Unit 01 (Pune)', 'HEALTHY (4 Flocks)', AppColors.healthy),
                  _buildMapNode(420, 160, 'Kalyan Broiler Hatchery (Thane)', 'MONITORING', AppColors.warning),
                  _buildMapNode(550, 290, 'Shree Ganesh Agro (Satara)', 'HEALTHY', AppColors.healthy),
                  _buildMapNode(220, 360, 'Solapur Integrated Unit #3', 'HEALTHY', AppColors.healthy),

                  // Map Controls Floating Panel
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.slate900.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                        border: Border.all(color: AppColors.slate700, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('DISTRICT: NASHIK DIVISION', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Farms Screened: 142 • Active Alerts: 2', style: TextStyle(color: AppColors.slate300, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVetDossierTab(HealthCaseModel? c) {
    return const SingleChildScrollView(
      child: VetPriorityQueueCard(),
    );
  }

  Widget _buildConditionItem(String title, String match, Color color, Color bg, String desc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.slate900)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                child: Text(match, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.slate700)),
        ],
      ),
    );
  }

  Widget _buildEvidenceRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.slate800))),
      ],
    );
  }

  Widget _buildActionStep(String step, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: AppColors.primary,
          child: Text(step, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.slate900)),
              Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.slate700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.slate700, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMapNode(double left, double top, String title, String status, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: Tooltip(
        message: '$title\nStatus: $status',
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Selected GIS node: $title ($status)')),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(title.split(' ').first, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep(String time, String title, String desc, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: isDone ? AppColors.healthy : AppColors.slate400,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.slate900)),
                    Text(time, style: AppTypography.metadata),
                  ],
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.slate600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5-STEP GUIDED HEALTH REPORTING MODAL WIZARD
// ─────────────────────────────────────────────────────────────────────────────
class _ReportHealthIssueWizardModal extends StatefulWidget {
  const _ReportHealthIssueWizardModal();

  @override
  State<_ReportHealthIssueWizardModal> createState() => _ReportHealthIssueWizardModalState();
}

class _ReportHealthIssueWizardModalState extends State<_ReportHealthIssueWizardModal> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  String _farm = 'Primary Farm (Nashik)';
  String _flock = 'Batch B07 (Cobb 500)';
  final _affectedController = TextEditingController(text: '15');
  final _mortalityController = TextEditingController(text: '4');
  final _notesController = TextEditingController();

  final Set<String> _selectedSymptoms = {'Sneezing', 'Reduced Feed Intake'};
  final List<String> _symptoms = [
    'Coughing',
    'Sneezing',
    'Weakness',
    'Diarrhoea',
    'Respiratory Difficulty',
    'Reduced Appetite',
    'Swelling (Head/Comb)',
    'Skin Lesions',
    'Neurological Signs',
  ];

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wizard Progress Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Report Health Incident • Step ${_currentStep + 1} of 5', style: AppTypography.titleLarge),
                  IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentStep + 1) / 5,
                backgroundColor: AppColors.slate100,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
              const SizedBox(height: 20),

              // Step Content
              if (_currentStep == 0) _buildStep1(),
              if (_currentStep == 1) _buildStep2(),
              if (_currentStep == 2) _buildStep3(),
              if (_currentStep == 3) _buildStep4(),
              if (_currentStep == 4) _buildStep5(),

              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    AppButton(
                      label: 'Back',
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.small,
                      onPressed: () => setState(() => _currentStep--),
                    )
                  else
                    const SizedBox.shrink(),
                  AppButton(
                    label: _currentStep == 4 ? 'Analyze & Submit to Vet' : 'Continue Next',
                    size: AppButtonSize.small,
                    onPressed: () {
                      if (_currentStep < 4) {
                        setState(() => _currentStep++);
                      } else {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Health case submitted & AI diagnostic initiated!')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 1: Facility & Flock Affected', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _farm,
          decoration: const InputDecoration(labelText: 'Poultry Farm', isDense: true),
          items: [_farm].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
          onChanged: (v) => setState(() => _farm = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _flock,
          decoration: const InputDecoration(labelText: 'Affected Flock', isDense: true),
          items: [_flock].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
          onChanged: (v) => setState(() => _flock = v!),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _affectedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Affected Birds Count', isDense: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _mortalityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Dead Birds Today', isDense: true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 2: Select Observed Clinical Signs', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        const Text('Select all symptoms noticed during morning and afternoon shed inspection:', style: AppTypography.metadata),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _symptoms.map((s) {
            final isSelected = _selectedSymptoms.contains(s);
            return FilterChip(
              label: Text(s),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) _selectedSymptoms.add(s);
                  else _selectedSymptoms.remove(s);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 3: Vital Flock Telemetry & Intake Drops', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: '18%',
          decoration: const InputDecoration(labelText: 'Feed Reduction Percentage (%)', isDense: true),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: '12%',
          decoration: const InputDecoration(labelText: 'Water Consumption Drop (%)', isDense: true),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: '28.5°C',
          decoration: const InputDecoration(labelText: 'Ambient Shed Temperature', isDense: true),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 4: Clinical Observations & Notes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe physical signs, droppings color, posture, or post-mortem lesions...',
          ),
        ),
      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 5: Review Incident Report', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(AppDesign.radiusMd),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: [
              AppDesign.infoRow('Facility', _farm),
              AppDesign.infoRow('Flock', _flock),
              AppDesign.infoRow('Affected / Dead', '${_affectedController.text} affected • ${_mortalityController.text} dead'),
              AppDesign.infoRow('Symptoms', _selectedSymptoms.join(', ')),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CASE DETAILS DOSSIER MODAL WITH EXPLAINABLE RISK BREAKDOWN (SIH26128)
// ─────────────────────────────────────────────────────────────────────────────
class _CaseDetailsDossierModal extends StatelessWidget {
  final HealthCaseModel healthCase;
  const _CaseDetailsDossierModal({required this.healthCase});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 780, maxHeight: 850),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                  ),
                  child: const Icon(Icons.assignment_outlined,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Incident Dossier: ${healthCase.caseNumber}',
                              style: AppTypography.titleLarge),
                          const SizedBox(width: 10),
                          StatusBadge.fromStatus(healthCase.status.name),
                        ],
                      ),
                      Text(
                        'Facility: ${healthCase.farmName} • Flock: ${healthCase.flockName} • Reported: ${DateFormat("dd MMM yyyy, HH:mm").format(healthCase.reportedAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.slate500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Central Explainable Real-Time Risk Breakdown Card (Authoritative Phase 3 Engine)
                    ExplainableRiskBreakdownCard(healthCase: healthCase),
                    const SizedBox(height: 20),

                    // 2. Official Veterinary Clinical Guidance & Management Plan (Phase 6 Workflow)
                    FarmerVeterinaryGuidanceCard(healthCase: healthCase),
                    const SizedBox(height: 20),

                    // 3. Diagnostic Laboratory Sample Tracking & Confirmatory Results (Phase 7 Workflow)
                    if (healthCase.labRequired) ...[
                      LabDiagnosticWorkflowCard(healthCase: healthCase, isVeterinarian: false),
                      const SizedBox(height: 20),
                    ],

                    // 4. Multimodal AI Clinical Decision-Support Card (Phase 4 Multimodal Intelligence)
                    AIHealthAssessmentCard(healthCase: healthCase),
                    const SizedBox(height: 20),

                    // 3. Clinical Observation & Symptoms Gallery
                    const Text(
                      'CLINICAL SYMPTOMS OBSERVED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.slate500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (healthCase.symptoms.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: healthCase.symptoms.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.slate100,
                              borderRadius:
                                  BorderRadius.circular(AppDesign.radiusSm),
                              border: Border.all(
                                  color: AppColors.slate300, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.coronavirus_outlined,
                                    size: 14, color: AppColors.slate700),
                                const SizedBox(width: 6),
                                Text(
                                  s.replaceAll('_', ' ').toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    else
                      const Text('No specific clinical symptoms selected.',
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.slate500)),
                    const SizedBox(height: 18),

                    // 3. Clinical Notes & Observations
                    if (healthCase.notes.isNotEmpty) ...[
                      const Text(
                        'FARMER CLINICAL NOTES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius:
                              BorderRadius.circular(AppDesign.radiusMd),
                          border:
                              Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Text(
                          healthCase.notes,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.slate800,
                              height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // 4. Evidence Images Gallery (if any)
                    if (healthCase.imageUrls.isNotEmpty) ...[
                      const Text(
                        'PHOTOGRAPHIC EVIDENCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: healthCase.imageUrls.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, idx) {
                            return ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppDesign.radiusMd),
                              child: Image.network(
                                healthCase.imageUrls[idx],
                                width: 120,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 120,
                                  height: 100,
                                  color: AppColors.slate200,
                                  child: const Icon(Icons.broken_image,
                                      color: AppColors.slate500),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // 5. Facility & Flock Telemetry Metadata
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AppDesign.cardDecorationFlat,
                      child: Column(
                        children: [
                          AppDesign.infoRow('Facility / Farm ID',
                              '${healthCase.farmName} (${healthCase.farmId})'),
                          AppDesign.infoRow('Flock / Batch ID',
                              '${healthCase.flockName} (${healthCase.flockId})'),
                          AppDesign.infoRow('Birds Affected / Mortality',
                              '${healthCase.affectedCount} affected • ${healthCase.mortalityCount} dead'),
                          if (healthCase.temperature != null ||
                              healthCase.humidity != null)
                            AppDesign.infoRow(
                              'Environmental Telemetry',
                              '${healthCase.temperature?.toStringAsFixed(1) ?? "--"}°C Temp • ${healthCase.humidity?.toStringAsFixed(0) ?? "--"}% Humidity',
                            ),
                          AppDesign.infoRow(
                            'Lifecycle Status',
                            healthCase.status.label.toUpperCase(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),

            // Footer Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SIH26128 Health Surveillance Engine',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.slate400),
                ),
                AppButton(
                  label: 'Close Dossier',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.small,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GisGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += 40) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
