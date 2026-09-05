import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/weight/data/weight_record_service.dart';
import 'package:flock_sense/features/weight/domain/weight_record_model.dart';

class WeightRecordFormScreen extends StatefulWidget {
  const WeightRecordFormScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    this.existingRecord,
  });

  final String farmId;
  final String batchId;
  final WeightRecordModel? existingRecord;

  @override
  State<WeightRecordFormScreen> createState() => _WeightRecordFormScreenState();
}

class _WeightRecordFormScreenState extends State<WeightRecordFormScreen> {
  late DateTime _recordDate;
  late TextEditingController _weightController;
  late TextEditingController _sampleCountController;
  late TextEditingController _notesController;
  late String _selectedUnit;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    final record = widget.existingRecord;
    _recordDate = record?.recordDate ?? DateTime.now();
    _selectedUnit = record?.unit ?? 'grams';
    _weightController = TextEditingController(
      text: record != null ? record.averageWeight.toString() : '',
    );
    _sampleCountController = TextEditingController(
      text: record?.sampleCount?.toString() ?? '',
    );
    _notesController = TextEditingController(text: record?.notes ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _sampleCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _recordDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final weight = double.parse(_weightController.text.trim());
      final sampleCount = _sampleCountController.text.trim().isEmpty
          ? null
          : int.parse(_sampleCountController.text.trim());

      await WeightRecordService.createOrUpdateWeightRecord(
        farmId: widget.farmId,
        batchId: widget.batchId,
        recordDate: _recordDate,
        averageWeight: weight,
        unit: _selectedUnit,
        sampleCount: sampleCount,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save weight record: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Weight Sample' : 'Log Weight Sample',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageContainer(
        maxWidth: AppDesign.maxFormWidth,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Web Page Header
              WebPageHeader(
                title: _isEdit ? 'Edit Weight Sampling' : 'Record Flock Weight Sampling',
                subtitle:
                    'Log sample bird weights to assess Average Daily Gain (ADG), uniformity index, and growth standard variance.',
                breadcrumb: 'Batches / Weight Records / ${_isEdit ? "Edit" : "New Sample"}',
              ),

              // 2. Main Form Card
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppDesign.sectionTitle('Sampling Parameters'),
                    const SizedBox(height: 12),

                    // Date Picker Input
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 18, color: AppColors.slate400),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Sampling Date',
                                        style: TextStyle(fontSize: 11, color: AppColors.slate500)),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('dd MMMM yyyy').format(_recordDate),
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.slate800),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Icon(Icons.edit_calendar_rounded,
                                color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Weight Input and Unit Toggle
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _textField(
                            _weightController,
                            'Average Weight per Bird',
                            icon: Icons.fitness_center_rounded,
                            required: true,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Weight is required';
                              }
                              final weight = double.tryParse(value.trim());
                              if (weight == null || weight <= 0) {
                                return 'Enter a valid weight > 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.slate100,
                                  borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedUnit,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(value: 'grams', child: Text('Grams (g)')),
                                      DropdownMenuItem(value: 'kilograms', child: Text('Kilograms (kg)')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedUnit = val);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _textField(
                      _sampleCountController,
                      'Number of Sampled Birds (e.g. 50 birds)',
                      icon: Icons.pets_outlined,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    _textField(
                      _notesController,
                      'Sampling Observations / Breed Standard Notes',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: _isEdit ? 'Update Sample' : 'Save Sample Weight',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController c,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: AppColors.slate900),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.slate400) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      validator: validator ??
          (required
              ? (v) => (v?.trim().isEmpty ?? true) ? 'This field is required' : null
              : null),
    );
  }
}
