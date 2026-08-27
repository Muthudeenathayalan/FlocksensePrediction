import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/platform/file_upload_service.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/health/data/health_service.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';

class UploadedEvidenceItem {
  final String name;
  final int sizeBytes;
  final Uint8List bytes;
  String? downloadUrl;
  bool isUploading;
  String? error;

  UploadedEvidenceItem({
    required this.name,
    required this.sizeBytes,
    required this.bytes,
    this.downloadUrl,
    this.isUploading = false,
    this.error,
  });
}

/// 5-Step Guided Health Incident Reporting Modal Wizard (SIH26128)
class ReportHealthIssueWizardModal extends StatefulWidget {
  final String? initialFarmId;
  final String? initialFarmName;
  final String? initialFlockId;
  final String? initialFlockName;
  final VoidCallback? onCaseSubmitted;

  const ReportHealthIssueWizardModal({
    super.key,
    this.initialFarmId,
    this.initialFarmName,
    this.initialFlockId,
    this.initialFlockName,
    this.onCaseSubmitted,
  });

  @override
  State<ReportHealthIssueWizardModal> createState() =>
      _ReportHealthIssueWizardModalState();
}

class _ReportHealthIssueWizardModalState
    extends State<ReportHealthIssueWizardModal> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Farms & Flocks
  List<FarmModel> _farms = [];
  List<BatchModel> _flocks = [];
  bool _loadingFarms = true;
  bool _loadingFlocks = false;

  FarmModel? _selectedFarm;
  BatchModel? _selectedFlock;

  // Step 1: Incident Numbers
  final _affectedController = TextEditingController();
  final _mortalityController = TextEditingController(text: '0');
  DateTime _dateObserved = DateTime.now();

  // Step 2: Symptoms
  final Set<String> _selectedSymptoms = {};
  final List<String> _availableSymptoms = [
    'Coughing',
    'Sneezing',
    'Respiratory Difficulty',
    'Weakness',
    'Diarrhoea',
    'Reduced Appetite',
    'Swelling (Head/Comb)',
    'Skin Lesions',
    'Neurological Signs',
    'Nasal Discharge',
    'Eye Swelling',
    'Reduced Activity',
    'Sudden Death',
  ];
  final _customSymptomController = TextEditingController();

  // Step 3: Vitals & Farm Telemetry
  final _feedDropController = TextEditingController();
  final _waterDropController = TextEditingController();
  final _tempController = TextEditingController();
  final _humidityController = TextEditingController();
  String _activityChange = 'Normal';
  String _vaccineConcern = 'Up to date';

  // Step 4: Evidence & Notes
  final List<UploadedEvidenceItem> _evidenceList = [];
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Submission State
  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    _loadFarmerFarms();
  }

  @override
  void dispose() {
    _affectedController.dispose();
    _mortalityController.dispose();
    _customSymptomController.dispose();
    _feedDropController.dispose();
    _waterDropController.dispose();
    _tempController.dispose();
    _humidityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadFarmerFarms() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loadingFarms = false);
      return;
    }

    try {
      final farms = await FarmService.getUserFarms();
      if (mounted) {
        setState(() {
          _farms = farms;
          _loadingFarms = false;

          // Preselect if provided
          if (widget.initialFarmId != null && _farms.isNotEmpty) {
            _selectedFarm = _farms.firstWhere(
              (f) => f.id == widget.initialFarmId,
              orElse: () => _farms.first,
            );
          } else if (_farms.isNotEmpty) {
            _selectedFarm = _farms.first;
          }
        });

        if (_selectedFarm != null) {
          _loadFlocksForFarm(_selectedFarm!.id);
        }
      }
    } catch (e) {
      debugPrint('[ReportHealthWizard] Error loading farms: $e');
      if (mounted) setState(() => _loadingFarms = false);
    }
  }

  Future<void> _loadFlocksForFarm(String farmId) async {
    setState(() => _loadingFlocks = true);
    try {
      final batches = await BatchService.getBatchesByFarmId(farmId);
      if (mounted) {
        setState(() {
          _flocks = batches;
          _loadingFlocks = false;

          if (widget.initialFlockId != null && _flocks.isNotEmpty) {
            _selectedFlock = _flocks.firstWhere(
              (b) => b.id == widget.initialFlockId,
              orElse: () => _flocks.first,
            );
          } else if (_flocks.isNotEmpty) {
            _selectedFlock = _flocks.first;
          } else {
            _selectedFlock = null;
          }
        });
      }
    } catch (e) {
      debugPrint('[ReportHealthWizard] Error loading batches: $e');
      if (mounted) setState(() => _loadingFlocks = false);
    }
  }

  Future<void> _pickImageEvidence() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > 10 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size exceeds maximum 10MB limit.')),
        );
        return;
      }

      final item = UploadedEvidenceItem(
        name: picked.name,
        sizeBytes: bytes.lengthInBytes,
        bytes: bytes,
      );

      setState(() {
        _evidenceList.add(item);
      });
    } catch (e) {
      debugPrint('[ReportHealthWizard] Error picking image: $e');
    }
  }

  void _removeEvidence(int index) {
    setState(() {
      _evidenceList.removeAt(index);
    });
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (_selectedFarm == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an active farm.')),
        );
        return false;
      }
      if (_selectedFlock == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an active flock/batch.')),
        );
        return false;
      }
      final affected = int.tryParse(_affectedController.text.trim()) ?? 0;
      if (affected <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid affected animals count (> 0).')),
        );
        return false;
      }
      final mortality = int.tryParse(_mortalityController.text.trim()) ?? 0;
      if (mortality < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mortality count cannot be negative.')),
        );
        return false;
      }
      return true;
    } else if (step == 1) {
      if (_selectedSymptoms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one observed symptom.')),
        );
        return false;
      }
      return true;
    }
    return true;
  }

  Future<void> _submitHealthReport() async {
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final farmId = _selectedFarm?.id ?? 'farm_01';
      final farmName = _selectedFarm?.farmName ?? widget.initialFarmName ?? 'Primary Facility';
      final flockId = _selectedFlock?.id ?? 'batch_01';
      final flockName = _selectedFlock?.batchName ?? widget.initialFlockName ?? 'Flock';

      final affected = int.tryParse(_affectedController.text.trim()) ?? 1;
      final mortality = int.tryParse(_mortalityController.text.trim()) ?? 0;
      final feedDrop = double.tryParse(_feedDropController.text.trim());
      final waterDrop = double.tryParse(_waterDropController.text.trim());
      final temp = double.tryParse(_tempController.text.trim());
      final hum = double.tryParse(_humidityController.text.trim());

      // 1. Upload evidence images to Firebase Storage
      final List<String> imageUrls = [];
      for (final ev in _evidenceList) {
        try {
          ev.isUploading = true;
          final downloadUrl = await FileUploadService.uploadBytes(
            bytes: ev.bytes,
            fileName: ev.name,
            pathPrefix: 'health_evidence',
          );
          ev.downloadUrl = downloadUrl;
          imageUrls.add(downloadUrl);
        } catch (e) {
          debugPrint('[ReportHealthWizard] Error uploading image ${ev.name}: $e');
        }
      }

      // 2. Build deterministic incident key
      final incidentKey = HealthService.generateIncidentKey(farmId, flockId, _dateObserved);

      // 3. Construct Health Case
      final caseNumber = 'HC-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final newCase = HealthCaseModel(
        id: '',
        caseNumber: caseNumber,
        farmId: farmId,
        farmName: farmName,
        flockId: flockId,
        flockName: flockName,
        farmerId: user?.uid,
        affectedCount: affected,
        mortalityCount: mortality,
        symptoms: _selectedSymptoms.toList(),
        notes: _notesController.text.trim(),
        imageUrls: imageUrls,
        feedReductionPercent: feedDrop,
        waterReductionPercent: waterDrop,
        temperature: temp,
        humidity: hum,
        riskScore: 0, // Phase 2: Pending assessment, no fake AI risk
        riskLevel: HealthRiskLevel.low,
        status: HealthCaseStatus.reported,
        incidentKey: incidentKey,
        reportedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final saved = await HealthService.createOrUpdateHealthCase(newCase);

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context); // Close wizard

        widget.onCaseSubmitted?.call();

        // Show confirmation modal
        _showSuccessConfirmation(saved);
      }
    } catch (e) {
      debugPrint('[ReportHealthWizard] Submission error: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submissionError = 'Failed to submit report. Please check connection and retry.';
        });
      }
    }
  }

  void _showSuccessConfirmation(HealthCaseModel savedCase) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AppColors.healthy, size: 28),
            SizedBox(width: 10),
            Text('Health Incident Reported', style: AppTypography.cardTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your report has been saved to Firebase Firestore and logged in the official surveillance register.', style: AppTypography.bodySmall),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  AppDesign.infoRow('Case Reference', savedCase.caseNumber),
                  const SizedBox(height: 6),
                  AppDesign.infoRow('Facility', savedCase.farmName),
                  const SizedBox(height: 6),
                  AppDesign.infoRow('Flock / Batch', savedCase.flockName),
                  const SizedBox(height: 6),
                  AppDesign.infoRow('Status', 'Reported (Ready for Clinical Assessment)'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          AppButton(
            label: 'Close',
            size: AppButtonSize.small,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: Container(
        padding: const EdgeInsets.all(28),
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Health Issue • Step ${_currentStep + 1} of 5',
                        style: AppTypography.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getStepSubtitle(_currentStep),
                        style: AppTypography.metadata,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress Bar
              LinearProgressIndicator(
                value: (_currentStep + 1) / 5,
                backgroundColor: AppColors.slate100,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
              const SizedBox(height: 24),

              if (_submissionError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.criticalBg,
                      borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                      border: Border.all(color: AppColors.critical.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.critical, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_submissionError!, style: const TextStyle(color: AppColors.critical, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Step Content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildCurrentStepWidget(),
              ),

              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 16),

              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    AppButton(
                      label: 'Back',
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.small,
                      onPressed: _isSubmitting ? null : () => setState(() => _currentStep--),
                    )
                  else
                    const SizedBox.shrink(),
                  AppButton(
                    label: _currentStep == 4 ? 'Submit Health Report' : 'Continue Next',
                    icon: _currentStep == 4 ? Icons.send_rounded : Icons.arrow_forward_rounded,
                    size: AppButtonSize.small,
                    isLoading: _isSubmitting,
                    onPressed: () {
                      if (_validateStep(_currentStep)) {
                        if (_currentStep < 4) {
                          setState(() => _currentStep++);
                        } else {
                          _submitHealthReport();
                        }
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

  String _getStepSubtitle(int step) {
    switch (step) {
      case 0:
        return 'Select affected farm facility, flock batch, and initial bird count';
      case 1:
        return 'Select all observed clinical symptoms and anomalous behaviors';
      case 2:
        return 'Record feed, water, ambient vital changes and immunization status';
      case 3:
        return 'Upload photographic evidence or diagnostic images (Max 10MB)';
      case 4:
        return 'Review report details before final submission to surveillance database';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case 0:
        return _buildStep1FarmFlock();
      case 1:
        return _buildStep2Symptoms();
      case 2:
        return _buildStep3Vitals();
      case 3:
        return _buildStep4Evidence();
      case 4:
        return _buildStep5Review();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1FarmFlock() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Farm Selector
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Farm Facility *', style: AppTypography.metadata),
                  const SizedBox(height: 6),
                  if (_loadingFarms)
                    const LinearProgressIndicator()
                  else
                    DropdownButtonFormField<FarmModel>(
                      value: _selectedFarm,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _farms.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text('${f.farmName} (${f.district ?? "Facility"})', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedFarm = val);
                          _loadFlocksForFarm(val.id);
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Flock Selector
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Flock / Batch *', style: AppTypography.metadata),
                  const SizedBox(height: 6),
                  if (_loadingFlocks)
                    const LinearProgressIndicator()
                  else
                    DropdownButtonFormField<BatchModel>(
                      value: _selectedFlock,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _flocks.map((b) {
                        return DropdownMenuItem(
                          value: b,
                          child: Text('${b.batchName} (${b.currentBirds} birds)', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedFlock = val),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            // Affected Count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Birds / Animals Affected *', style: AppTypography.metadata),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _affectedController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 18',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Mortality Count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mortality Count Today', style: AppTypography.metadata),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _mortalityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 2',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Date Observed
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dateObserved,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _dateObserved = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Date First Observed: ${DateFormat('dd MMM yyyy').format(_dateObserved)}', style: AppTypography.bodySmall),
                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.slate500),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2Symptoms() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select all observed clinical symptoms:', style: AppTypography.sectionTitle),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableSymptoms.map((sym) {
            final isSelected = _selectedSymptoms.contains(sym);
            return FilterChip(
              label: Text(sym),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedSymptoms.add(sym);
                  } else {
                    _selectedSymptoms.remove(sym);
                  }
                });
              },
              selectedColor: AppColors.primaryLight,
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primaryDark : AppColors.slate700,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Custom Symptom Input
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _customSymptomController,
                decoration: const InputDecoration(
                  hintText: 'Add custom observed symptom...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AppButton(
              label: 'Add',
              icon: Icons.add_rounded,
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.small,
              onPressed: () {
                final txt = _customSymptomController.text.trim();
                if (txt.isNotEmpty) {
                  setState(() {
                    if (!_availableSymptoms.contains(txt)) {
                      _availableSymptoms.add(txt);
                    }
                    _selectedSymptoms.add(txt);
                    _customSymptomController.clear();
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3Vitals() {
    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Feed Intake Reduction (%)', style: AppTypography.metadata),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _feedDropController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 18',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  const Text('Water Intake Reduction (%)', style: AppTypography.metadata),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _waterDropController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 12',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Shed Temperature (°C)', style: AppTypography.metadata),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _tempController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 31.5',
                      suffixText: '°C',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  const Text('Shed Humidity (%)', style: AppTypography.metadata),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _humidityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 68',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Activity & Behavior', style: AppTypography.metadata),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _activityChange,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Normal', child: Text('Normal Activity')),
                      DropdownMenuItem(value: 'Mild Lethargy', child: Text('Mild Lethargy')),
                      DropdownMenuItem(value: 'Severe Prostration', child: Text('Severe Inactivity / Prostration')),
                    ],
                    onChanged: (val) => setState(() => _activityChange = val ?? 'Normal'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vaccination Schedule Status', style: AppTypography.metadata),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _vaccineConcern,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Up to date', child: Text('Up to date')),
                      DropdownMenuItem(value: 'Booster Overdue', child: Text('Booster Overdue')),
                      DropdownMenuItem(value: 'Unknown', child: Text('Unknown / Not tracked')),
                    ],
                    onChanged: (val) => setState(() => _vaccineConcern = val ?? 'Up to date'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep4Evidence() {
    return Column(
      key: const ValueKey('step4'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Upload Diagnostic Images / Evidence (Max 10MB)', style: AppTypography.sectionTitle),
            AppButton(
              label: 'Select Image',
              icon: Icons.add_photo_alternate_rounded,
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.small,
              onPressed: _pickImageEvidence,
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_evidenceList.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(AppDesign.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: const [
                Icon(Icons.photo_library_outlined, size: 36, color: AppColors.slate400),
                SizedBox(height: 8),
                Text('No diagnostic images attached.', style: AppTypography.metadata),
                SizedBox(height: 4),
                Text('Attaching lesion, swab, or bird images helps duty vets conduct triage faster.', style: TextStyle(fontSize: 11.5, color: AppColors.slate500)),
              ],
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _evidenceList.asMap().entries.map((entry) {
              final idx = entry.key;
              final ev = entry.value;
              return Container(
                width: 140,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.memory(
                        ev.bytes,
                        height: 80,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ev.name,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${(ev.sizeBytes / 1024).toStringAsFixed(0)} KB',
                      style: AppTypography.metadata,
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _removeEvidence(idx),
                      child: const Text('Remove', style: TextStyle(fontSize: 11, color: AppColors.critical, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 16),
        const Text('Additional Clinical Observations / Farmer Notes', style: AppTypography.metadata),
        const SizedBox(height: 6),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Describe sudden behavioral changes, weather events, or feeding anomalies...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildStep5Review() {
    return Column(
      key: const ValueKey('step5'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Health Incident Summary', style: AppTypography.sectionTitle),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(AppDesign.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              AppDesign.infoRow('Facility', _selectedFarm?.farmName ?? 'Primary Facility'),
              const SizedBox(height: 6),
              AppDesign.infoRow('Flock / Batch', _selectedFlock?.batchName ?? 'Flock'),
              const SizedBox(height: 6),
              AppDesign.infoRow('Birds Affected', '${_affectedController.text.trim()} birds'),
              const SizedBox(height: 6),
              AppDesign.infoRow('Mortality Count', '${_mortalityController.text.trim()} birds'),
              const SizedBox(height: 6),
              AppDesign.infoRow('Observed Symptoms', _selectedSymptoms.join(', ')),
              if (_feedDropController.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                AppDesign.infoRow('Feed Intake Drop', '${_feedDropController.text.trim()}%'),
              ],
              if (_waterDropController.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                AppDesign.infoRow('Water Intake Drop', '${_waterDropController.text.trim()}%'),
              ],
              if (_evidenceList.isNotEmpty) ...[
                const SizedBox(height: 6),
                AppDesign.infoRow('Attached Evidence', '${_evidenceList.length} image(s)'),
              ],
              if (_notesController.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                AppDesign.infoRow('Notes', _notesController.text.trim()),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'ℹ️ On submission, this case will be recorded in the official surveillance register and made available for clinical assessment.',
          style: TextStyle(fontSize: 12, color: AppColors.slate600, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
