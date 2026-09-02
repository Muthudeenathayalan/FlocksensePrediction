import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/providers/connectivity_provider.dart';
import 'package:flock_sense/core/services/sync_service.dart';
import 'package:flock_sense/core/widgets/adaptive_scaffold.dart';
import 'package:flock_sense/features/ai/presentation/screens/ai_screen.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_providers.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_list_screen.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/farms/presentation/providers/selected_farm_provider.dart';
import 'package:flock_sense/features/farms/presentation/screens/farm_list_screen.dart';
import 'package:flock_sense/features/feed/presentation/screens/feed_inventory_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/farmer_disease_alerts_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_biosecurity_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_cases_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_command_center_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_district_surveillance_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_gis_map_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_lab_surveillance_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_outbreak_registry_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_vaccination_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_vet_response_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/health_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/veterinarian_assigned_cases_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/veterinarian_critical_queue_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/veterinarian_disease_alerts_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/veterinarian_district_queue_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/veterinarian_follow_ups_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/veterinarian_investigations_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/veterinarian_lab_requests_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/veterinarian_lab_results_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/veterinarian_treatment_plans_screen.dart';
import 'package:flock_sense/features/home/presentation/screens/farmer_dashboard_screen.dart';
import 'package:flock_sense/features/home/presentation/screens/veterinarian_dashboard_screen.dart';
import 'package:flock_sense/features/inventory/presentation/screens/inventory_dashboard_screen.dart';
import 'package:flock_sense/features/medicine/presentation/screens/medicine_records_screen.dart';
import 'package:flock_sense/features/performance/presentation/screens/growth_analytics_screen.dart';
import 'package:flock_sense/features/profile/presentation/screens/profile_screen.dart';
import 'package:flock_sense/features/reports/presentation/screens/reports_dashboard_screen.dart';
import 'package:flock_sense/features/settings/presentation/screens/settings_dashboard_screen.dart';
import 'package:flock_sense/features/vaccine/presentation/screens/vaccine_records_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final String? initialRole;

  const MainShellScreen({
    super.key,
    this.initialRole,
  });

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;
  late String _currentRole;
  bool _hasCustomRole = false;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole ?? 'Farmer';
    if (widget.initialRole != null) {
      _hasCustomRole = true;
    }
  }

  String get _currentTitle {
    if (_currentRole == 'Government') {
      const govTitles = [
        'Command Center',
        'Disease Map',
        'Outbreaks',
        'District Surveillance',
        'Cases',
        'Vaccination Surveillance',
        'Biosecurity / Prevention',
        'Veterinary Response',
        'Laboratory Surveillance',
        'Analytics',
        'Reports',
        'Government Settings',
        'User Profile',
      ];
      if (_currentIndex < govTitles.length) return govTitles[_currentIndex];
    } else if (_currentRole == 'Veterinarian') {
      const vetTitles = [
        'Clinical Triage Dashboard',
        'Critical Emergency Queue',
        'Assigned Clinical Cases',
        'District Case Pool',
        'Clinical Investigations',
        'Diagnostic Lab Requests',
        'Laboratory Results',
        'Treatment Plans & Prescriptions',
        'Clinical Follow-Ups',
        'Regional Disease Alerts',
        'Epidemiological Analytics',
        'AI Clinical Assistant',
        'Veterinarian Settings',
        'Clinician Profile',
      ];
      if (_currentIndex < vetTitles.length) return vetTitles[_currentIndex];
    }
    const titles = [
      'Farmer Dashboard',
      'My Farms',
      'Flocks & Batches',
      'Daily Records',
      'Animal Health & Disease',
      'Vaccination Schedule',
      'Treatments & Prescriptions',
      'Disease Alerts & Biosecurity',
      'Feed & Water Operations',
      'Inventory Stock',
      'Reports & Export',
      'AI Health Assistant',
      'Growth & FCR Analytics',
      'System Settings',
      'User Profile',
    ];
    return _currentIndex < titles.length ? titles[_currentIndex] : 'FlockSense';
  }

  String? get _currentSubtitle {
    if (_currentRole == 'Government') {
      const govSubtitles = [
        'What requires Government attention right now? State animal health situation room & triage overview',
        'WHERE is animal-health risk occurring? Interactive GIS spatial map, cluster buffers & farm risk markers',
        'WHAT disease clusters are active and what evidence supports them? Cluster investigation & cordon control',
        'WHICH districts need attention first and WHY? Comparative risk ranking, velocity scores & drill-downs',
        'Which individual animal-health cases require surveillance attention? Clinical records & RT-PCR verification',
        'Where are vaccination gaps increasing vulnerability? District coverage, overdue schedules & cold chain tracking',
        'Where are preventable vulnerabilities highest? Farm barrier integrity, biosecurity score & sanitary audits',
        'How quickly and effectively are veterinary cases being handled? Response latency, triage & workload tracking',
        'What is the diagnostic pipeline status? Diagnostic sample tracking, viral RT-PCR assays & lab results',
        'What trends are emerging over time? Longitudinal epidemiological morbidity, mortality & disease curves',
        'What official/exportable surveillance summaries can Government generate? Sanitary bulletins & OIE/DAHD exports',
        'Surveillance thresholds, regional alerts configuration, and platform management',
        'Government officer credentials, district authority, and access profile',
      ];
      if (_currentIndex < govSubtitles.length) return govSubtitles[_currentIndex];
    } else if (_currentRole == 'Veterinarian') {
      const vetSubtitles = [
        'Which cases require clinical attention, what is most urgent, and what diagnostics are pending?',
        'Priority-1 health cases requiring immediate clinical intervention and isolation protocols',
        'Active caseload assigned to attending veterinarian • Triage, diagnosis, and care plans',
        'Regional queue of reported cases awaiting discovery and assignment by duty clinicians',
        'In-depth disease differential diagnosis, symptom progression, and treatment tracking',
        'Diagnostic sample chain-of-custody, cold-chain receipt verification, and testing queues',
        'Verified RT-PCR assays, pathogen isolation findings, and clinician confirmation sign-off',
        'Prescribed supportive care, pharmaceuticals, biosecurity cordons, and withdrawal periods',
        'Track flock recovery progression, farmer compliance with treatment regimens, and discharge',
        'Regional epidemiological alerts, syndromic anomalies, and multi-farm containment zones',
        'Longitudinal morbidity patterns, regional pathogen trends, and treatment efficacy curves',
        'Differential diagnosis support, pathogen literature, and clinical decision intelligence',
        'Veterinary credentials, clinical alert thresholds, and queue sorting preferences',
        'Clinician identity, licensing credentials, and contact configuration',
      ];
      if (_currentIndex < vetSubtitles.length) return vetSubtitles[_currentIndex];
    }
    const subtitles = [
      'Live poultry farm health overview, flock performance, and active clinical alerts',
      'Select and manage multi-shed poultry farm facilities',
      'Monitor batch lifecycles, breed targets, and mortality status',
      'High-speed logging for daily mortality, feed, and water consumption',
      'Early disease detection, clinical health cases, and veterinary review',
      'Immunization schedules, overdue alerts, and flock protection status',
      'Prescribed medications, dosage tracking, and withdrawal periods',
      'Real-time anomaly detection, disease alerts, and bio-security index',
      'Feed distribution, silo monitoring, and water consumption trends',
      'Vaccine stock, medical supplies, and inventory replenishment',
      'Generate and download official PDF audit logs, CSVs, and reports',
      'Clinical risk scoring, symptom analysis, and veterinary support',
      'Growth curves, Uniformity %, and Feed Conversion Ratio (FCR)',
      'System configuration, threshold alerts, and cloud sync status',
      'User account credentials, farm association, and security',
    ];
    return _currentIndex < subtitles.length ? subtitles[_currentIndex] : null;
  }

  List<Widget> _buildScreens(ActiveFarmContext activeFarm) {
    if (_currentRole == 'Government') {
      return [
        const GovernmentCommandCenterScreen(), // 0: Command Center
        const GovernmentGisMapScreen(), // 1: Disease Map
        const GovernmentOutbreakRegistryScreen(), // 2: Outbreaks
        const GovernmentDistrictSurveillanceScreen(), // 3: District Surveillance
        const GovernmentCasesScreen(), // 4: Cases
        const GovernmentVaccinationScreen(), // 5: Vaccination Surveillance
        const GovernmentBiosecurityScreen(), // 6: Biosecurity / Prevention
        const GovernmentVetResponseScreen(), // 7: Veterinary Response
        const GovernmentLabSurveillanceScreen(), // 8: Laboratory Surveillance
        const GrowthAnalyticsScreen(), // 9: Analytics
        const ReportsDashboardScreen(), // 10: Reports
        const SettingsDashboardScreen(currentRole: 'Government'), // 11: Settings
        const ProfileScreen(), // 12: Profile
      ];
    } else if (_currentRole == 'Veterinarian') {
      return [
        const VeterinarianDashboardScreen(), // 0: Clinical Triage Dashboard
        const VeterinarianCriticalQueueScreen(), // 1: Critical Queue
        const VeterinarianAssignedCasesScreen(), // 2: Assigned Cases
        const VeterinarianDistrictQueueScreen(), // 3: District Pool
        const VeterinarianInvestigationsScreen(), // 4: Investigations
        const VeterinarianLabRequestsScreen(), // 5: Lab Requests
        const VeterinarianLabResultsScreen(), // 6: Lab Results
        const VeterinarianTreatmentPlansScreen(), // 7: Treatment Plans
        const VeterinarianFollowUpsScreen(), // 8: Follow-ups
        const VeterinarianDiseaseAlertsScreen(), // 9: Disease Alerts
        const GrowthAnalyticsScreen(), // 10: Analytics & Trends
        const AiScreen(), // 11: AI Assistant
        const SettingsDashboardScreen(currentRole: 'Veterinarian'), // 12: Settings
        const ProfileScreen(), // 13: Profile
      ];
    }
    return [
      const FarmerDashboardScreen(), // 0: Dashboard
      const FarmListScreen(), // 1: My Farms
      BatchListScreen(farmId: activeFarm.farmId, farmName: activeFarm.farmName), // 2: Flocks & Batches
      const DailyRecordsDashboardScreen(), // 3: Daily Records
      const HealthScreen(), // 4: Health & Disease
      const VaccineRecordsScreen(), // 5: Vaccination
      const MedicineRecordsScreen(), // 6: Treatments
      const FarmerDiseaseAlertsScreen(), // 7: Disease Alerts & Biosecurity
      FeedInventoryScreen(farmId: activeFarm.farmId, batchId: activeFarm.batchId ?? 'batch_demo_001', batchName: activeFarm.batchName), // 8: Feed & Water
      const InventoryDashboardScreen(), // 9: Inventory Stock
      const ReportsDashboardScreen(), // 10: Reports & Export
      const AiScreen(), // 11: AI Assistant
      const GrowthAnalyticsScreen(), // 12: Analytics & FCR
      const SettingsDashboardScreen(currentRole: 'Farmer'), // 13: Settings
      const ProfileScreen(), // 14: Profile
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeFarm = ref.watch(activeFarmContextProvider);
    // Synchronize authoritative role from Firebase Profile unless explicitly overridden
    final authProfile = ref.watch(currentUserProfileProvider).value;
    if (authProfile != null && !_hasCustomRole) {
      final authoritativeRole = authProfile.role.label.split(' ').first; // 'Farmer', 'Veterinarian', 'Government'
      if (_currentRole != authoritativeRole) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentRole = authoritativeRole;
            });
          }
        });
      }
    }

    // Listen for network reconnect and sync pending offline operations
    ref.listen(connectivityProvider, (prev, next) {
      final wasOnline =
          prev?.maybeWhen(data: (v) => v, orElse: () => true) ?? true;
      final nowOnline = next.maybeWhen(data: (v) => v, orElse: () => true);
      if (!wasOnline && nowOnline) {
        SyncService().syncPendingOperations();
      }
    });

    return AdaptiveScaffold(
      selectedIndex: _currentIndex,
      onDestinationSelected: _navigateToTab,
      title: _currentTitle,
      subtitle: _currentSubtitle,
      currentRole: _currentRole,
      onRoleChanged: (newRole) {
        setState(() {
          _hasCustomRole = true;
          _currentRole = newRole;
          _currentIndex = 0; // Return to dashboard / command center for the selected role
        });
      },
      body: IndexedStack(
        index: _currentIndex,
        children: _buildScreens(activeFarm),
      ),
    );
  }

  void _navigateToTab(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
  }
}
