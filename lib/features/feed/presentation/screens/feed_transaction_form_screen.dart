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
import 'package:flock_sense/features/feed/data/feed_service.dart';
import 'package:flock_sense/features/feed/domain/feed_transaction_model.dart';

class FeedTransactionFormScreen extends StatefulWidget {
  const FeedTransactionFormScreen({
    super.key,
    required this.farmId,
    required this.batchId,
    this.batchName,
    this.existingTransaction,
  });

  final String farmId;
  final String batchId;
  final String? batchName;
  final FeedTransactionModel? existingTransaction;

  @override
  State<FeedTransactionFormScreen> createState() =>
      _FeedTransactionFormScreenState();
}

class _FeedTransactionFormScreenState extends State<FeedTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late String _selectedFeedType;
  final _dcNumberController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _bagsController = TextEditingController();
  final _weightPerBagController = TextEditingController(text: '75');
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  static const List<String> _feedTypes = <String>[
    'PB82',
    '882',
    'B4',
    'Starter',
    'Grower',
    'Finisher',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    _selectedDate = existing?.date ?? DateTime.now();
    _selectedFeedType = existing?.feedType ?? _feedTypes.first;
    _dcNumberController.text = existing?.dcNumber ?? '';
    _batchNumberController.text = existing?.batchNumber ?? '';
    _bagsController.text = existing?.bags.toString() ?? '';
    _weightPerBagController.text = existing?.weightPerBagKg.toString() ?? '75';
    _supplierController.text = existing?.supplierName ?? '';
    _notesController.text = existing?.notes ?? '';
  }

  @override
  void dispose() {
    _dcNumberController.dispose();
    _batchNumberController.dispose();
    _bagsController.dispose();
    _weightPerBagController.dispose();
    _supplierController.dispose();
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

  double _calculateTotalKg() {
    final bags = int.tryParse(_bagsController.text.trim()) ?? 0;
    final weightPerBag =
        double.tryParse(_weightPerBagController.text.trim()) ?? 0;
    return bags > 0 && weightPerBag > 0 ? bags * weightPerBag : 0.0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final bags = int.tryParse(_bagsController.text.trim()) ?? 0;
      final weightPerBag =
          double.tryParse(_weightPerBagController.text.trim()) ?? 0;
      final totalKg = _calculateTotalKg();

      if (bags <= 0) {
        throw Exception('Number of bags must be greater than zero.');
      }

      await FeedService.createFeedTransaction(
        farmId: widget.farmId,
        batchId: widget.batchId,
        transactionDate: _selectedDate,
        transactionType: 'received',
        feedType: _selectedFeedType,
        feedBatchNumber: _batchNumberController.text.trim().isEmpty
            ? null
            : _batchNumberController.text.trim(),
        dcNumber: _dcNumberController.text.trim().isEmpty
            ? null
            : _dcNumberController.text.trim(),
        bags: bags,
        weightPerBagKg: weightPerBag,
        totalKg: totalKg,
        supplierOrSource: _supplierController.text.trim().isEmpty
            ? null
            : _supplierController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feed delivery receipt saved successfully!'),
          backgroundColor: AppColors.healthy,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save error: $e'),
          backgroundColor: AppColors.critical,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalKg = _calculateTotalKg();

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebPageHeader(
            title: widget.batchName != null
                ? 'Feed Receipt • ${widget.batchName}'
                : 'Log Feed Receipt',
            subtitle: 'Log incoming feed deliveries, delivery challan reference numbers, and silo allocations.',
            actions: [
              AppButton(
                label: 'Back to Feed Inventory',
                icon: Icons.arrow_back_rounded,
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.small,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Feed Delivery Challan Details', style: AppTypography.headingSmall),
                              const SizedBox(height: 4),
                              Text('Record bags received from feed mill into the batch storage silo.', style: AppTypography.caption),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                            ),
                            child: Text(
                              _selectedFeedType,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 20),

                      Text('Feed Type / Ration Category *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _feedTypes.map((type) {
                          final selected = _selectedFeedType == type;
                          return FilterChip(
                            label: Text(type),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedFeedType = type),
                            selectedColor: AppColors.primaryLight,
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? AppColors.primaryDark : AppColors.slate700,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Delivery Date *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _pickDate,
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 13)),
                                        const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.slate500),
                                      ],
                                    ),
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
                                Text('Delivery Challan (DC) No.', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _dcNumberController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. DC-99824',
                                    isDense: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Feed Mill Batch / Lot No.', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _batchNumberController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. MILL-LOT-441',
                                    isDense: true,
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
                                Text('Feed Mill / Supplier Name', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _supplierController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Suguna Feed Mills',
                                    isDense: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Number of Bags *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _bagsController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. 80',
                                    isDense: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (val) {
                                    final parsed = int.tryParse(val?.trim() ?? '');
                                    return (parsed == null || parsed <= 0) ? 'Enter valid bag count' : null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Weight per Bag (kg) *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _weightPerBagController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    hintText: '75',
                                    isDense: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Weight Received', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${totalKg.toStringAsFixed(1)} kg',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      Text('Delivery Remarks & Silo Allocation', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Add remarks on feed moisture, truck driver details, or silo allocation...',
                        ),
                      ),
                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppButton(
                            label: 'Cancel',
                            variant: AppButtonVariant.outlined,
                            size: AppButtonSize.medium,
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          AppButton(
                            label: 'Save Delivery Receipt',
                            icon: Icons.check_circle_outline_rounded,
                            size: AppButtonSize.medium,
                            isLoading: _saving,
                            onPressed: _save,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
