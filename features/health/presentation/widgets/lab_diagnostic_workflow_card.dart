import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/health/data/lab_test_service.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/lab_test_model.dart';

/// Professional Web SaaS Laboratory Diagnostic & Sample Tracking Card (SIH26128 Phase 7)
class LabDiagnosticWorkflowCard extends StatefulWidget {
  final HealthCaseModel healthCase;
  final bool isVeterinarian;
  final VoidCallback? onStatusUpdated;

  const LabDiagnosticWorkflowCard({
    super.key,
    required this.healthCase,
    this.isVeterinarian = true,
    this.onStatusUpdated,
  });

  @override
  State<LabDiagnosticWorkflowCard> createState() => _LabDiagnosticWorkflowCardState();
}

class _LabDiagnosticWorkflowCardState extends State<LabDiagnosticWorkflowCard> {
  int _selectedTestIndex = 0;

  void _openCollectionDialog(LabTestModel test) {
    showDialog(
      context: context,
      builder: (ctx) => _SampleCollectionDialog(test: test, onSaved: () => setState(() {})),
    );
  }

  void _openDispatchDialog(LabTestModel test) {
    showDialog(
      context: context,
      builder: (ctx) => _SampleDispatchDialog(test: test, onSaved: () => setState(() {})),
    );
  }

  void _openReceiveDialog(LabTestModel test) {
    showDialog(
      context: context,
      builder: (ctx) => _SampleReceiveDialog(test: test, onSaved: () => setState(() {})),
    );
  }

