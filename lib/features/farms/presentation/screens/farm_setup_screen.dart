import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flock_sense/core/services/location_service.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_command_center_screen.dart';

class FarmSetupScreen extends StatefulWidget {
  const FarmSetupScreen({super.key, this.initialFarm});

  final FarmModel? initialFarm;

  @override
  State<FarmSetupScreen> createState() => _FarmSetupScreenState();
}

class _FarmSetupScreenState extends State<FarmSetupScreen> {
  final _pageController = PageController();
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  final _farmNameController = TextEditingController();
  final _farmerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _capacityController = TextEditingController(text: '5000');

  final _areaController = TextEditingController(text: 'Paramathi Velur');
  final _districtController = TextEditingController(text: 'Namakkal');
  final _stateController = TextEditingController(text: 'Tamil Nadu');
  final _countryController = TextEditingController(text: 'India');
  final _lengthController = TextEditingController(text: '200');
  final _breadthController = TextEditingController(text: '35');
  final _notesController = TextEditingController();

  String _selectedFarmType = 'EC';
  String _selectedFlockType = 'Broiler';
  String _sizeUnit = 'ft';
  bool _resolvingLocation = false;
  bool _saving = false;
  int _step = 0;

  static const _farmTypes = <Map<String, String>>[
    {'id': 'EC', 'title': 'EC Shed', 'sub': 'Closed Environment Control'},
    {'id': 'Open', 'title': 'Open House', 'sub': 'Natural Ventilation'},
  ];

  static const _flockTypes = <Map<String, String>>[
    {'id': 'Broiler', 'title': 'Broiler', 'sub': 'Meat Production'},
    {'id': 'Layer', 'title': 'Layer', 'sub': 'Commercial Egg'},
    {'id': 'Breeder', 'title': 'Breeder', 'sub': 'Parent Stock'},
    {'id': 'Country', 'title': 'Country / Desi', 'sub': 'Free Range / Nattu'},
  ];

  @override
  void initState() {
    super.initState();
    _hydrateFromInitial();
  }

