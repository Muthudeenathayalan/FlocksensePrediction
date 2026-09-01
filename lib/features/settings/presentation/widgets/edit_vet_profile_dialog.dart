import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/core/widgets/app_text_field.dart';
import 'package:flock_sense/features/settings/data/models/user_preferences_model.dart';
import 'package:flock_sense/features/settings/data/services/settings_service.dart';
import 'package:flock_sense/features/settings/domain/settings_providers.dart';

class EditVetProfileDialog extends ConsumerStatefulWidget {
  final UserPreferencesModel currentPrefs;

  const EditVetProfileDialog({
    super.key,
    required this.currentPrefs,
  });

  @override
  ConsumerState<EditVetProfileDialog> createState() => _EditVetProfileDialogState();
}

class _EditVetProfileDialogState extends ConsumerState<EditVetProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _regIdController;
  late TextEditingController _specController;
  late TextEditingController _clinicController;
  String _selectedDistrict = 'Nashik';
  String _selectedAvailability = 'Available on Duty';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentPrefs.displayName);
    _phoneController = TextEditingController(text: widget.currentPrefs.phone);
    _regIdController = TextEditingController(text: widget.currentPrefs.vetRegistrationId);
    _specController = TextEditingController(text: widget.currentPrefs.specialization);
    _clinicController = TextEditingController(text: widget.currentPrefs.clinicOrganization);
    _selectedDistrict = widget.currentPrefs.serviceDistrict;
    _selectedAvailability = widget.currentPrefs.availabilityStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _regIdController.dispose();
    _specController.dispose();
    _clinicController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(settingsNotifierProvider.notifier);
      await notifier.updateVetProfessionalDetails(
        vetRegistrationId: _regIdController.text.trim(),
        specialization: _specController.text.trim(),
        clinicOrganization: _clinicController.text.trim(),
        serviceDistrict: _selectedDistrict,
        availabilityStatus: _selectedAvailability,
      );
      await SettingsService.updateProfile(
        displayName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update details: $e'),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Edit Veterinarian Professional Details',
      icon: Icons.medical_services_outlined,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _nameController,
                labelText: 'Clinician Full Name',
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter clinician name' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _phoneController,
                labelText: 'Contact Phone Number',
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _regIdController,
                labelText: 'Veterinary Council Registration ID',
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter registration ID (e.g. VET-MH-2024-8841)' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _specController,
                labelText: 'Clinical Specialization',
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter specialization' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _clinicController,
                labelText: 'Clinic / Polyclinic Organization',
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter clinic name' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: const InputDecoration(
                  labelText: 'Assigned Service District',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: ['Nashik', 'Pune', 'Ahmednagar', 'Dhule', 'Jalgaon', 'Solapur', 'Satara']
                    .map((d) => DropdownMenuItem(value: d, child: Text('$d Division')))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDistrict = v ?? 'Nashik'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedAvailability,
                decoration: const InputDecoration(
                  labelText: 'Duty Availability Status',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: ['Available on Duty', 'On Field Visit', 'Off Duty']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedAvailability = v ?? 'Available on Duty'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          variant: AppButtonVariant.text,
          size: AppButtonSize.small,
        ),
        const SizedBox(width: 10),
        AppButton(
          label: 'Save Professional Details',
          onPressed: _isLoading ? null : _save,
          isLoading: _isLoading,
          variant: AppButtonVariant.primary,
          size: AppButtonSize.small,
        ),
      ],
    );
  }
}