  void _openResultEntryDialog(LabTestModel test) {
    showDialog(
      context: context,
      builder: (ctx) => _LabResultEntryDialog(
        test: test,
        healthCase: widget.healthCase,
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _openVetReviewDialog(LabTestModel test) {
    showDialog(
      context: context,
      builder: (ctx) => _VetResultReviewDialog(
        test: test,
        healthCase: widget.healthCase,
        onSaved: () {
          widget.onStatusUpdated?.call();
          setState(() {});
        },
      ),
    );
  }

  void _openRepeatTestDialog(LabTestModel test) {
    showDialog(
      context: context,
      builder: (ctx) => _RepeatTestDialog(
        previousTest: test,
        healthCase: widget.healthCase,
        onSaved: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LabTestModel>>(
      stream: LabTestService.streamTestsForCase(widget.healthCase.id),
      builder: (context, snapshot) {
        final tests = snapshot.data ?? [];

        if (tests.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDesign.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No laboratory diagnostic tests requested for this case.',
                style: TextStyle(fontSize: 13, color: AppColors.slate600),
              ),
            ),
          );
        }

        final currentIndex = _selectedTestIndex < tests.length ? _selectedTestIndex : 0;
        final currentTest = tests[currentIndex];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDesign.radiusLg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppDesign.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Banner
              _buildHeader(currentTest, tests),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Turnaround & Status Summary Bar
                    _buildSummaryBar(currentTest),
                    const SizedBox(height: 20),

                    // 2. Visual Sample Lifecycle Stepper
                    _buildLifecycleStepper(currentTest),
                    const SizedBox(height: 20),

                    // 3. Official Diagnostic Result Panel
                    if (currentTest.status == LabTestStatus.result_available || currentTest.status == LabTestStatus.reviewed)
                      _buildResultPanel(currentTest),

                    // 4. Clinical Separation Disclaimer
                    _buildClinicalAuthorityBanner(currentTest),
                    const SizedBox(height: 16),

                    // 5. Action Toolbar
                    _buildActionToolbar(currentTest),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(LabTestModel test, List<LabTestModel> allTests) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDesign.radiusLg),
          topRight: Radius.circular(AppDesign.radiusLg),
        ),
        border: const Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppDesign.radiusSm)),
                child: const Icon(Icons.biotech_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Diagnostic Laboratory Test • ${test.sampleId}', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.slate900)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: test.priority == 'emergency' || test.priority == 'urgent' ? AppColors.criticalBg : AppColors.slate100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: test.priority == 'emergency' || test.priority == 'urgent' ? AppColors.critical : AppColors.slate300),
                        ),
                        child: Text(
                          test.priority.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: test.priority == 'emergency' || test.priority == 'urgent' ? AppColors.critical : AppColors.slate700),
                        ),
                      ),
                    ],
                  ),
                  Text('${test.testRequested} (${test.sampleType}) • ${test.labName ?? "Central Diagnostic Lab"}', style: const TextStyle(fontSize: 11.5, color: AppColors.slate600)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (allTests.length > 1)
                DropdownButton<int>(
                  value: _selectedTestIndex,
                  underline: const SizedBox.shrink(),
                  items: List.generate(allTests.length, (i) {
                    return DropdownMenuItem(value: i, child: Text('Sample #${i + 1}: ${allTests[i].sampleId}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)));
                  }),
                  onChanged: (val) => setState(() => _selectedTestIndex = val ?? 0),
                ),
              const SizedBox(width: 8),
              StatusBadge.fromStatus(test.status.name),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(LabTestModel test) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: test.isDelayed ? AppColors.criticalBg.withOpacity(0.5) : AppColors.slate50,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        border: Border.all(color: test.isDelayed ? AppColors.critical.withOpacity(0.4) : AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: AppColors.slate700),
              const SizedBox(width: 8),
              Text('Turnaround Time: ${test.turnaroundTimeFormatted}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.slate800)),
              if (test.isDelayed) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.critical, borderRadius: BorderRadius.circular(4)),
                  child: const Text('BEYOND RESPONSE TARGET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
            ],
          ),
          Text(
            'Requested: ${DateFormat("dd MMM, hh:mm a").format(test.requestedAt)} by ${test.requestedBy}',
            style: const TextStyle(fontSize: 11.5, color: AppColors.slate600),
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleStepper(LabTestModel test) {
    final steps = [
      _StepInfo('1', 'Requested', test.requestedAt, true),
      _StepInfo('2', 'Collected', test.collectedAt, test.collectedAt != null),
      _StepInfo('3', 'In Transit', test.dispatchedAt, test.dispatchedAt != null),
      _StepInfo('4', 'Received', test.receivedAt, test.receivedAt != null),
      _StepInfo('5', 'Testing', test.testingStartedAt, test.testingStartedAt != null),
      _StepInfo('6', 'Result', test.resultAt, test.resultAt != null),
      _StepInfo('7', 'Confirmed', test.reviewedAt, test.reviewedAt != null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DIAGNOSTIC SAMPLE LIFECYCLE & QUALITY CONTROL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.slate500)),
        const SizedBox(height: 12),
        Row(
          children: steps.map((s) {
            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: s.isDone ? AppColors.primary : AppColors.slate300,
                        child: Text(s.index, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                      if (s.index != '7')
                        Expanded(
                          child: Container(
                            height: 2,
                            color: s.isDone ? AppColors.primary : AppColors.slate300,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(s.title, style: TextStyle(fontSize: 11, fontWeight: s.isDone ? FontWeight.w700 : FontWeight.w500, color: s.isDone ? AppColors.slate900 : AppColors.slate500)),
                  ),
                  if (s.time != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(DateFormat('dd MMM, hh:mm').format(s.time!), style: const TextStyle(fontSize: 9.5, color: AppColors.slate500)),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultPanel(LabTestModel test) {
    final isPositive = test.resultCategory == LabResultCategory.positive;
    final isReviewed = test.status == LabTestStatus.reviewed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPositive ? AppColors.criticalBg.withOpacity(0.5) : AppColors.healthyBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        border: Border.all(color: isPositive ? AppColors.critical.withOpacity(0.4) : AppColors.healthy.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(isPositive ? Icons.error_outline_rounded : Icons.check_circle_outline, color: isPositive ? AppColors.critical : AppColors.healthy, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'LABORATORY RESULT: ${test.result ?? test.resultCategory?.label.toUpperCase()}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isPositive ? AppColors.critical : AppColors.healthy),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isReviewed ? AppColors.primary : AppColors.warning,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isReviewed ? 'VET CLINICALLY CONFIRMED' : 'AWAITING VET INTERPRETATION',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
          if (test.resultNotes != null && test.resultNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Lab Notes: ${test.resultNotes!}', style: const TextStyle(fontSize: 12.5, color: AppColors.slate800)),
          ],
          if (test.vetInterpretationNotes != null && test.vetInterpretationNotes!.isNotEmpty) ...[
            const Divider(height: 16, color: AppColors.divider),
            Text('Veterinarian Clinical Assessment: "${test.vetInterpretationNotes}"', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: AppColors.slate900)),
            if (test.confirmationBasis != null)
              Text('Confirmation Basis: ${test.confirmationBasis}', style: const TextStyle(fontSize: 11.5, color: AppColors.slate700)),
          ],
        ],
      ),
    );
  }

  Widget _buildClinicalAuthorityBanner(LabTestModel test) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Clinical Authority Principle: AI suggestions and raw lab findings never automatically declare confirmed diagnosis. Official confirmation is established exclusively by authorized veterinary review.',
              style: TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionToolbar(LabTestModel test) {
    if (!widget.isVeterinarian) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (test.status == LabTestStatus.requested || test.status == LabTestStatus.sample_ready)
              OutlinedButton.icon(
                icon: const Icon(Icons.check_box_outlined, size: 14),
                label: const Text('Mark Collected'),
                onPressed: () => _openCollectionDialog(test),
              ),
            if (test.status == LabTestStatus.collected)
              OutlinedButton.icon(
                icon: const Icon(Icons.local_shipping_outlined, size: 14),
                label: const Text('Dispatch in Transit'),
                onPressed: () => _openDispatchDialog(test),
              ),
            if (test.status == LabTestStatus.dispatched)
              OutlinedButton.icon(
                icon: const Icon(Icons.inventory_2_outlined, size: 14),
                label: const Text('Receive at Lab'),
                onPressed: () => _openReceiveDialog(test),
              ),
            if (test.status == LabTestStatus.received)
              OutlinedButton.icon(
                icon: const Icon(Icons.play_circle_outline, size: 14),
                label: const Text('Start Testing'),
                onPressed: () async {
                  await LabTestService.startTesting(testId: test.id);
                  setState(() {});
                },
              ),
            if (test.status == LabTestStatus.testing)
              AppButton(
                label: 'Enter Lab Result',
                icon: Icons.assignment_turned_in_outlined,
                size: AppButtonSize.small,
                onPressed: () => _openResultEntryDialog(test),
              ),
            if (test.status == LabTestStatus.result_available)
              AppButton(
                label: 'Review & Confirm Diagnosis',
                icon: Icons.verified_user_outlined,
                size: AppButtonSize.small,
                onPressed: () => _openVetReviewDialog(test),
              ),
            if (test.status == LabTestStatus.inconclusive || test.status == LabTestStatus.rejected)
              OutlinedButton.icon(
                icon: const Icon(Icons.replay_rounded, size: 14),
                label: const Text('Request Repeat Test'),
                onPressed: () => _openRepeatTestDialog(test),
              ),
          ],
        ),
      ],
    );
  }
}

class _StepInfo {
  final String index;
  final String title;
  final DateTime? time;
  final bool isDone;
  _StepInfo(this.index, this.title, this.time, this.isDone);
}

/// Sample Collection Dialog
class _SampleCollectionDialog extends StatefulWidget {
  final LabTestModel test;
  final VoidCallback onSaved;

  const _SampleCollectionDialog({required this.test, required this.onSaved});

  @override
  State<_SampleCollectionDialog> createState() => _SampleCollectionDialogState();
}

class _SampleCollectionDialogState extends State<_SampleCollectionDialog> {
  final _collectorCtrl = TextEditingController(text: 'Field Assistant A. Deshmukh');
  final _locationCtrl = TextEditingController(text: 'Shed 2 (Green Valley Farm)');
  final _quantityCtrl = TextEditingController(text: '4 Swabs in Viral Transport Medium (VTM)');
  final _notesCtrl = TextEditingController(text: 'Swabs collected from acute symptomatic birds.');
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final success = await LabTestService.collectSample(
      testId: widget.test.id,
      collectorName: _collectorCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      sampleQuantity: _quantityCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        widget.onSaved();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Record Sample Collection', style: AppTypography.titleLarge),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _collectorCtrl, decoration: const InputDecoration(labelText: 'Collector Name')),
            const SizedBox(height: 12),
            TextFormField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'Collection Location')),
            const SizedBox(height: 12),
            TextFormField(controller: _quantityCtrl, decoration: const InputDecoration(labelText: 'Sample Quantity / Vials')),
            const SizedBox(height: 12),
            TextFormField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Collection Notes')),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                AppButton(label: 'Save Collection', size: AppButtonSize.small, onPressed: _isSaving ? null : _save),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Sample Dispatch Dialog
class _SampleDispatchDialog extends StatefulWidget {
  final LabTestModel test;
  final VoidCallback onSaved;

  const _SampleDispatchDialog({required this.test, required this.onSaved});

  @override
  State<_SampleDispatchDialog> createState() => _SampleDispatchDialogState();
}

class _SampleDispatchDialogState extends State<_SampleDispatchDialog> {
  final _labCtrl = TextEditingController(text: 'Central Poultry Disease Diagnostic Lab, Pune');
  final _trackingCtrl = TextEditingController(text: 'MAH-VET-COLD-8921');
  final _notesCtrl = TextEditingController(text: 'Cold chain maintained with insulated ice box (2-8°C).');
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final success = await LabTestService.dispatchSample(
      testId: widget.test.id,
      destinationLab: _labCtrl.text.trim(),
      trackingReference: _trackingCtrl.text.trim(),
      transportNotes: _notesCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        widget.onSaved();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dispatch Sample in Transit', style: AppTypography.titleLarge),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _labCtrl, decoration: const InputDecoration(labelText: 'Destination Laboratory')),
            const SizedBox(height: 12),
            TextFormField(controller: _trackingCtrl, decoration: const InputDecoration(labelText: 'Cold Chain Tracking ID')),
            const SizedBox(height: 12),
            TextFormField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Transit Notes')),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                AppButton(label: 'Mark Dispatched', size: AppButtonSize.small, onPressed: _isSaving ? null : _save),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Sample Reception Dialog
class _SampleReceiveDialog extends StatefulWidget {
  final LabTestModel test;
  final VoidCallback onSaved;

  const _SampleReceiveDialog({required this.test, required this.onSaved});

  @override
  State<_SampleReceiveDialog> createState() => _SampleReceiveDialogState();
}

class _SampleReceiveDialogState extends State<_SampleReceiveDialog> {
  final _receiverCtrl = TextEditingController(text: 'Lab Duty Officer M. Kulkarni');
  SampleReceiptCondition _condition = SampleReceiptCondition.acceptable;
  final _reasonCtrl = TextEditingController();
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final success = await LabTestService.receiveSample(
      testId: widget.test.id,
      receivedBy: _receiverCtrl.text.trim(),
      condition: _condition,
      rejectionReason: _reasonCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        widget.onSaved();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Laboratory Sample Receipt', style: AppTypography.titleLarge),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _receiverCtrl, decoration: const InputDecoration(labelText: 'Received By')),
            const SizedBox(height: 12),
            DropdownButtonFormField<SampleReceiptCondition>(
              value: _condition,
              decoration: const InputDecoration(labelText: 'Sample Condition at Arrival'),
              items: SampleReceiptCondition.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
              onChanged: (val) => setState(() => _condition = val ?? _condition),
            ),
            if (_condition != SampleReceiptCondition.acceptable) ...[
              const SizedBox(height: 12),
              TextFormField(controller: _reasonCtrl, decoration: const InputDecoration(labelText: 'Rejection Reason / Defect Notes')),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                AppButton(label: 'Confirm Receipt', size: AppButtonSize.small, onPressed: _isSaving ? null : _save),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Lab Result Entry Dialog
class _LabResultEntryDialog extends StatefulWidget {
  final LabTestModel test;
  final HealthCaseModel healthCase;
  final VoidCallback onSaved;

  const _LabResultEntryDialog({required this.test, required this.healthCase, required this.onSaved});

  @override
  State<_LabResultEntryDialog> createState() => _LabResultEntryDialogState();
}

class _LabResultEntryDialogState extends State<_LabResultEntryDialog> {
  LabResultCategory _category = LabResultCategory.positive;
  final _resultTextCtrl = TextEditingController(text: 'Positive for Newcastle Disease Virus (NDV) Matrix Gene via RT-PCR (Ct value: 21.4). Avian Influenza Negative.');
  final _enteredByCtrl = TextEditingController(text: 'Dr. V. Rao (Senior Microbiologist)');
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final success = await LabTestService.recordResult(
      testId: widget.test.id,
      caseId: widget.healthCase.id,
      result: _category == LabResultCategory.positive ? 'Positive' : (_category == LabResultCategory.negative ? 'Negative' : 'Inconclusive'),
      category: _category,
      notes: _resultTextCtrl.text.trim(),
      enteredBy: _enteredByCtrl.text.trim(),
      assignedVetId: widget.healthCase.assignedVetId,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        widget.onSaved();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Enter Laboratory Diagnostic Findings', style: AppTypography.titleLarge),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LabResultCategory>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Result Classification'),
              items: LabResultCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
              onChanged: (val) => setState(() => _category = val ?? _category),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _resultTextCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Assay Findings & Quantification Notes'),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _enteredByCtrl, decoration: const InputDecoration(labelText: 'Microbiologist / Lab Sign-off')),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                AppButton(label: 'Submit Findings', size: AppButtonSize.small, onPressed: _isSaving ? null : _save),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Veterinarian Result Review Dialog
class _VetResultReviewDialog extends StatefulWidget {
  final LabTestModel test;
  final HealthCaseModel healthCase;
  final VoidCallback onSaved;

  const _VetResultReviewDialog({required this.test, required this.healthCase, required this.onSaved});

  @override
  State<_VetResultReviewDialog> createState() => _VetResultReviewDialogState();
}

class _VetResultReviewDialogState extends State<_VetResultReviewDialog> {
  String _decision = 'confirmed'; // 'confirmed', 'ruled_out', 'provisional', 'inconclusive'
  final _basisCtrl = TextEditingController(text: 'Newcastle Disease (NDV)');
  final _notesCtrl = TextEditingController(text: 'RT-PCR Ct value of 21.4 corroborates observed acute mortality and respiratory clicking in Shed 2. Final diagnosis clinically and diagnostically confirmed.');
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final success = await LabTestService.reviewResultByVet(
      testId: widget.test.id,
      caseId: widget.healthCase.id,
      vetId: widget.healthCase.assignedVetId ?? 'vet_district_01',
      interpretationNotes: _notesCtrl.text.trim(),
      diagnosisDecision: _decision,
      confirmationBasis: _basisCtrl.text.trim(),
      updateCaseDiagnosis: true,
      farmerId: widget.healthCase.farmerId,
      caseNumber: widget.healthCase.caseNumber,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        widget.onSaved();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Veterinary Diagnostic Review & Sign-Off', style: AppTypography.titleLarge),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _decision,
              decoration: const InputDecoration(labelText: 'Clinical Diagnosis Decision'),
              items: const [
                DropdownMenuItem(value: 'confirmed', child: Text('Clinically Confirmed by Lab')),
                DropdownMenuItem(value: 'ruled_out', child: Text('Ruled Out by Negative Lab')),
                DropdownMenuItem(value: 'provisional', child: Text('Keep Provisional / Mixed')),
                DropdownMenuItem(value: 'inconclusive', child: Text('Inconclusive / Repeat Needed')),
              ],
              onChanged: (val) => setState(() => _decision = val ?? _decision),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _basisCtrl, decoration: const InputDecoration(labelText: 'Final Pathogen / Disease Name')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Veterinarian Interpretation & Correlation Notes'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                AppButton(label: 'Publish Official Diagnosis', size: AppButtonSize.small, onPressed: _isSaving ? null : _save),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Repeat Test Dialog
class _RepeatTestDialog extends StatefulWidget {
  final LabTestModel previousTest;
  final HealthCaseModel healthCase;
  final VoidCallback onSaved;

  const _RepeatTestDialog({required this.previousTest, required this.healthCase, required this.onSaved});

  @override
  State<_RepeatTestDialog> createState() => _RepeatTestDialogState();
}

class _RepeatTestDialogState extends State<_RepeatTestDialog> {
  final _reasonCtrl = TextEditingController(text: 'Initial sample inconclusive/rejected. Collecting fresh tracheal swab.');
  bool _isSaving = false;

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    final newTest = LabTestModel(
      id: 'lt_${widget.healthCase.id}_${DateTime.now().millisecondsSinceEpoch}',
      sampleId: LabTestService.generateSampleId(widget.healthCase.caseNumber, 2),
      caseId: widget.healthCase.id,
      farmId: widget.healthCase.farmId,
      batchId: widget.healthCase.flockId,
      sampleType: widget.previousTest.sampleType,
      testRequested: widget.previousTest.testRequested,
      priority: 'urgent',
      requestedBy: 'Dr. Attending Veterinarian',
      requestedAt: DateTime.now(),
      status: LabTestStatus.requested,
      collectionNotes: _reasonCtrl.text.trim(),
    );

    final success = await LabTestService.requestRepeatTest(
      previousTestId: widget.previousTest.id,
      newTest: newTest,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        widget.onSaved();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Request Repeat Diagnostic Test', style: AppTypography.titleLarge),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Clinical Reason for Repeat Testing'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                AppButton(label: 'Order Repeat Sample', size: AppButtonSize.small, onPressed: _isSaving ? null : _submit),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
