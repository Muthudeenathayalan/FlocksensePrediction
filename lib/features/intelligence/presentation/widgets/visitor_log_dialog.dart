import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/features/intelligence/data/visitor_service.dart';

/// Modal dialog for logging a farm visitor event (Part 5)
class VisitorLogDialog extends StatefulWidget {
  final String farmId;
  final VoidCallback? onSaved;

  const VisitorLogDialog({
    super.key,
    required this.farmId,
    this.onSaved,
  });

  @override
  State<VisitorLogDialog> createState() => _VisitorLogDialogState();
}

class _VisitorLogDialogState extends State<VisitorLogDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _orgController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();

  String _visitorType = 'service_tech';
  bool _visitedLivestockRecently = false;
  bool _vehicleEntered = false;
  bool _footwearDisinfected = true;
  bool _vehicleDisinfected = true;
  bool _ppeUsed = true;
  bool _sharedEquipment = false;
  bool _newAnimalIntroduction = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _orgController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await VisitorService.logVisitorEvent(
        farmId: widget.farmId,
        visitorName: _nameController.text.trim(),
        visitorType: _visitorType,
        organization: _orgController.text.trim(),
        purpose: _purposeController.text.trim(),
        enteredAt: DateTime.now(),
        visitedLivestockFarmRecently: _visitedLivestockRecently,
        vehicleEntered: _vehicleEntered,
        footwearDisinfected: _footwearDisinfected,
        vehicleDisinfected: _vehicleDisinfected,
        ppeUsed: _ppeUsed,
        sharedEquipment: _sharedEquipment,
        newAnimalIntroductionRelated: _newAnimalIntroduction,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visitor & biosecurity event logged successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving visitor log: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusMd)),
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Text('Log Farm Visitor & Biosecurity Event', style: AppTypography.headingSmall),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Visitor Name & Type
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Visitor Name *',
                          hintText: 'e.g. Ramesh Patil',
                          isDense: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        value: _visitorType,
                        decoration: const InputDecoration(labelText: 'Type', isDense: true),
                        items: const [
                          DropdownMenuItem(value: 'veterinarian', child: Text('Veterinarian')),
                          DropdownMenuItem(value: 'feed_supplier', child: Text('Feed Supplier')),
                          DropdownMenuItem(value: 'chick_delivery', child: Text('Chick Delivery')),
                          DropdownMenuItem(value: 'buyer', child: Text('Bird Buyer')),
                          DropdownMenuItem(value: 'service_tech', child: Text('Service Tech')),
                          DropdownMenuItem(value: 'neighboring_farmer', child: Text('Neighbor')),
                          DropdownMenuItem(value: 'inspector', child: Text('Govt Inspector')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _visitorType = v ?? 'other'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Organization & Purpose
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _orgController,
                        decoration: const InputDecoration(
                          labelText: 'Organization / Company',
                          hintText: 'e.g. Sahyadri Feeds',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _purposeController,
                        decoration: const InputDecoration(
                          labelText: 'Visit Purpose *',
                          hintText: 'e.g. Feed Delivery',
                          isDense: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Divider(),
                const SizedBox(height: 8),
                Text('Biosecurity Checkpoints & Risk Vectors', style: AppTypography.labelMedium),
                const SizedBox(height: 8),

                // Checkboxes
                CheckboxListTile(
                  dense: true,
                  title: const Text('Visited another livestock/poultry farm in past 48-72h'),
                  value: _visitedLivestockRecently,
                  onChanged: (v) => setState(() => _visitedLivestockRecently = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Footwear disinfection footbath verified at entry'),
                  value: _footwearDisinfected,
                  onChanged: (v) => setState(() => _footwearDisinfected = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Vehicle entered farm perimeter'),
                  value: _vehicleEntered,
                  onChanged: (v) => setState(() => _vehicleEntered = v ?? false),
                ),
                if (_vehicleEntered)
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: CheckboxListTile(
                      dense: true,
                      title: const Text('Vehicle wheels/tyres sprayed with disinfectant'),
                      value: _vehicleDisinfected,
                      onChanged: (v) => setState(() => _vehicleDisinfected = v ?? false),
                    ),
                  ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Farm PPE / dedicated boots provided and used'),
                  value: _ppeUsed,
                  onChanged: (v) => setState(() => _ppeUsed = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('Shared crates or equipment brought onto premises'),
                  value: _sharedEquipment,
                  onChanged: (v) => setState(() => _sharedEquipment = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  title: const Text('New animal/bird stock introduction involved'),
                  value: _newAnimalIntroduction,
                  onChanged: (v) => setState(() => _newAnimalIntroduction = v ?? false),
                ),

                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes',
                    hintText: 'e.g. Sheds entered, hygiene observations...',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: _saving ? 'Saving...' : 'Record Visitor Entry',
                      variant: AppButtonVariant.primary,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
