import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/health/data/prevention_engine.dart';
import 'package:flock_sense/features/health/data/prevention_service.dart';
import 'package:flock_sense/features/health/domain/biosecurity_assessment_model.dart';

/// Modal questionnaire for Farmer Biosecurity Assessment & Audit (SIH26128 Phase 10)
class FarmBiosecurityAssessmentModal extends StatefulWidget {
  final String farmId;
  final String farmName;
  final BiosecurityAssessmentModel? initialAssessment;
  final VoidCallback? onAssessmentSaved;

  const FarmBiosecurityAssessmentModal({
    super.key,
    required this.farmId,
    this.farmName = 'Green Valley Poultry Farm',
    this.initialAssessment,
    this.onAssessmentSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required String farmId,
    String farmName = 'Green Valley Poultry Farm',
    BiosecurityAssessmentModel? initialAssessment,
    VoidCallback? onAssessmentSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FarmBiosecurityAssessmentModal(
        farmId: farmId,
        farmName: farmName,
        initialAssessment: initialAssessment,
        onAssessmentSaved: onAssessmentSaved,
      ),
    );
  }

  @override
  State<FarmBiosecurityAssessmentModal> createState() => _FarmBiosecurityAssessmentModalState();
}

class _FarmBiosecurityAssessmentModalState extends State<FarmBiosecurityAssessmentModal> {
  late BiosecurityAnswer _visitorLog;
  late BiosecurityAnswer _restrictedEntry;
  late BiosecurityAnswer _footwearDisinfection;
  late BiosecurityAnswer _vehicleDisinfection;
  late BiosecurityAnswer _protectiveClothing;

  late BiosecurityAnswer _isolationArea;
  late BiosecurityAnswer _sickBirdsIsolated;
  late BiosecurityAnswer _newQuarantine;
  late BiosecurityAnswer _ageSeparated;

  late BiosecurityAnswer _routineCleaning;
  late BiosecurityAnswer _equipmentDisinfection;
  late BiosecurityAnswer _feederDrinkerClean;
  late BiosecurityAnswer _sharedEquipment;

  late BiosecurityAnswer _cleanWater;
  late BiosecurityAnswer _waterSanitation;
  late BiosecurityAnswer _feedPestProtected;
  late BiosecurityAnswer _feedStorageDry;

  late BiosecurityAnswer _carcassDisposal;
  late BiosecurityAnswer _wasteDisposal;
  late BiosecurityAnswer _litterManagement;

  late BiosecurityAnswer _vaxRecords;
  late BiosecurityAnswer _vaxUpToDate;
  late BiosecurityAnswer _dailyMonitoring;
  late BiosecurityAnswer _vetContact;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialAssessment;
    _visitorLog = init?.visitorLogMaintained ?? BiosecurityAnswer.yes;
    _restrictedEntry = init?.restrictedEntry ?? BiosecurityAnswer.yes;
    _footwearDisinfection = init?.footwearDisinfection ?? BiosecurityAnswer.no;
    _vehicleDisinfection = init?.vehicleDisinfection ?? BiosecurityAnswer.partial;
    _protectiveClothing = init?.protectiveClothing ?? BiosecurityAnswer.partial;

    _isolationArea = init?.isolationAreaAvailable ?? BiosecurityAnswer.no;
    _sickBirdsIsolated = init?.sickAnimalsIsolated ?? BiosecurityAnswer.no;
    _newQuarantine = init?.newAnimalsQuarantined ?? BiosecurityAnswer.yes;
    _ageSeparated = init?.ageGroupsSeparated ?? BiosecurityAnswer.yes;

    _routineCleaning = init?.routineShedCleaning ?? BiosecurityAnswer.yes;
    _equipmentDisinfection = init?.equipmentDisinfection ?? BiosecurityAnswer.partial;
    _feederDrinkerClean = init?.feederDrinkerCleaning ?? BiosecurityAnswer.yes;
    _sharedEquipment = init?.sharedEquipmentControl ?? BiosecurityAnswer.no;

    _cleanWater = init?.cleanWaterSource ?? BiosecurityAnswer.yes;
    _waterSanitation = init?.waterSanitation ?? BiosecurityAnswer.no;
    _feedPestProtected = init?.feedContaminationProtection ?? BiosecurityAnswer.yes;
    _feedStorageDry = init?.feedStorageHygiene ?? BiosecurityAnswer.yes;

    _carcassDisposal = init?.safeCarcassDisposal ?? BiosecurityAnswer.no;
    _wasteDisposal = init?.wasteDisposal ?? BiosecurityAnswer.partial;
    _litterManagement = init?.litterManureManagement ?? BiosecurityAnswer.yes;

