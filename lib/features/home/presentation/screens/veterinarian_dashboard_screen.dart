import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/health/presentation/screens/farm_clinical_view_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/veterinarian_critical_queue_screen.dart';
import 'package:flock_sense/features/home/presentation/providers/veterinarian_dashboard_provider.dart';
import 'package:flock_sense/shared/analytics/animated_kpi_card.dart';

/// Managed Farm Record for Veterinarian Surveillance Network
class VetNetworkFarmItem {
  final String farmId;
  final String farmName;
  final String farmerName;
  final String district;
  final String livestockType;
  final int totalBirds;
  final int currentMortality;
  final String mortalityTrend;
  final String feedTrend;
  final String riskLevel; // 'critical', 'high', 'moderate', 'low'
  final String environmentalRisk;
  final String nearbyExposure;
  final int activeCases;
  final DateTime lastReportedAt;

  const VetNetworkFarmItem({
    required this.farmId,
    required this.farmName,
    required this.farmerName,
    required this.district,
    this.livestockType = 'Broiler (Cobb 500)',
    this.totalBirds = 10000,
    required this.currentMortality,
    required this.mortalityTrend,
    required this.feedTrend,
    required this.riskLevel,
    required this.environmentalRisk,
    required this.nearbyExposure,
    required this.activeCases,
    required this.lastReportedAt,
  });
}

/// Dedicated Veterinarian Multi-Farm Dashboard (Part 11)
class VeterinarianDashboardScreen extends ConsumerStatefulWidget {
  final String? vetId;
  final String? district;

  const VeterinarianDashboardScreen({
    super.key,
    this.vetId,
    this.district,
  });

  @override
  ConsumerState<VeterinarianDashboardScreen> createState() => _VeterinarianDashboardScreenState();
}

class _VeterinarianDashboardScreenState extends ConsumerState<VeterinarianDashboardScreen> {
  String _riskFilter = 'ALL'; // 'ALL', 'CRITICAL', 'HIGH', 'MODERATE', 'LOW'
  String _searchQuery = '';

