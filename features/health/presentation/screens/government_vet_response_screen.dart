import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/health/presentation/screens/government_veterinarian_detail_screen.dart';

/// Government Veterinary Network Response & Workload Screen (Part 12)
/// Answers: Which veterinarians are handling which farms and how effectively?
class GovernmentVetResponseScreen extends StatefulWidget {
  const GovernmentVetResponseScreen({super.key});

  @override
  State<GovernmentVetResponseScreen> createState() => _GovernmentVetResponseScreenState();
}

class _GovernmentVetResponseScreenState extends State<GovernmentVetResponseScreen> {
  String _searchQuery = '';
  String _districtFilter = 'ALL';

  List<GovernmentVetRecord> _getVetNetwork() {
    return [
      const GovernmentVetRecord(
        vetId: 'vet_dr_sharma',
        name: 'Dr. V. Sharma',
        registrationNumber: 'MAH-VET-2018-04921',
        specialization: 'Avian Epidemiology & Pathology',
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
      ),
      const GovernmentVetRecord(
        vetId: 'vet_dr_deshmukh',
        name: 'Dr. Priya Deshmukh',
        registrationNumber: 'MAH-VET-2016-03120',
        specialization: 'Poultry Infectious Diseases',
        district: 'Nashik',
        serviceArea: 'Sinnar & Igatpuri Talukas',
        farmsCovered: 22,
        criticalFarms: 1,
        activeCases: 3,
        pendingCases: 0,
        averageAcceptanceMinutes: 18,
        activeInvestigations: 2,
        labCases: 1,
        followUps: 3,
        workload: 'OPTIMAL (3/8)',
        status: 'Active Duty',
      ),
      const GovernmentVetRecord(
        vetId: 'vet_dr_kulkarni',
        name: 'Dr. Rajesh Kulkarni',
        registrationNumber: 'MAH-VET-2012-01890',
        specialization: 'Commercial Broiler Health',
        district: 'Pune',
        serviceArea: 'Haveli & Baramati Talukas',
        farmsCovered: 31,
        criticalFarms: 0,
        activeCases: 2,
        pendingCases: 0,
        averageAcceptanceMinutes: 22,
        activeInvestigations: 1,
        labCases: 0,
        followUps: 4,
        workload: 'LIGHT (2/8)',
        status: 'On Call',
      ),
      const GovernmentVetRecord(
        vetId: 'vet_dr_patel',
        name: 'Dr. Ankit Patel',
        registrationNumber: 'MAH-VET-2020-06104',
        specialization: 'Avian Virology & Vaccinology',
        district: 'Nagpur',
        serviceArea: 'Kamptee & Hingna Talukas',
        farmsCovered: 16,
        criticalFarms: 1,
        activeCases: 5,
        pendingCases: 2,
        averageAcceptanceMinutes: 28,
        activeInvestigations: 3,
        labCases: 2,
        followUps: 1,
        workload: 'HEAVY (5/8)',
        status: 'Field Visit',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final allVets = _getVetNetwork();

    final filteredVets = allVets.where((v) {
      final matchesDistrict = _districtFilter == 'ALL' || v.district.toUpperCase() == _districtFilter;
      final matchesSearch = v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.district.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.registrationNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.serviceArea.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDistrict && matchesSearch;
    }).toList();

    final totalVets = allVets.length;
    final totalFarmsCovered = allVets.fold<int>(0, (s, v) => s + v.farmsCovered);
    final totalActiveCases = allVets.fold<int>(0, (s, v) => s + v.activeCases);
    final avgAcceptance = (allVets.fold<int>(0, (s, v) => s + v.averageAcceptanceMinutes) / totalVets).round();

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebPageHeader(
            title: 'State Veterinary Surveillance Network',
            subtitle: 'Which veterinarians are handling which farms and how effectively? • Field triage velocity & workload',
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Text(
                  '$totalVets Duty Clinicians Deployed',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                ),
              ),
            ],
          ),

          // KPIs
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 36) / 4;
              final isNarrow = constraints.maxWidth < 900;
              final itemWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : cardWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildKpiCard('Total Clinicians', '$totalVets Registered', '100% Licensed', const Color(0xFF15803D), itemWidth),
                  _buildKpiCard('Total Farms Covered', '$totalFarmsCovered Poultry Premises', 'Assigned Network', AppColors.healthy, itemWidth),
                  _buildKpiCard('Active Triage Caseload', '$totalActiveCases Incidents', 'Under Triage', AppColors.warning, itemWidth),
                  _buildKpiCard('State Avg Acceptance', '$avgAcceptance Minutes', 'Target: <30 min', AppColors.healthy, itemWidth),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Filters & Search
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Veterinarian Triage & Field Response Directory', style: AppTypography.headingSmall),
                    Wrap(
                      spacing: 6,
                      children: ['ALL', 'NASHIK', 'PUNE', 'NAGPUR'].map((dist) {
                        final isSelected = _districtFilter == dist;
                        return ChoiceChip(
                          label: Text(dist, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _districtFilter = dist),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by doctor name, registration ID, taluka, or district...',
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
                  itemCount: filteredVets.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final vet = filteredVets[index];
                    return _buildVetRow(vet);
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

  Widget _buildKpiCard(String title, String val, String sub, Color color, double width) {
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
          Text(val, style: AppTypography.headingSmall.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sub, style: AppTypography.caption.copyWith(color: AppColors.slate600)),
        ],
      ),
    );
  }

  Widget _buildVetRow(GovernmentVetRecord vet) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GovernmentVeterinarianDetailScreen(
              vetId: vet.vetId,
              initialRecord: vet,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Icon(Icons.person_pin_outlined, color: Color(0xFF15803D)),
            ),
            const SizedBox(width: 14),

            // Identity
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vet.name, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                  Text('${vet.registrationNumber} • ${vet.specialization}', style: AppTypography.caption),
                ],
              ),
            ),

            // District & Service Area
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${vet.district} District', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  Text(vet.serviceArea, style: AppTypography.caption),
                ],
              ),
            ),

            // Farms & Critical
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${vet.farmsCovered} Farms Covered', style: AppTypography.bodySmall),
                  Text(
                    vet.criticalFarms > 0 ? '${vet.criticalFarms} Critical Farms' : '0 Critical',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: vet.criticalFarms > 0 ? AppColors.critical : AppColors.healthy,
                    ),
                  ),
                ],
              ),
            ),

            // Acceptance Latency
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Avg Triage: ${vet.averageAcceptanceMinutes}m', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                  Text('Workload: ${vet.workload}', style: AppTypography.caption),
                ],
              ),
            ),

            // Action
            AppButton(
              label: 'Inspect Vet Network',
              icon: Icons.open_in_new_rounded,
              size: AppButtonSize.small,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GovernmentVeterinarianDetailScreen(
                      vetId: vet.vetId,
                      initialRecord: vet,
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
