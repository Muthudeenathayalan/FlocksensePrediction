import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/health/presentation/screens/government_farm_surveillance_detail_screen.dart';

/// Managed Veterinarian Profile & District Coverage Record
class GovernmentVetRecord {
  final String vetId;
  final String name;
  final String registrationNumber;
  final String specialization;
  final String speciesExpertise;
  final String district;
  final String serviceArea;
  final int farmsCovered;
  final int criticalFarms;
  final int activeCases;
  final int pendingCases;
  final int averageAcceptanceMinutes;
  final int activeInvestigations;
  final int labCases;
  final int followUps;
  final String workload; // 'OPTIMAL', 'HEAVY', 'CRITICAL_LOAD'
  final String status; // 'Active Duty', 'On Call', 'Field Visit'

  const GovernmentVetRecord({
    required this.vetId,
    required this.name,
    required this.registrationNumber,
    this.specialization = 'Avian Disease Specialist',
    this.speciesExpertise = 'Commercial Broiler & Layer',
    required this.district,
    required this.serviceArea,
    required this.farmsCovered,
    required this.criticalFarms,
    required this.activeCases,
    required this.pendingCases,
    required this.averageAcceptanceMinutes,
    required this.activeInvestigations,
    required this.labCases,
    required this.followUps,
    required this.workload,
    required this.status,
  });
}

/// Government View: Veterinarian Detail & Assigned Farm Network (Part 12)
class GovernmentVeterinarianDetailScreen extends StatefulWidget {
  final String vetId;
  final GovernmentVetRecord? initialRecord;

  const GovernmentVeterinarianDetailScreen({
    super.key,
    required this.vetId,
    this.initialRecord,
  });

  @override
  State<GovernmentVeterinarianDetailScreen> createState() => _GovernmentVeterinarianDetailScreenState();
}

class _GovernmentVeterinarianDetailScreenState extends State<GovernmentVeterinarianDetailScreen> {
  late GovernmentVetRecord _vet;

  @override
  void initState() {
    super.initState();
    _vet = widget.initialRecord ??
        const GovernmentVetRecord(
          vetId: 'vet_dr_sharma',
          name: 'Dr. V. Sharma (Surgeon)',
          registrationNumber: 'MAH-VET-2018-04921',
          specialization: 'Avian Epidemiology & Pathology',
          speciesExpertise: 'Commercial Poultry & Breeder',
          district: 'Nashik',
          serviceArea: 'Dindori & Niphad Talukas',
          farmsCovered: 18,
          criticalFarms: 2,
          activeCases: 4,
          pendingCases: 1,
          averageAcceptanceMinutes: 14,
          activeInvestigations: 3,
          labCases: 2,
          followUps: 2,
          workload: 'OPTIMAL (4/8)',
          status: 'Active Duty',
        );
  }

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Breadcrumb
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Text('Veterinary Network', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.slate400)),
                Text(_vet.district, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.slate400)),
                Text(_vet.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Header
          WebPageHeader(
            title: _vet.name,
            subtitle: 'Registration: ${_vet.registrationNumber} • District: ${_vet.district} (${_vet.serviceArea}) • Specialty: ${_vet.specialization}',
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Text(
                  'DAHD • CLINICIAN CREDENTIALS VERIFIED',
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: _vet.status.toUpperCase(),
                type: StatusBadgeType.healthy,
              ),
            ],
          ),

          // 3. Performance & Workload KPIs
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 36) / 4;
              final isNarrow = constraints.maxWidth < 900;
              final itemWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : cardWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildKpiCard('Farms Covered', '${_vet.farmsCovered} Facilities', '${_vet.criticalFarms} Critical', const Color(0xFF15803D), itemWidth),
                  _buildKpiCard('Avg Acceptance Time', '${_vet.averageAcceptanceMinutes} Minutes', 'Target: <30 min', AppColors.healthy, itemWidth),
                  _buildKpiCard('Active Triage Queue', '${_vet.activeCases} Cases', '${_vet.pendingCases} Pending', _vet.pendingCases > 0 ? AppColors.warning : AppColors.info, itemWidth),
                  _buildKpiCard('Diagnostic Lab Pipeline', '${_vet.labCases} Lab Tests', '${_vet.followUps} Follow-ups', const Color(0xFF4F46E5), itemWidth),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // 4. Assigned Farms Network Table
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assigned Poultry Farm Facilities (${_vet.farmsCovered} Total)', style: AppTypography.headingSmall),
                Text('Click any farm to inspect authorized government surveillance dossier', style: AppTypography.bodySmall),
                const SizedBox(height: 16),

                _buildAssignedFarmItem(
                  farmId: 'farm_demo_001',
                  farmName: 'Green Valley Poultry Farm',
                  farmer: 'Ramesh Patil',
                  birds: '10,000 Broilers',
                  mortality: '15/day (5.0x spike)',
                  riskLevel: 'critical',
                ),
                const Divider(height: 1),
                _buildAssignedFarmItem(
                  farmId: 'farm_demo_002',
                  farmName: 'Sahyadri Poultry Centre',
                  farmer: 'Vikram Shinde',
                  birds: '14,500 Layers',
                  mortality: '12/day (4.0x spike)',
                  riskLevel: 'critical',
                ),
                const Divider(height: 1),
                _buildAssignedFarmItem(
                  farmId: 'farm_demo_004',
                  farmName: 'Shivneri Poultry Farm',
                  farmer: 'Anil Deshmukh',
                  birds: '12,000 Broilers',
                  mortality: '8/day (2.6x spike)',
                  riskLevel: 'high',
                ),
                const Divider(height: 1),
                _buildAssignedFarmItem(
                  farmId: 'farm_demo_003',
                  farmName: 'Godavari Broiler Agro',
                  farmer: 'Sanjay More',
                  birds: '8,500 Broilers',
                  mortality: '2/day (Stable)',
                  riskLevel: 'low',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String sub, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.caption),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.headingSmall.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sub, style: AppTypography.caption.copyWith(color: AppColors.slate600)),
        ],
      ),
    );
  }

  Widget _buildAssignedFarmItem({
    required String farmId,
    required String farmName,
    required String farmer,
    required String birds,
    required String mortality,
    required String riskLevel,
  }) {
    final isCritical = riskLevel == 'critical';
    final isHigh = riskLevel == 'high';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GovernmentFarmSurveillanceDetailScreen(
              farmId: farmId,
              farmName: farmName,
              district: _vet.district,
              assignedVetName: _vet.name,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            StatusBadge(
              label: riskLevel.toUpperCase(),
              type: isCritical ? StatusBadgeType.critical : (isHigh ? StatusBadgeType.warning : StatusBadgeType.healthy),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(farmName, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                  Text('Farmer: $farmer • $birds', style: AppTypography.caption),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(mortality, style: TextStyle(fontSize: 12, color: isCritical ? AppColors.critical : AppColors.slate700)),
            ),
            AppButton(
              label: 'Surveillance Dossier',
              icon: Icons.search_rounded,
              size: AppButtonSize.small,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GovernmentFarmSurveillanceDetailScreen(
                      farmId: farmId,
                      farmName: farmName,
                      district: _vet.district,
                      assignedVetName: _vet.name,
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