  List<VetNetworkFarmItem> _getNetworkFarms() {
    final now = DateTime.now();
    return [
      VetNetworkFarmItem(
        farmId: 'farm_demo_001',
        farmName: 'Green Valley Poultry Farm',
        farmerName: 'Ramesh Patil',
        district: 'Nashik',
        livestockType: 'Broiler (42d)',
        totalBirds: 10000,
        currentMortality: 15,
        mortalityTrend: '5.0x (Spike)',
        feedTrend: '-19.6% (Drop)',
        riskLevel: 'critical',
        environmentalRisk: 'HIGH (35°C, 82%)',
        nearbyExposure: 'HIGH (2 cases in 7km)',
        activeCases: 1,
        lastReportedAt: now.subtract(const Duration(minutes: 14)),
      ),
      VetNetworkFarmItem(
        farmId: 'farm_demo_002',
        farmName: 'Sahyadri Poultry Centre',
        farmerName: 'Vikram Shinde',
        district: 'Nashik',
        livestockType: 'Layer (Babcock)',
        totalBirds: 14500,
        currentMortality: 12,
        mortalityTrend: '4.0x (Spike)',
        feedTrend: '-14.0%',
        riskLevel: 'critical',
        environmentalRisk: 'HIGH (34°C, 80%)',
        nearbyExposure: 'HIGH (10km cluster)',
        activeCases: 1,
        lastReportedAt: now.subtract(const Duration(hours: 1)),
      ),
      VetNetworkFarmItem(
        farmId: 'farm_demo_004',
        farmName: 'Shivneri Poultry Farm',
        farmerName: 'Anil Deshmukh',
        district: 'Nashik',
        livestockType: 'Broiler (35d)',
        totalBirds: 12000,
        currentMortality: 8,
        mortalityTrend: '2.6x (Elevated)',
        feedTrend: '-8.5%',
        riskLevel: 'high',
        environmentalRisk: 'ALERT (32°C, 75%)',
        nearbyExposure: 'MODERATE',
        activeCases: 1,
        lastReportedAt: now.subtract(const Duration(hours: 3)),
      ),
      VetNetworkFarmItem(
        farmId: 'farm_demo_003',
        farmName: 'Godavari Broiler Agro',
        farmerName: 'Sanjay More',
        district: 'Nashik',
        livestockType: 'Broiler (21d)',
        totalBirds: 8500,
        currentMortality: 2,
        mortalityTrend: 'Stable (1.0x)',
        feedTrend: 'Normal (+1%)',
        riskLevel: 'low',
        environmentalRisk: 'NORMAL (25°C, 62%)',
        nearbyExposure: 'LOW',
        activeCases: 0,
        lastReportedAt: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Dr. V. Sharma (Duty Clinician)';
    final activeVetId = widget.vetId ?? user?.uid ?? 'vet_dr_sharma';
    final vetState = ref.watch(veterinarianDashboardProvider(activeVetId));
    final districtName = widget.district ?? vetState.activeDistrict;

    final networkFarms = _getNetworkFarms();

    // Counts
    final totalFarms = networkFarms.length;
    final criticalFarms = networkFarms.where((f) => f.riskLevel == 'critical').length;
    final highFarms = networkFarms.where((f) => f.riskLevel == 'high').length;

    // Filter & Search
    final filteredFarms = networkFarms.where((f) {
      final matchesFilter = _riskFilter == 'ALL' || f.riskLevel.toUpperCase() == _riskFilter;
      final matchesSearch = f.farmName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f.farmerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f.district.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    // Default Critical first sorting
    filteredFarms.sort((a, b) {
      final order = {'critical': 0, 'high': 1, 'moderate': 2, 'low': 3};
      return (order[a.riskLevel] ?? 4).compareTo(order[b.riskLevel] ?? 4);
    });

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          WebPageHeader(
            title: 'Veterinarian Clinical Farm Network',
            subtitle: 'Attending: $displayName • Service District: $districtName • Which farms require clinical attention?',
            actions: [
              AppButton(
                label: 'Emergency Queue (${vetState.criticalCount})',
                icon: Icons.crisis_alert_rounded,
                size: AppButtonSize.small,
                variant: AppButtonVariant.primary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VeterinarianCriticalQueueScreen()),
                  );
                },
              ),
            ],
          ),

          // 2. Multi-Farm Network KPIs
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1100;
              final cardWidth = isNarrow ? (constraints.maxWidth - 20) / 3 : (constraints.maxWidth - 50) / 6;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: AnimatedKpiCard(
                      title: 'Total Service Farms',
                      numericValue: totalFarms,
                      suffix: 'Farms',
                      delta: '$districtName Zone',
                      isPositiveDelta: true,
                      subtitle: 'Active Assigned Network',
                      icon: Icons.hub_outlined,
                      accentColor: AppColors.primary,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: AnimatedKpiCard(
                      title: 'Critical Farms',
                      numericValue: criticalFarms,
                      suffix: 'Urgent',
                      delta: criticalFarms > 0 ? 'Action Req' : 'Clear',
                      isPositiveDelta: criticalFarms == 0,
                      isIncreaseNegative: true,
                      subtitle: 'Severe Anomaly / Spikes',
                      icon: Icons.crisis_alert_rounded,
                      accentColor: AppColors.critical,
                      isCritical: criticalFarms > 0,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: AnimatedKpiCard(
                      title: 'High Risk Farms',
                      numericValue: highFarms,
                      suffix: 'Elevated',
                      delta: 'Triage Queue',
                      isPositiveDelta: false,
                      subtitle: 'Clinical anomalies logged',
                      icon: Icons.warning_amber_rounded,
                      accentColor: AppColors.warning,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: AnimatedKpiCard(
                      title: 'Active Health Cases',
                      numericValue: vetState.criticalCount + vetState.pendingReviewCount,
                      suffix: 'Cases',
                      delta: 'Field Reports',
                      isPositiveDelta: true,
                      subtitle: 'Under Triage Protocol',
                      icon: Icons.medical_services_outlined,
                      accentColor: AppColors.info,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: AnimatedKpiCard(
                      title: 'Lab Diagnostics',
                      numericValue: vetState.labResultsReadyCount,
                      suffix: 'Ready',
                      delta: 'Assays Active',
                      isPositiveDelta: true,
                      subtitle: 'RT-PCR & Oocyst Tests',
                      icon: Icons.biotech_outlined,
                      accentColor: AppColors.primary,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: AnimatedKpiCard(
                      title: 'Follow-Ups Due',
                      numericValue: vetState.followUpsDueCount,
                      suffix: 'Due',
                      delta: '48h Checkpoints',
                      isPositiveDelta: true,
                      subtitle: 'Recovery verification',
                      icon: Icons.update_rounded,
                      accentColor: AppColors.healthy,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 3. Multi-Farm Risk Table
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Assigned & Service Area Poultry Farms', style: AppTypography.headingSmall),
                    // Filter Chips
                    Wrap(
                      spacing: 6,
                      children: ['ALL', 'CRITICAL', 'HIGH', 'MODERATE', 'LOW'].map((filter) {
                        final isSelected = _riskFilter == filter;
                        return ChoiceChip(
                          label: Text(filter, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _riskFilter = filter),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by farm name, farmer, or district...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 16),

                // Table
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredFarms.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final farm = filteredFarms[index];
                    return _buildFarmRow(farm);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFarmRow(VetNetworkFarmItem farm) {
    final isCritical = farm.riskLevel == 'critical';
    final isHigh = farm.riskLevel == 'high';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FarmClinicalViewScreen(
              farmId: farm.farmId,
              farmName: farm.farmName,
              farmerName: farm.farmerName,
              district: farm.district,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Risk Badge
            StatusBadge(
              label: farm.riskLevel.toUpperCase(),
              type: isCritical ? StatusBadgeType.critical : (isHigh ? StatusBadgeType.warning : StatusBadgeType.healthy),
            ),
            const SizedBox(width: 14),

            // Farm & Farmer
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(farm.farmName, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                  Text('Farmer: ${farm.farmerName} • ${farm.district}', style: AppTypography.caption),
                ],
              ),
            ),

            // Mortality & Trends
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mortality: ${farm.currentMortality} dead', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  Text(farm.mortalityTrend, style: TextStyle(fontSize: 11, color: isCritical ? AppColors.critical : AppColors.slate600)),
                ],
              ),
            ),

            // Telemetry & Corridor
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Env: ${farm.environmentalRisk}', style: AppTypography.caption),
                  Text('Corridor: ${farm.nearbyExposure}', style: TextStyle(fontSize: 11, color: AppColors.slate600)),
                ],
              ),
            ),

            // Action Button
            AppButton(
              label: 'Clinical Dossier',
              icon: Icons.open_in_new_rounded,
              size: AppButtonSize.small,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FarmClinicalViewScreen(
                      farmId: farm.farmId,
                      farmName: farm.farmName,
                      farmerName: farm.farmerName,
                      district: farm.district,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
