import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/sales/data/sales_service.dart';

class SalesFormScreen extends StatefulWidget {
  const SalesFormScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    required this.currentBatchAge,
  });

  final String farmId;
  final String batchId;
  final int currentBatchAge;

  @override
  State<SalesFormScreen> createState() => _SalesFormScreenState();
}

class _SalesFormScreenState extends State<SalesFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _birdsController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _customerController.dispose();
    _birdsController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _vehicleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await SalesService.createSalesRecord(
        farmId: widget.farmId,
        batchId: widget.batchId,
        customerName: _customerController.text.trim(),
        birdsSold: int.tryParse(_birdsController.text.trim()) ?? 0,
        averageWeightKg: double.tryParse(_weightController.text.trim()) ?? 0,
        pricePerBird: double.tryParse(_priceController.text.trim()) ?? 0,
        date: _selectedDate,
        batchAgeDay: widget.currentBatchAge,
        vehicleNumber: _vehicleController.text.trim().isEmpty
            ? null
            : _vehicleController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale entry saved successfully'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final birds = int.tryParse(_birdsController.text.trim()) ?? 0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final totalVal = birds * price;
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Record Bird Sale',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
              const WebPageHeader(
                title: 'Record Market Bird Sale',
                subtitle:
                    'Log commercial bird sales, buyer records, truck dispatches, and calculate total revenue realization.',
                breadcrumb: 'Batches / Sales / New Entry',
              ),

              // 2. Form Card
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppDesign.sectionTitle('Sale & Buyer Details'),
                    const SizedBox(height: 12),
                    _textField(
                      _customerController,
                      'Buyer / Wholesaler Name (e.g. Metro Poultry Mart)',
                      icon: Icons.person_outline_rounded,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            _birdsController,
                            'Birds Sold (Count)',
                            icon: Icons.pets_outlined,
                            required: true,
                            keyboardType: TextInputType.number,
                            formatter: FilteringTextInputFormatter.digitsOnly,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _textField(
                            _weightController,
                            'Avg Weight per Bird (kg)',
                            icon: Icons.scale_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            formatter: FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            _priceController,
                            'Price per Bird (₹)',
                            icon: Icons.currency_rupee_rounded,
                            required: true,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            formatter: FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.]'),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
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
                                      const SizedBox(width: 10),
                                      Text(
                                        DateFormat('dd MMM yyyy').format(_selectedDate),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.slate800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.arrow_drop_down_rounded,
                                      color: AppColors.slate400),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            _vehicleController,
                            'Dispatch Vehicle Number (e.g. KA-04-AB-1234)',
                            icon: Icons.local_shipping_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _textField(
                      _notesController,
                      'Dispatch & Payment Notes',
                      icon: Icons.notes_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    // Calculated Total Value Card
                    Container(
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
                              color: AppColors.emerald.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded,
                                color: AppColors.emerald, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estimated Sale Value Realization',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  totalVal > 0
                                      ? '$birds birds × ₹${price.toStringAsFixed(1)} = ${currencyFmt.format(totalVal)}'
                                      : 'Enter bird count and price above to calculate total revenue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: totalVal > 0
                                        ? AppColors.emerald
                                        : AppColors.slate400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                    label: 'Save & Dispatch Sale',
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
    TextInputFormatter? formatter,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      inputFormatters: formatter != null ? [formatter] : null,
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
      validator: required
          ? (v) => (v?.trim().isEmpty ?? true) ? 'This field is required' : null
          : null,
    );
  }
}