    _vaxRecords = init?.vaccinationRecordsMaintained ?? BiosecurityAnswer.yes;
    _vaxUpToDate = init?.vaccinationUpToDate ?? BiosecurityAnswer.no;
    _dailyMonitoring = init?.regularHealthMonitoring ?? BiosecurityAnswer.yes;
    _vetContact = init?.veterinaryContactAvailable ?? BiosecurityAnswer.yes;
  }

  BiosecurityAssessmentModel _calculateCurrentPreview() {
    return PreventionEngine.evaluateBiosecurity(
      farmId: widget.farmId,
      farmName: widget.farmName,
      visitorLogMaintained: _visitorLog,
      restrictedEntry: _restrictedEntry,
      footwearDisinfection: _footwearDisinfection,
      vehicleDisinfection: _vehicleDisinfection,
      protectiveClothing: _protectiveClothing,
      isolationAreaAvailable: _isolationArea,
      sickAnimalsIsolated: _sickBirdsIsolated,
      newAnimalsQuarantined: _newQuarantine,
      ageGroupsSeparated: _ageSeparated,
      routineShedCleaning: _routineCleaning,
      equipmentDisinfection: _equipmentDisinfection,
      feederDrinkerCleaning: _feederDrinkerClean,
      sharedEquipmentControl: _sharedEquipment,
      cleanWaterSource: _cleanWater,
      waterSanitation: _waterSanitation,
      feedContaminationProtection: _feedPestProtected,
      feedStorageHygiene: _feedStorageDry,
      safeCarcassDisposal: _carcassDisposal,
      wasteDisposal: _wasteDisposal,
      litterManureManagement: _litterManagement,
      vaccinationRecordsMaintained: _vaxRecords,
      vaccinationUpToDate: _vaxUpToDate,
      regularHealthMonitoring: _dailyMonitoring,
      veterinaryContactAvailable: _vetContact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _calculateCurrentPreview();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 760,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Farm Biosecurity & Disease Prevention Audit',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${widget.farmName} • Standardized Epidemiological Self-Assessment',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Live Score Preview Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStrengthColor(preview.strength).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _getStrengthColor(preview.strength)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${preview.score} / 100',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _getStrengthColor(preview.strength),
                        ),
                      ),
                      Text(
                        preview.strength.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _getStrengthColor(preview.strength),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Scrollable Questionnaire Sections
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('1. Entry & Visitor Control', Icons.door_front_door_outlined),
                    _buildQuestionItem('Visitor registry log maintained at farm perimeter', _visitorLog, (v) => setState(() => _visitorLog = v)),
                    _buildQuestionItem('Restricted entry (authorized attendants only)', _restrictedEntry, (v) => setState(() => _restrictedEntry = v)),
                    _buildQuestionItem('Disinfectant footbaths installed and active at shed doorways', _footwearDisinfection, (v) => setState(() => _footwearDisinfection = v)),
                    _buildQuestionItem('Vehicle wheel spray/dip at farm entrance', _vehicleDisinfection, (v) => setState(() => _vehicleDisinfection = v)),
                    _buildQuestionItem('Dedicated protective boots/overalls worn inside sheds', _protectiveClothing, (v) => setState(() => _protectiveClothing = v)),
                    const SizedBox(height: 16),

                    _buildSectionHeader('2. Animal & Flock Separation', Icons.fence_outlined),
                    _buildQuestionItem('Dedicated sick-bird isolation pen physically separated from main sheds', _isolationArea, (v) => setState(() => _isolationArea = v)),
                    _buildQuestionItem('Symptomatic birds promptly segregated upon detection', _sickBirdsIsolated, (v) => setState(() => _sickBirdsIsolated = v)),
                    _buildQuestionItem('14-day quarantine observed for newly introduced stock', _newQuarantine, (v) => setState(() => _newQuarantine = v)),
                    _buildQuestionItem('Strict age-group separation (all-in / all-out management)', _ageSeparated, (v) => setState(() => _ageSeparated = v)),
                    const SizedBox(height: 16),

                    _buildSectionHeader('3. Cleaning & Disinfection', Icons.cleaning_services_outlined),
                    _buildQuestionItem('Terminal shed washout and disinfection between batch cycles', _routineCleaning, (v) => setState(() => _routineCleaning = v)),
                    _buildQuestionItem('Transport crates, egg trays, and tools sanitized after each use', _equipmentDisinfection, (v) => setState(() => _equipmentDisinfection = v)),
                    _buildQuestionItem('Drinkers and feeders flushed/cleaned on weekly schedule', _feederDrinkerClean, (v) => setState(() => _feederDrinkerClean = v)),
                    _buildQuestionItem('No unwashed tool/equipment sharing with neighboring farms', _sharedEquipment, (v) => setState(() => _sharedEquipment = v)),
                    const SizedBox(height: 16),

                    _buildSectionHeader('4. Water & Feed Safety', Icons.water_drop_outlined),
                    _buildQuestionItem('Safe water source (deep borewell / treated municipal supply)', _cleanWater, (v) => setState(() => _cleanWater = v)),
                    _buildQuestionItem('Active water sanitization (chlorine / peroxide dosing 2-3 ppm)', _waterSanitation, (v) => setState(() => _waterSanitation = v)),
                    _buildQuestionItem('Feed storage sealed against wild birds and rodents', _feedPestProtected, (v) => setState(() => _feedPestProtected = v)),
                    _buildQuestionItem('Feed bags stored on pallets in dry, ventilated space', _feedStorageDry, (v) => setState(() => _feedStorageDry = v)),
                    const SizedBox(height: 16),

                    _buildSectionHeader('5. Mortality & Waste Management', Icons.delete_outline),
                    _buildQuestionItem('Safe carcass disposal (sealed deep burial with lime / incineration)', _carcassDisposal, (v) => setState(() => _carcassDisposal = v)),
                    _buildQuestionItem('Manure/spent litter composted downwind away from shed air inlets', _wasteDisposal, (v) => setState(() => _wasteDisposal = v)),
                    _buildQuestionItem('Litter managed dry and friable (<25% moisture)', _litterManagement, (v) => setState(() => _litterManagement = v)),
                    const SizedBox(height: 16),

                    _buildSectionHeader('6. Vaccination & Health Management', Icons.vaccines_outlined),
                    _buildQuestionItem('Vaccination log maintained with batch numbers and dates', _vaxRecords, (v) => setState(() => _vaxRecords = v)),
                    _buildQuestionItem('Flock vaccinations up to date per state schedule', _vaxUpToDate, (v) => setState(() => _vaxUpToDate = v)),
                    _buildQuestionItem('Daily mortality and feed/water consumption recorded', _dailyMonitoring, (v) => setState(() => _dailyMonitoring = v)),
                    _buildQuestionItem('Registered poultry veterinarian on retainer / emergency contact', _vetContact, (v) => setState(() => _vetContact = v)),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),

            // Footer Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${preview.riskFactors.length} biosecurity gaps identified',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitAssessment,
                      icon: _isSubmitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Save & Update Biosecurity Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(String question, BiosecurityAnswer currentAnswer, ValueChanged<BiosecurityAnswer> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              question,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          _buildAnswerRadio('Yes', BiosecurityAnswer.yes, currentAnswer, onChanged),
          const SizedBox(width: 6),
          _buildAnswerRadio('Partial', BiosecurityAnswer.partial, currentAnswer, onChanged),
          const SizedBox(width: 6),
          _buildAnswerRadio('No', BiosecurityAnswer.no, currentAnswer, onChanged),
        ],
      ),
    );
  }

  Widget _buildAnswerRadio(
    String label,
    BiosecurityAnswer value,
    BiosecurityAnswer groupValue,
    ValueChanged<BiosecurityAnswer> onChanged,
  ) {
    final isSelected = value == groupValue;
    Color activeColor;
    switch (value) {
      case BiosecurityAnswer.yes:
        activeColor = AppColors.success;
        break;
      case BiosecurityAnswer.partial:
        activeColor = AppColors.warning;
        break;
      case BiosecurityAnswer.no:
        activeColor = AppColors.critical;
        break;
      case BiosecurityAnswer.na:
        activeColor = AppColors.textSecondary;
        break;
    }

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Color _getStrengthColor(BiosecurityStrength strength) {
    switch (strength) {
      case BiosecurityStrength.strong:
        return AppColors.success;
      case BiosecurityStrength.good:
        return AppColors.info;
      case BiosecurityStrength.needs_improvement:
        return AppColors.warning;
      case BiosecurityStrength.high_vulnerability:
        return AppColors.critical;
    }
  }

  Future<void> _submitAssessment() async {
    setState(() => _isSubmitting = true);
    final assessment = _calculateCurrentPreview();
    await PreventionService.saveAssessment(assessment);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.pop(context);
    widget.onAssessmentSaved?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Biosecurity assessment updated! Score: ${assessment.score}/100 (${assessment.strength.label})'),
        backgroundColor: _getStrengthColor(assessment.strength),
      ),
    );
  }
}
