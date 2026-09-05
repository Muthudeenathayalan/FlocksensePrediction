import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/sheds/data/shed_service.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';

class ShedFormScreen extends StatefulWidget {
  const ShedFormScreen({super.key, required this.farmId, this.existing});
  final String farmId;
  final ShedModel? existing;

  @override
  State<ShedFormScreen> createState() => _ShedFormScreenState();
}

class _ShedFormScreenState extends State<ShedFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _length;
  late final TextEditingController _width;
  late final TextEditingController _capacity;
  late final TextEditingController _notes;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _length = TextEditingController(
      text: s != null ? s.lengthFt.toString() : '',
    );
    _width = TextEditingController(text: s != null ? s.widthFt.toString() : '');
    _capacity = TextEditingController(text: s?.capacity?.toString() ?? '');
    _notes = TextEditingController(text: s?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _length.dispose();
    _width.dispose();
    _capacity.dispose();
    _notes.dispose();
    super.dispose();
  }

  double _parseDouble(String value) => double.tryParse(value.trim()) ?? 0.0;

  int? _parseInt(String value) =>
      value.trim().isEmpty ? null : int.tryParse(value.trim());

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      final lengthFt = _parseDouble(_length.text);
      final widthFt = _parseDouble(_width.text);
      final capacity = _parseInt(_capacity.text);
      final notes = _notes.text.trim().isNotEmpty ? _notes.text.trim() : null;

      if (_isEdit) {
        await ShedService.updateShed(widget.farmId, widget.existing!.id, {
          'name': name,
          'shedName': name,
          'lengthFt': lengthFt,
          'widthFt': widthFt,
          'totalSqFt': lengthFt * widthFt,
          'capacity': capacity,
          'notes': notes,
        });
      } else {
        await ShedService.createShed(
          farmId: widget.farmId,
          name: name,
          lengthFt: lengthFt,
          widthFt: widthFt,
          capacity: capacity,
          notes: notes,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Shed' : 'New Shed Unit',
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
              // 1. Header
              WebPageHeader(
                title: _isEdit ? 'Edit Shed Configuration' : 'Register New Shed',
                subtitle:
                    'Configure structural dimensions, total square footage, and bird stocking capacity.',
                breadcrumb: 'Farms / Sheds / ${_isEdit ? "Edit" : "New"}',
              ),

              // 2. Primary Details Card
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppDesign.sectionTitle('Shed Identification & Dimensions'),
                    const SizedBox(height: 12),
                    _field(
                      _name,
                      'Shed Name / Identifier (e.g. Shed 1 - North)',
                      icon: Icons.home_work_outlined,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            _length,
                            'Length (feet)',
                            icon: Icons.straighten_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            required: true,
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final value = double.tryParse(v ?? '');
                              if (value == null || value <= 0) {
                                return 'Enter valid length';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _field(
                            _width,
                            'Width (feet)',
                            icon: Icons.straighten_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            required: true,
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final value = double.tryParse(v ?? '');
                              if (value == null || value <= 0) {
                                return 'Enter valid width';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _field(
                      _capacity,
                      'Physical Bird Capacity',
                      icon: Icons.pets_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      _notes,
                      'Operational Notes / Equipment Details',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    _buildCalculatedAreaBadge(),
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
                    label: _isEdit ? 'Update Shed' : 'Save & Register Shed',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: _saving,
                    onPressed: _saving ? null : _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatedAreaBadge() {
    final lengthFt = double.tryParse(_length.text.trim()) ?? 0.0;
    final widthFt = double.tryParse(_width.text.trim()) ?? 0.0;
    final totalSqFt = lengthFt > 0 && widthFt > 0 ? (lengthFt * widthFt) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
            ),
            child: const Icon(Icons.square_foot_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calculated Floor Space',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  totalSqFt > 0
                      ? '${lengthFt.toStringAsFixed(1)} ft × ${widthFt.toStringAsFixed(1)} ft  =  ${totalSqFt.toStringAsFixed(1)} sq.ft'
                      : 'Enter length and width above to calculate total area',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: totalSqFt > 0
                        ? AppColors.slate800
                        : AppColors.slate400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    IconData? icon,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
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