  void _hydrateFromInitial() {
    final farm = widget.initialFarm;
    if (farm == null) return;

    _farmNameController.text = farm.farmName;
    _farmerNameController.text = farm.farmerName ?? '';
    _phoneController.text = farm.phoneNumber ?? '';
    _selectedFarmType = farm.farmType.isNotEmpty ? farm.farmType : 'EC';
    _selectedFlockType = farm.flockType.isNotEmpty ? farm.flockType : 'Broiler';
    _areaController.text = farm.areaName ?? '';
    _districtController.text = farm.district ?? '';
    _stateController.text = farm.state ?? 'Tamil Nadu';
    _countryController.text = farm.country ?? 'India';
    _sizeUnit = farm.sizeUnit;
    _capacityController.text = (farm.capacity ?? 5000).toString();
    _notesController.text = farm.notes ?? '';

    final length = _sizeUnit == 'm' ? _ftToMeter(farm.lengthFt) : farm.lengthFt;
    final breadth = _sizeUnit == 'm' ? _ftToMeter(farm.widthFt) : farm.widthFt;
    _lengthController.text = _toDisplay(length);
    _breadthController.text = _toDisplay(breadth);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _farmNameController.dispose();
    _farmerNameController.dispose();
    _phoneController.dispose();
    _capacityController.dispose();
    _areaController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _lengthController.dispose();
    _breadthController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    setState(() => _resolvingLocation = true);
    try {
      final location = await LocationService.resolveCurrentLocation();
      if (!mounted) return;
      if (location != null) {
        setState(() {
          if (location.area.isNotEmpty) _areaController.text = location.area;
          if (location.district.isNotEmpty) _districtController.text = location.district;
          if (location.state.isNotEmpty) _stateController.text = location.state;
          if (location.country.isNotEmpty) _countryController.text = location.country;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Location updated: ${location.shortAddress}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (_) {
      // Non-blocking fallback
    } finally {
      if (mounted) {
        setState(() => _resolvingLocation = false);
      }
    }
  }

  double get _lengthInput => double.tryParse(_lengthController.text.trim()) ?? 0;
  double get _breadthInput => double.tryParse(_breadthController.text.trim()) ?? 0;
  double get _areaInSelectedUnit => _lengthInput * _breadthInput;

  double get _lengthFt => _sizeUnit == 'm' ? _meterToFt(_lengthInput) : _lengthInput;
  double get _breadthFt => _sizeUnit == 'm' ? _meterToFt(_breadthInput) : _breadthInput;

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final isEdit = widget.initialFarm != null;
      final addressParts = <String>[
        _areaController.text.trim(),
        _districtController.text.trim(),
        _stateController.text.trim(),
        _countryController.text.trim(),
      ].where((part) => part.isNotEmpty).toList();

      final farm = isEdit
          ? await FarmService.updateFarm(
              farmId: widget.initialFarm!.id,
              farmName: _farmNameController.text.trim(),
              farmType: _selectedFarmType,
              flockType: _selectedFlockType,
              areaName: _areaController.text.trim().isEmpty
                  ? null
                  : _areaController.text.trim(),
              district: _districtController.text.trim().isEmpty
                  ? null
                  : _districtController.text.trim(),
              state: _stateController.text.trim().isEmpty
                  ? null
                  : _stateController.text.trim(),
              country: _countryController.text.trim().isEmpty
                  ? null
                  : _countryController.text.trim(),
              address: addressParts.join(', '),
              lengthFt: _lengthFt,
              widthFt: _breadthFt,
              sizeUnit: _sizeUnit,
              capacity: int.tryParse(_capacityController.text.trim()),
              notes: _notesController.text.trim(),
            )
          : await FarmService.createFarm(
              farmName: _farmNameController.text.trim(),
              farmerName: _farmerNameController.text.trim().isNotEmpty
                  ? _farmerNameController.text.trim()
                  : null,
              phoneNumber: _phoneController.text.trim().isNotEmpty
                  ? _phoneController.text.trim()
                  : null,
              farmType: _selectedFarmType,
              flockType: _selectedFlockType,
              address: addressParts.join(', '),
              areaName: _areaController.text.trim().isEmpty
                  ? null
                  : _areaController.text.trim(),
              district: _districtController.text.trim().isEmpty
                  ? null
                  : _districtController.text.trim(),
              state: _stateController.text.trim().isEmpty
                  ? null
                  : _stateController.text.trim(),
              country: _countryController.text.trim().isEmpty
                  ? null
                  : _countryController.text.trim(),
              lengthFt: _lengthFt,
              widthFt: _breadthFt,
              sizeUnit: _sizeUnit,
              capacity: int.tryParse(_capacityController.text.trim()),
              notes: _notesController.text.trim(),
            );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEdit
                      ? 'Farm "${farm.farmName}" updated successfully!'
                      : 'Farm "${farm.farmName}" registered successfully!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (isEdit) {
        Navigator.of(context).pop(farm);
      } else {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(farm);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => FarmCommandCenterScreen(farm: farm),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save farm: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _nextStep() {
    if (_step == 0) {
      final nameValid = _step1FormKey.currentState?.validate() ?? false;
      if (!nameValid) return;
      setState(() => _step = 1);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    final step2Valid = _step2FormKey.currentState?.validate() ?? false;
    if (!step2Valid) return;
    _save();
  }

  void _backStep() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step = 0);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialFarm != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Farm Facility' : 'Register New Poultry Farm',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        elevation: 0,
        backgroundColor: AppColors.surface,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: _WizardHeader(step: _step),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_buildStepBasics(), _buildStepLocationAndDimensions()],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _backStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(_step == 0 ? 'Cancel' : '← Previous Step'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _saving ? null : _nextStep,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _step == 1
                                    ? (isEdit ? 'Save Changes' : '✓ Complete & Register Farm')
                                    : 'Next: Location & Size →',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBasics() {
    return Form(
      key: _step1FormKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        children: [
          _SectionCard(
            title: 'Farm Identity & Profile',
            subtitle: 'Specify the facility name, operational type, and production breed.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _farmNameController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Farm Name *',
                    hintText: 'e.g. Green Valley Farm Unit 1',
                    prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a valid farm name.';
                    }
                    if (value.trim().length < 2) {
                      return 'Farm name must be at least 2 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  'Housing Structure *',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate800,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _farmTypes.map((t) {
                    final isSelected = _selectedFarmType == t['id'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFarmType = t['id']!),
                        child: Container(
                          margin: EdgeInsets.only(right: t == _farmTypes.first ? 10 : 0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryLight : AppColors.slate50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    t['id'] == 'EC' ? Icons.factory_outlined : Icons.wb_sunny_outlined,
                                    size: 18,
                                    color: isSelected ? AppColors.primary : AppColors.slate600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t['title']!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isSelected ? AppColors.primary : AppColors.slate900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t['sub']!,
                                style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                Text(
                  'Flock Production Type *',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate800,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _flockTypes.map((f) {
                    final isSelected = _selectedFlockType == f['id'];
                    return ChoiceChip(
                      label: Text(f['title']!),
                      selected: isSelected,
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.slate800,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12.5,
                      ),
                      onSelected: (_) => setState(() => _selectedFlockType = f['id']!),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Operator & Bird Capacity',
            subtitle: 'Contact details for farm management and housing capacity.',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _farmerNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Owner / Manager Name',
                          hintText: 'e.g. Muthu Deenathayalan',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Contact Phone',
                          hintText: 'e.g. 9876543210',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Total Bird Capacity (Birds)',
                    hintText: 'e.g. 5000',
                    prefixIcon: Icon(Icons.pets_outlined, size: 20),
                    suffixText: 'birds',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLocationAndDimensions() {
    return Form(
      key: _step2FormKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        children: [
          _SectionCard(
            title: 'Geographic Location',
            subtitle: 'Used for disease surveillance, weather sync, and GIS cluster mapping.',
            trailing: OutlinedButton.icon(
              onPressed: _resolvingLocation ? null : _resolveLocation,
              icon: _resolvingLocation
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded, size: 16),
              label: Text(_resolvingLocation ? 'Detecting...' : 'Auto-detect GPS'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _areaController,
                        decoration: const InputDecoration(
                          labelText: 'Village / Area Name *',
                          hintText: 'e.g. Paramathi Velur',
                          prefixIcon: Icon(Icons.pin_drop_outlined, size: 18),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Area name required' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _districtController,
                        decoration: const InputDecoration(
                          labelText: 'District *',
                          hintText: 'e.g. Namakkal',
                          prefixIcon: Icon(Icons.map_outlined, size: 18),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'District required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          hintText: 'Tamil Nadu',
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          hintText: 'India',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Shed Dimensions & Size',
            subtitle: 'Length and width automatically compute floor area and density ratings.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Measurement Unit:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Feet (ft)'),
                          selected: _sizeUnit == 'ft',
                          onSelected: (_) => setState(() => _sizeUnit = 'ft'),
                        ),
                        ChoiceChip(
                          label: const Text('Meters (m)'),
                          selected: _sizeUnit == 'm',
                          onSelected: (_) => setState(() => _sizeUnit = 'm'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lengthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                        decoration: InputDecoration(
                          labelText: 'Length ($_sizeUnit)',
                          hintText: 'e.g. 200',
                          prefixIcon: const Icon(Icons.straighten, size: 18),
                        ),
                        validator: _positiveNumber,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _breadthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                        decoration: InputDecoration(
                          labelText: 'Breadth / Width ($_sizeUnit)',
                          hintText: 'e.g. 35',
                          prefixIcon: const Icon(Icons.height, size: 18),
                        ),
                        validator: _positiveNumber,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.healthyBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Total Floor Area: ${_areaInSelectedUnit.toStringAsFixed(1)} $_sizeUnit²',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          fontSize: 13.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '~${(_lengthFt * _breadthFt / 1.2).round()} max birds',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Biosecurity Protocols (Optional)',
                    hintText: 'e.g. Shed 1 & 2 equipped with automated tunnel ventilation and nipple drinkers.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid positive number';
    }
    return null;
  }

  static double _meterToFt(double value) => value * 3.28084;
  static double _ftToMeter(double value) => value / 3.28084;

  static String _toDisplay(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(context, 0, '1. Farm Basics', step >= 0),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 2,
            color: step > 0 ? AppColors.primary : AppColors.border,
          ),
        ),
        const SizedBox(width: 12),
        _dot(context, 1, '2. Location & Dimensions', step >= 1),
      ],
    );
  }

  Widget _dot(BuildContext context, int index, String label, bool active) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: active ? AppColors.primary : AppColors.slate200,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 11,
              color: active ? Colors.white : AppColors.slate600,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.slate900 : AppColors.slate500,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDesign.cardDecorationFlat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.cardTitle.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: AppTypography.metadata,
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
