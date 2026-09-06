import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/health/data/government_surveillance_service.dart';
import 'package:flock_sense/features/health/domain/district_surveillance_model.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/shared/analytics/animated_bar_chart.dart';
import 'package:flock_sense/shared/analytics/animated_chart_container.dart';
import 'package:flock_sense/shared/analytics/animated_kpi_card.dart';

/// Government Surveillance Page 3: District Surveillance & Drill-down
/// Answers: WHICH districts need attention first and WHY?
class GovernmentDistrictSurveillanceScreen extends StatefulWidget {
  const GovernmentDistrictSurveillanceScreen({super.key});

  @override
  State<GovernmentDistrictSurveillanceScreen> createState() =>
      _GovernmentDistrictSurveillanceScreenState();
}

class _GovernmentDistrictSurveillanceScreenState
    extends State<GovernmentDistrictSurveillanceScreen> {
  String _searchQuery = '';
  String _riskFilter = 'All';
  String _sortBy = 'Risk Score (High to Low)';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DistrictSurveillanceSummary>>(
      stream: GovernmentSurveillanceService.streamDistrictSummaries(),
      builder: (context, snapshot) {
        final rawList = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting && rawList.isEmpty;

        // Summary metrics
        final totalDistricts = rawList.length;
        final criticalDistricts = rawList.where((d) => d.districtRiskLevel == HealthRiskLevel.critical).length;
        final highRiskDistricts = rawList.where((d) => d.districtRiskLevel == HealthRiskLevel.high).length;
        final withClusters = rawList.where((d) => d.activeClusters > 0).length;

        // Filter and Sort
        var filteredList = rawList.where((d) {
          final matchesSearch = d.district.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.state.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesRisk = _riskFilter == 'All' ||
              d.districtRiskLevel.name.toLowerCase() == _riskFilter.toLowerCase();
          return matchesSearch && matchesRisk;
        }).toList();

        filteredList.sort((a, b) {
          if (_sortBy == 'Risk Score (High to Low)') {
            return b.districtRiskScore.compareTo(a.districtRiskScore);
          } else if (_sortBy == 'Active Cases') {
            return b.activeCases.compareTo(a.activeCases);
          } else if (_sortBy == 'Mortality Count') {
            return b.mortalityCount.compareTo(a.mortalityCount);
          } else if (_sortBy == 'Vaccination (Low to High)') {
            return a.vaccinationCoveragePercent.compareTo(b.vaccinationCoveragePercent);
          }
          return a.district.compareTo(b.district);
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesign.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description banner
              AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Icon(Icons.analytics_outlined, color: Color(0xFF15803D), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('District Surveillance & Epidemiological Triage', style: AppTypography.pageTitle),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF86EFAC)),
                                ),
                                child: const Text(
                                  'DAHD • EPIDEMIOLOGICAL TRIAGE',
                                  style: TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Algorithmic risk scoring prioritizes districts requiring immediate containment cordons, field veterinary deployment, and vaccination surge.',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Top 4 Animated Summary Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 48) / 4;
                  final isNarrow = constraints.maxWidth < 800;
                  final width = isNarrow ? constraints.maxWidth : cardWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: width,
                        child: AnimatedKpiCard(
                          title: 'Districts Monitored',
                          numericValue: totalDistricts,
                          suffix: 'Admin Zones',
                          delta: 'State Coverage',
                          isPositiveDelta: true,
                          subtitle: 'Verified administrative bounds',
                          icon: Icons.location_city_rounded,
                          accentColor: const Color(0xFF15803D),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: AnimatedKpiCard(
                          title: 'Critical Alert Zones',
                          numericValue: criticalDistricts,
                          suffix: 'Districts',
                          delta: criticalDistricts > 0 ? 'P1 Action' : 'Zero Critical',
                          isPositiveDelta: criticalDistricts == 0,
                          isIncreaseNegative: true,
                          subtitle: 'Immediate cordon required',
                          icon: Icons.error_outline_rounded,
                          accentColor: AppColors.critical,
                          isCritical: criticalDistricts > 0,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: AnimatedKpiCard(
                          title: 'High Risk Surveillance',
                          numericValue: highRiskDistricts,
                          suffix: 'Districts',
                          delta: 'Heightened',
                          isPositiveDelta: false,
                          isIncreaseNegative: true,
                          subtitle: 'Targeted field testing',
                          icon: Icons.warning_amber_rounded,
                          accentColor: AppColors.highRisk,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: AnimatedKpiCard(
                          title: 'Active Outbreak Clusters',
                          numericValue: withClusters,
                          suffix: 'Clusters',
                          delta: withClusters > 0 ? 'Multi-Farm' : 'None',
                          isPositiveDelta: withClusters == 0,
                          isIncreaseNegative: true,
                          subtitle: 'Spatial transmission cordons',
                          icon: Icons.hub_outlined,
                          accentColor: AppColors.indigo,
                          isCritical: withClusters > 0,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Animated District Risk Overview Bar Chart
              AnimatedChartContainer(
                title: 'Statewide District Epidemiological Risk Comparison',
                subtitle: 'Comparative algorithm risk score (0–100) and vaccination coverage across surveyed districts',
                timeRanges: const [],
                height: 210,
                child: AnimatedBarChart(
                  maxY: 100,
                  unit: ' pts',
                  items: rawList.map((d) {
                    Color c = AppColors.healthy;
                    if (d.districtRiskScore >= 75) c = AppColors.critical;
                    else if (d.districtRiskScore >= 50) c = AppColors.highRisk;
                    else if (d.districtRiskScore >= 25) c = AppColors.warning;
                    return BarChartItemData(
                      label: d.district,
                      value: d.districtRiskScore.toDouble(),
                      color: c,
                      payload: d,
                    );
                  }).toList(),
                  onItemSelected: (payload) {
                    if (payload is DistrictSurveillanceSummary) {
                      _openDistrictDrilldownModal(payload);
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Filter & Search Controls
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search district by name (e.g. Nashik, Pune, Ahmednagar)...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _riskFilter,
                      underline: const SizedBox(),
                      items: ['All', 'Critical', 'High', 'Moderate', 'Low']
                          .map((r) => DropdownMenuItem(value: r, child: Text('Risk: $r')))
                          .toList(),
                      onChanged: (v) => setState(() => _riskFilter = v ?? 'All'),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox(),
                      items: ['Risk Score (High to Low)', 'Active Cases', 'Mortality Count', 'Vaccination (Low to High)']
                          .map((s) => DropdownMenuItem(value: s, child: Text('Sort: $s')))
                          .toList(),
                      onChanged: (v) => setState(() => _sortBy = v ?? 'Risk Score (High to Low)'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Main District Ranking Table
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('District Health Vulnerability Rankings (Highest Risk First)', style: AppTypography.cardTitle),
                    const SizedBox(height: 12),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (filteredList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No districts matching selected filter criteria.')),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 20,
                          horizontalMargin: 12,
                          columns: const [
                            DataColumn(label: Text('District', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Risk Tier', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Risk Score', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Clusters', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Critical Cases', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Farms at Risk', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Affected / Dead', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Vaccination', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Avg Vet Response', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredList.map((d) {
                            final isCrit = d.districtRiskLevel == HealthRiskLevel.critical;
                            final isHigh = d.districtRiskLevel == HealthRiskLevel.high;
                            final tierColor = isCrit
                                ? AppColors.critical
                                : isHigh
                                    ? AppColors.highRisk
                                    : d.districtRiskLevel == HealthRiskLevel.moderate
                                        ? AppColors.warning
                                        : AppColors.healthy;

                            return DataRow(
                              color: WidgetStateProperty.resolveWith<Color?>((states) {
                                if (isCrit) return AppColors.criticalBg.withOpacity(0.3);
                                return null;
                              }),
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(d.district, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.slate900)),
                                      Text(d.state, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  StatusBadge.fromStatus(d.districtRiskLevel.name.toUpperCase()),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      Text('${d.districtRiskScore}/100', style: TextStyle(fontWeight: FontWeight.w800, color: tierColor)),
                                      const SizedBox(width: 6),
                                      SizedBox(
                                        width: 40,
                                        child: LinearProgressIndicator(
                                          value: d.districtRiskScore / 100.0,
                                          backgroundColor: AppColors.slate200,
                                          valueColor: AlwaysStoppedAnimation(tierColor),
                                          minHeight: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    d.activeClusters > 0 ? '${d.activeClusters} Active' : 'None',
                                    style: TextStyle(
                                      fontWeight: d.activeClusters > 0 ? FontWeight.w700 : FontWeight.normal,
                                      color: d.activeClusters > 0 ? AppColors.critical : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${d.criticalCases}',
                                    style: TextStyle(
                                      fontWeight: d.criticalCases > 0 ? FontWeight.w700 : FontWeight.normal,
                                      color: d.criticalCases > 0 ? AppColors.critical : AppColors.slate900,
                                    ),
                                  ),
                                ),
                                DataCell(Text('${d.farmsAtRisk} Facilities')),
                                DataCell(Text('${d.affectedCount} / ${d.mortalityCount}')),
                                DataCell(
                                  Text(
                                    '${d.vaccinationCoveragePercent.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: d.vaccinationCoveragePercent < 75 ? AppColors.critical : AppColors.healthy,
                                    ),
                                  ),
                                ),
                                DataCell(Text('${d.averageVetResponseTimeMinutes} mins')),
                                DataCell(
                                  AppButton(
                                    label: 'View District',
                                    size: AppButtonSize.small,
                                    variant: AppButtonVariant.outlined,
                                    onPressed: () => _openDistrictDrilldownModal(d),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, double width) {
    return SizedBox(
      width: width,
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.kpiLabel),
                  const SizedBox(height: 2),
                  Text(value, style: AppTypography.cardTitle.copyWith(color: AppColors.slate900, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDistrictDrilldownModal(DistrictSurveillanceSummary d) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 760,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('${d.district.toUpperCase()} DISTRICT', style: AppTypography.sectionTitle),
                            const SizedBox(width: 12),
                            StatusBadge.fromStatus(d.districtRiskLevel.name.toUpperCase()),
                          ],
                        ),
                        Text('${d.state} State • District Surveillance Deep-Dive Dossier', style: AppTypography.bodySmall),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(height: 28),

                // Key metrics row
                Row(
                  children: [
                    _buildModalKpi('Risk Score', '${d.districtRiskScore}/100', AppColors.critical),
                    const SizedBox(width: 12),
                    _buildModalKpi('Active Clusters', '${d.activeClusters}', AppColors.indigo),
                    const SizedBox(width: 12),
                    _buildModalKpi('Critical Cases', '${d.criticalCases}', AppColors.critical),
                    const SizedBox(width: 12),
                    _buildModalKpi('Farms at Risk', '${d.farmsAtRisk}', AppColors.warning),
                    const SizedBox(width: 12),
                    _buildModalKpi('Vaccination', '${d.vaccinationCoveragePercent}%', AppColors.healthy),
                  ],
                ),
                const SizedBox(height: 20),

                // Algorithmic Risk Evidence Factors
                Text('Epidemiological Risk Evidence & Drivers', style: AppTypography.cardTitle),
                const SizedBox(height: 8),
                if (d.riskReasons.isNotEmpty)
                  ...d.riskReasons.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppColors.critical, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(r, style: AppTypography.bodySmall)),
                          ],
                        ),
                      ))
                else
                  Text(
                    '• High mortality velocity detected in commercial layer belt (3.8x baseline).\n• Multi-farm spatial clustering detected within 6.8 km.\n• Vaccination coverage below 75% target threshold in adjacent blocks.\n• RT-PCR lab confirmation pending for Newcastle Disease (NDV).',
                    style: AppTypography.bodySmall,
                  ),
                const SizedBox(height: 20),

                // Response Actions
                Text('Recommended State Interventions', style: AppTypography.cardTitle),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('1. Deploy Rapid Response Field Veterinary Mobile Unit to central cluster coordinates.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('2. Issue mandatory 5km live poultry movement restrictions across vulnerable wards.', style: TextStyle(fontSize: 12)),
                      SizedBox(height: 4),
                      Text('3. Initiate emergency booster ring-vaccination for 14 commercial farms within buffer perimeter.', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      label: 'Close Dossier',
                      variant: AppButtonVariant.outlined,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'Export District OIE Report',
                      icon: Icons.file_download_outlined,
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Exporting official epidemiological dossier for ${d.district}...'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
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

  Widget _buildModalKpi(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
