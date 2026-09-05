import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/home/presentation/providers/home_dashboard_provider.dart';
import 'package:flock_sense/features/inventory/domain/inventory_item_model.dart';
import 'package:flock_sense/features/inventory/presentation/providers/inventory_providers.dart';

class InventoryItemFormScreen extends ConsumerStatefulWidget {
  const InventoryItemFormScreen({super.key, this.existingItem});

  final InventoryItemModel? existingItem;

  @override
  ConsumerState<InventoryItemFormScreen> createState() => _InventoryItemFormScreenState();
}

class _InventoryItemFormScreenState extends ConsumerState<InventoryItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _supplierController;
  late TextEditingController _quantityController;
  late TextEditingController _minStockController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _storageLocationController;
  late TextEditingController _batchNumberController;
  late TextEditingController _notesController;

  String _category = 'Feed';
  String _unit = 'kg';
  DateTime _purchaseDate = DateTime.now();
  DateTime? _expiryDate;
  bool _isSaving = false;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;

    _nameController = TextEditingController(text: item?.itemName ?? '');
    _brandController = TextEditingController(text: item?.brand ?? '');
    _supplierController = TextEditingController(text: item?.supplier ?? '');
    _quantityController = TextEditingController(
      text: item != null ? item.quantityAvailable.toString() : '',
    );
    _minStockController = TextEditingController(
      text: item != null ? item.minStockLevel.toString() : '10',
    );
    _purchasePriceController = TextEditingController(
      text: item != null ? item.purchasePrice.toString() : '',
    );
    _sellingPriceController = TextEditingController(
      text: item?.sellingPrice != null ? item!.sellingPrice.toString() : '',
    );
    _storageLocationController = TextEditingController(
      text: item?.storageLocation ?? 'Main Store',
    );
    _batchNumberController = TextEditingController(text: item?.batchNumber ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');

    if (item != null) {
      _category = item.category;
      _unit = item.unit;
      _purchaseDate = item.purchaseDate;
      _expiryDate = item.expiryDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _supplierController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _storageLocationController.dispose();
    _batchNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingItem != null;

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Web Page Header with Back Action
          WebPageHeader(
            title: isEdit ? 'Edit Stock Item' : 'Add Inventory Item',
            subtitle: isEdit
                ? 'Update specifications, quantity adjustments, and pricing for this stock asset.'
                : 'Register a new feed, medicine, vaccine, or farm equipment item in stock.',
            actions: [
              AppButton(
                label: 'Back to Inventory',
                icon: Icons.arrow_back_rounded,
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.small,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          // 2. Centered Form in AppCard
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
                          Text('Item Specifications & Details', style: AppTypography.headingSmall),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                            ),
                            child: Text(
                              _category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11.5,
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

                      // Row 1: Category & Name
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Item Category *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _category,
                                  decoration: const InputDecoration(isDense: true),
                                  items: const [
                                    DropdownMenuItem(value: 'Feed', child: Text('Feed')),
                                    DropdownMenuItem(value: 'Medicine', child: Text('Medicine')),
                                    DropdownMenuItem(value: 'Vaccines', child: Text('Vaccines')),
                                    DropdownMenuItem(value: 'Equipment', child: Text('Equipment')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _category = val;
                                        _unit = _defaultUnitForCategory(val);
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Item Name *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Starter Feed, Amoxicillin 10%',
                                    isDense: true,
                                  ),
                                  validator: (val) =>
                                      (val == null || val.trim().isEmpty) ? 'Please enter item name' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Row 2: Brand & Supplier
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Brand / Manufacturer', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _brandController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Suguna / Venkys / Hester',
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
                                Text('Supplier Name', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _supplierController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Namakkal Agro Agencies',
                                    isDense: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Row 3: Quantity & Unit
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quantity Available *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _quantityController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    isDense: true,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Enter quantity';
                                    final q = double.tryParse(val.trim());
                                    if (q == null || q < 0) return 'Invalid quantity';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Unit *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _unit,
                                  decoration: const InputDecoration(isDense: true),
                                  items: const [
                                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                                    DropdownMenuItem(value: 'Liters', child: Text('Liters')),
                                    DropdownMenuItem(value: 'Bags', child: Text('Bags')),
                                    DropdownMenuItem(value: 'Doses', child: Text('Doses')),
                                    DropdownMenuItem(value: 'Pieces', child: Text('Pieces')),
                                    DropdownMenuItem(value: 'Units', child: Text('Units')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _unit = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Row 4: Minimum Stock Level & Storage Location
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Min Stock Level (Alert Threshold) *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _minStockController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    hintText: '10',
                                    isDense: true,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Enter min stock';
                                    final m = double.tryParse(val.trim());
                                    if (m == null || m < 0) return 'Invalid number';
                                    return null;
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
                                Text('Storage Location *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _storageLocationController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Feed Silo 1 / Cold Storage',
                                    isDense: true,
                                  ),
                                  validator: (val) =>
                                      (val == null || val.trim().isEmpty) ? 'Enter location' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Row 5: Purchase Price & Selling Price
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Purchase Price (₹) *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _purchasePriceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    hintText: '₹ 0.00',
                                    isDense: true,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Enter price';
                                    final p = double.tryParse(val.trim());
                                    if (p == null || p < 0) return 'Invalid price';
                                    return null;
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
                                Text('Selling Price (₹) — Optional', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _sellingPriceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    hintText: '₹ 0.00',
                                    isDense: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Row 6: Purchase Date & Expiry Date
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Purchase Date *', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _purchaseDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) setState(() => _purchaseDate = picked);
                                  },
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
                                        Text(_dateFormat.format(_purchaseDate), style: const TextStyle(fontSize: 13)),
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
                                Text('Expiry Date — Optional', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 180)),
                                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                                    );
                                    if (picked != null) setState(() => _expiryDate = picked);
                                  },
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
                                        Text(
                                          _expiryDate != null ? _dateFormat.format(_expiryDate!) : 'No Expiry Set',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _expiryDate != null ? AppColors.textPrimary : AppColors.textHint,
                                          ),
                                        ),
                                        if (_expiryDate != null)
                                          GestureDetector(
                                            onTap: () => setState(() => _expiryDate = null),
                                            child: const Icon(Icons.clear, size: 16, color: AppColors.slate500),
                                          )
                                        else
                                          const Icon(Icons.event_busy_outlined, size: 16, color: AppColors.slate500),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Row 7: Batch Number & Notes
                      Text('Batch / Lot Number', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _batchNumberController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. BATCH-2026-09-A',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 18),

                      Text('Notes / Storage Remarks', style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Add storage conditions, dosage guidance, or supplier contact notes...',
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Actions
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
                            label: isEdit ? 'Update Stock Item' : 'Save Item to Inventory',
                            icon: Icons.check_circle_outline_rounded,
                            size: AppButtonSize.medium,
                            isLoading: _isSaving,
                            onPressed: _saveItem,
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

  String _defaultUnitForCategory(String category) {
    switch (category) {
      case 'Feed':
        return 'kg';
      case 'Medicine':
        return 'Units';
      case 'Vaccines':
        return 'Doses';
      case 'Equipment':
      default:
        return 'Pieces';
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = ref.read(authStateProvider).value;
      final activeFarmId = ref.read(activeFarmIdProvider).value;

      if (user == null || activeFarmId == null) {
        throw Exception('User or farm session not found.');
      }

      final service = ref.read(inventoryServiceProvider);

      final item = InventoryItemModel(
        id: widget.existingItem?.id ?? '',
        farmId: activeFarmId,
        ownerId: user.uid,
        itemName: _nameController.text.trim(),
        category: _category,
        brand: _brandController.text.trim(),
        supplier: _supplierController.text.trim(),
        quantityAvailable: double.parse(_quantityController.text.trim()),
        unit: _unit,
        minStockLevel: double.parse(_minStockController.text.trim()),
        purchaseDate: _purchaseDate,
        expiryDate: _expiryDate,
        purchasePrice: double.parse(_purchasePriceController.text.trim()),
        sellingPrice: _sellingPriceController.text.trim().isNotEmpty
            ? double.tryParse(_sellingPriceController.text.trim())
            : null,
        storageLocation: _storageLocationController.text.trim(),
        batchNumber: _batchNumberController.text.trim().isNotEmpty
            ? _batchNumberController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: widget.existingItem?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingItem == null) {
        await service.addInventoryItem(item);
      } else {
        await service.updateInventoryItem(item);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingItem == null
                  ? 'Inventory item added successfully!'
                  : 'Inventory item updated successfully!',
            ),
            backgroundColor: AppColors.healthy,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving item: $e'),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }
}
