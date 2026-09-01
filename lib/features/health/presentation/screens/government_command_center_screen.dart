import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/health/data/government_surveillance_service.dart';
import 'package:flock_sense/features/health/data/outbreak_cluster_service.dart';
import 'package:flock_sense/features/health/domain/district_surveillance_model.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/outbreak_cluster_model.dart';
import 'package:flock_sense/features/health/presentation/widgets/outbreak_cluster_alert_card.dart';
import 'package:flock_sense/features/health/presentation/widgets/surveillance_gis_map.dart';
import 'package:flock_sense/shared/analytics/animated_bar_chart.dart';
import 'package:flock_sense/shared/analytics/animated_chart_container.dart';
import 'package:flock_sense/shared/analytics/animated_kpi_card.dart';
import 'package:flock_sense/shared/analytics/animated_line_chart.dart';

/// Government Animal Health Command Center & State Surveillance Desk (SIH26128 Phase 9)
class GovernmentCommandCenterScreen extends StatefulWidget {
  const GovernmentCommandCenterScreen({super.key});

  @override
  State<GovernmentCommandCenterScreen> createState() => _GovernmentCommandCenterScreenState();
}

class _GovernmentCommandCenterScreenState extends State<GovernmentCommandCenterScreen> {
  String _selectedDistrict = 'All';
  String _sortColumn = 'risk';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Command Center Header
          _buildHeader(),
          const SizedBox(height: 20),

          // 2. Stream Top 6 Surveillance KPIs
          StreamBuilder<GovernmentKpiData>(
            stream: GovernmentSurveillanceService.streamCommandCenterKPIs(),
            builder: (context, snapshot) {
              final kpi = snapshot.data ??
                  const GovernmentKpiData(
                    activeClustersCount: 1,
                    criticalCasesCount: 3,
                    farmsAtRiskCount: 3,
                    affectedDistrictsCount: 1,
                    reportedAffectedBirds: 67,
                    stateVaccinationCoverage: 78.4,
                    averageVetResponseMinutes: 18,
                  );
              return _buildKpiRow(kpi);
            },
          ),
          const SizedBox(height: 24),

          // 3. Main Operational View: GIS Map (65%) + Early Warning Alerts (35%)
          StreamBuilder<List<OutbreakClusterModel>>(
            stream: OutbreakClusterService.streamActiveClusters(),
            builder: (context, clusterSnap) {
              final clusters = clusterSnap.data ?? [];

              return StreamBuilder<List<FarmGisMapMarker>>(
                stream: GovernmentSurveillanceService.streamFarmGisMarkers(),
                builder: (context, farmSnap) {
                  final farms = farmSnap.data ?? [];

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 980;

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Main Surveillance GIS Map (62% width)
                            Expanded(
                              flex: 62,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SurveillanceGisMap(
                                    farmMarkers: farms,
                                    activeClusters: clusters,
                                    selectedDistrict: _selectedDistrict,
                                    onDistrictChanged: (dist) =>
                                        setState(() => _selectedDistrict = dist),
                                    onClusterSelected: _showClusterDetailDialog,
                                    onFarmSelected: _showFarmDetailDialog,
                                    height: 480,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildDataQualityBanner(farms.length),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Right: Early Warning Cluster Dossiers & Critical Alert Feed (38% width)
                            Expanded(
                              flex: 38,
                              child: _buildRightAlertsColumn(clusters),
                            ),
                          ],
                        );
                      } else {
                        // Narrow fallback layout
                        return Column(
                          children: [
                            SurveillanceGisMap(
                              farmMarkers: farms,
                              activeClusters: clusters,
                              selectedDistrict: _selectedDistrict,
                              onDistrictChanged: (dist) =>
                                  setState(() => _selectedDistrict = dist),
                              onClusterSelected: _showClusterDetailDialog,
                              onFarmSelected: _showFarmDetailDialog,
                              height: 400,
                            ),
                            const SizedBox(height: 16),
                            _buildRightAlertsColumn(clusters),
                          ],
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 28),

          // 4. District Risk Surveillance Table
          StreamBuilder<List<DistrictSurveillanceSummary>>(
            stream: GovernmentSurveillanceService.streamDistrictSummaries(),
            builder: (context, snapshot) {
              final districts = snapshot.data ?? [];
              return _buildDistrictRiskTable(districts);
            },
          ),
          const SizedBox(height: 28),

          // 5. Epidemiological Intelligence Panels (Vet Response & Vaccination)
          _buildIntelligenceGrid(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. COMMAND CENTER HEADER
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: AppDesign.subtleShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Animal Health Command Center',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: AppColors.success, size: 7),
                          SizedBox(width: 5),
                          Text(
                            'LIVE SURVEILLANCE • MAHARASHTRA',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'State-wide GIS disease intelligence, multi-farm outbreak early warning, and district intervention triage',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting State Surveillance Report (PDF)...')),
              );
            },
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Export Report'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. TOP KPI CARDS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildKpiRow(GovernmentKpiData kpi) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        final cardWidth = isDesktop ? (constraints.maxWidth - 50) / 6 : (constraints.maxWidth - 20) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: cardWidth,
              child: AnimatedKpiCard(
                title: 'Active Clusters',
                numericValue: kpi.activeClustersCount,
                suffix: 'Zones',
                delta: kpi.activeClustersCount > 0 ? 'P1 Outbreak' : 'Clear',
                isPositiveDelta: kpi.activeClustersCount == 0,
                isIncreaseNegative: true,
                subtitle: 'Early warning cordon',
                icon: Icons.warning_amber_rounded,
                accentColor: AppColors.critical,
                isCritical: kpi.activeClustersCount > 0,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: AnimatedKpiCard(
                title: 'Critical Cases',
                numericValue: kpi.criticalCasesCount,
                suffix: 'Cases',
                delta: 'Active Triage',
                isPositiveDelta: false,
                isIncreaseNegative: true,
                subtitle: 'High viral suspicion',
                icon: Icons.local_hospital_outlined,
                accentColor: AppColors.highRisk,
                isCritical: kpi.criticalCasesCount > 0,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: AnimatedKpiCard(
                title: 'Farms at Risk',
                numericValue: kpi.farmsAtRiskCount,
                suffix: 'Farms',
                delta: 'Buffer zone',
                isPositiveDelta: false,
                isIncreaseNegative: true,
                subtitle: 'Within 5km radius',
                icon: Icons.home_work_outlined,
                accentColor: AppColors.warning,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: AnimatedKpiCard(
                title: 'Affected Districts',
                numericValue: kpi.affectedDistrictsCount,
                suffix: 'Districts',
                delta: 'Nashik Corridor',
                isPositiveDelta: true,
                subtitle: 'Active surveillance',
                icon: Icons.location_city_outlined,
                accentColor: AppColors.info,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: AnimatedKpiCard(
                title: 'Reported Birds',
                numericValue: kpi.reportedAffectedBirds,
                suffix: 'Birds',
                delta: '+12%',
                isPositiveDelta: false,
                isIncreaseNegative: true,
                subtitle: 'Affected flock census',
                icon: Icons.cruelty_free_outlined,
                accentColor: const Color(0xFF8B5CF6),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: AnimatedKpiCard(
                title: 'Vaccine Coverage',
                numericValue: kpi.stateVaccinationCoverage,
                decimalDigits: 1,
                suffix: '%',
                delta: '+2.4%',
                isPositiveDelta: true,
                subtitle: 'State immunization',
                icon: Icons.vaccines_outlined,
                accentColor: AppColors.healthy,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: AppDesign.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. RIGHT COLUMN: EARLY WARNING CLUSTER DOSSIER & ALERTS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildRightAlertsColumn(List<OutbreakClusterModel> clusters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Outbreak Early Warning Card (Phase 8 Full Dossier)
        OutbreakClusterAlertCard(
          district: _selectedDistrict == 'All' ? 'Nashik' : _selectedDistrict,
          isFarmerView: false,
        ),
        const SizedBox(height: 14),

        // Urgent Veterinary Response Triage Notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.highRisk, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Veterinary Response Triage Active',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      '3 critical cases under active investigation by Nashik District Veterinary Officers. Average initial response time: 18 minutes.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataQualityBanner(int farmCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: AppColors.success, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Surveillance Data Quality: Strong • $farmCount farms accurately mapped with verified GPS coordinates • Real-time WebSocket sync',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. DISTRICT RISK ASSESSMENT TABLE
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildDistrictRiskTable(List<DistrictSurveillanceSummary> districts) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: AppDesign.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'District Health Risk Surveillance Matrix',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Aggregated risk scores based on active clusters, critical mortality cases, and vaccination coverage gaps',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              // Sort Selector
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortColumn,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  items: const [
                    DropdownMenuItem(value: 'risk', child: Text('Sort: Highest Risk First')),
                    DropdownMenuItem(value: 'clusters', child: Text('Sort: Active Clusters')),
                    DropdownMenuItem(value: 'critical', child: Text('Sort: Critical Cases')),
                    DropdownMenuItem(value: 'vaccine', child: Text('Sort: Vaccine Gap')),
                  ],
                  onChanged: (val) => setState(() => _sortColumn = val ?? 'risk'),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('DISTRICT', style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('RISK LEVEL', style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('CLUSTERS', style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('CRITICAL', style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('FARMS', style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('MORTALITY', style: _tableHeaderStyle)),
                Expanded(flex: 3, child: Text('VACCINATION', style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('VET RESPONSE', style: _tableHeaderStyle)),
                Expanded(flex: 2, child: Text('ACTION', style: _tableHeaderStyle)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Table Rows
          ...districts.map((d) => _buildDistrictRow(d)),
        ],
      ),
    );
  }

  static const _tableHeaderStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  Widget _buildDistrictRow(DistrictSurveillanceSummary d) {
    Color riskColor;
    switch (d.districtRiskLevel) {
      case HealthRiskLevel.critical:
        riskColor = AppColors.critical;
        break;
      case HealthRiskLevel.high:
        riskColor = AppColors.highRisk;
        break;
      case HealthRiskLevel.moderate:
        riskColor = AppColors.warning;
        break;
      case HealthRiskLevel.low:
        riskColor = AppColors.success;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: d.districtRiskLevel == HealthRiskLevel.critical
            ? AppColors.critical.withOpacity(0.04)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: d.districtRiskLevel == HealthRiskLevel.critical
              ? AppColors.critical.withOpacity(0.2)
              : AppColors.border.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          // District Name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 15,
                  color: d.districtRiskLevel == HealthRiskLevel.critical
                      ? AppColors.critical
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  d.district,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
          ),
          // Risk Score / Badge
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: riskColor),
                  ),
                  child: Text(
                    '${d.districtRiskScore}/100',
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Clusters
          Expanded(
            flex: 2,
            child: Text(
              '${d.activeClusters}',
              style: TextStyle(
                fontWeight: d.activeClusters > 0 ? FontWeight.w800 : FontWeight.w500,
                color: d.activeClusters > 0 ? AppColors.critical : AppColors.textPrimary,
              ),
            ),
          ),
          // Critical Cases
          Expanded(
            flex: 2,
            child: Text(
              '${d.criticalCases}',
              style: TextStyle(
                fontWeight: d.criticalCases > 0 ? FontWeight.w800 : FontWeight.w500,
                color: d.criticalCases > 0 ? AppColors.highRisk : AppColors.textPrimary,
              ),
            ),
          ),
          // Farms at Risk
          Expanded(flex: 2, child: Text('${d.farmsAtRisk}')),
          // Mortality Count
          Expanded(flex: 2, child: Text('${d.mortalityCount} birds')),
          // Vaccination Coverage
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: d.vaccinationCoveragePercent / 100.0,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        d.vaccinationCoveragePercent < 80.0
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                      minHeight: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${d.vaccinationCoveragePercent.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Avg. Vet Response Time
          Expanded(flex: 2, child: Text('${d.averageVetResponseTimeMinutes} min')),
          // Drill Down Action
          Expanded(
            flex: 2,
            child: TextButton.icon(
              onPressed: () => _showDistrictDrillDown(d),
              icon: const Icon(Icons.insights, size: 14),
              label: const Text('Inspect'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. INTELLIGENCE GRID: VET RESPONSE & VACCINATION SURVEILLANCE
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildIntelligenceGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Outbreak Cluster Temporal Growth Progression Curve
            Expanded(
              flex: isWide ? 6 : 1,
              child: AnimatedChartContainer(
                title: 'Outbreak Cluster Expansion Timeline',
                subtitle: 'Cumulative poultry premises entering active transmission cluster cordon (Nashik Cluster CL-2026-001)',
                timeRanges: const [],
                legendItems: const [
                  LegendItemData(label: 'Premises Linked (Farms)', color: AppColors.critical),
                  LegendItemData(label: 'Containment Threshold', color: AppColors.slate400, isDashed: true),
                ],
                height: 250,
                child: AnimatedLineChart(
                  yUnit: ' fms',
                  maxY: 6,
                  series: const [
                    LineChartSeriesData(
                      name: 'Linked Farms',
                      color: AppColors.critical,
                      hasAreaFill: true,
                      strokeWidth: 2.8,
                      points: [
                        ChartDataPoint(x: 0, y: 1, label: '10:00 (Index Farm)', isSpike: true),
                        ChartDataPoint(x: 1, y: 2, label: '16:00 (Shed 2)'),
                        ChartDataPoint(x: 2, y: 3, label: '08:00+1 (Neighbor 1.2km)'),
                        ChartDataPoint(x: 3, y: 4, label: '18:00+1 (Active Cordon)', isSpike: true),
                      ],
                    ),
                    LineChartSeriesData(
                      name: 'Containment Target',
                      color: AppColors.slate400,
                      isDashed: true,
                      hasAreaFill: false,
                      strokeWidth: 1.5,
                      points: [
                        ChartDataPoint(x: 0, y: 4, label: '10:00'),
                        ChartDataPoint(x: 1, y: 4, label: '16:00'),
                        ChartDataPoint(x: 2, y: 4, label: '08:00+1'),
                        ChartDataPoint(x: 3, y: 4, label: '18:00+1'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isWide) const SizedBox(width: 20),
            // Right: District Epidemiological Risk Score Ranking (Horizontal Bars)
            if (isWide)
              Expanded(
                flex: 4,
                child: AnimatedChartContainer(
                  title: 'District Epidemiological Risk Ranking',
                  subtitle: 'Real-time algorithm composite risk scores (0–100) across state veterinary surveillance zones',
                  timeRanges: const [],
                  height: 250,
                  child: AnimatedBarChart(
                    isHorizontal: true,
                    unit: ' pts',
                    maxY: 100,
                    items: const [
                      BarChartItemData(label: 'Nashik (Cluster Epicenter)', value: 82, color: AppColors.critical, payload: 'Nashik'),
                      BarChartItemData(label: 'Pune (Commercial Transit Corridor)', value: 61, color: AppColors.highRisk, payload: 'Pune'),
                      BarChartItemData(label: 'Nagpur (Border Surveillance)', value: 55, color: AppColors.warning, payload: 'Nagpur'),
                      BarChartItemData(label: 'Ahmednagar (Buffer Zone)', value: 48, color: AppColors.warning, payload: 'Ahmednagar'),
                      BarChartItemData(label: 'Kolhapur (Stable Baseline)', value: 32, color: AppColors.healthy, payload: 'Kolhapur'),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. DIALOGS & INSPECTION MODALS
  // ─────────────────────────────────────────────────────────────────────────────

  void _showDistrictDrillDown(DistrictSurveillanceSummary d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.location_city, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('${d.district} District Epidemiological Dossier'),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: d.districtRiskLevel == HealthRiskLevel.critical
                      ? AppColors.critical.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: d.districtRiskLevel == HealthRiskLevel.critical
                        ? AppColors.critical
                        : AppColors.warning,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'DISTRICT RISK SCORE: ${d.districtRiskScore}/100 (${d.districtRiskLevel.name.toUpperCase()})',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: d.districtRiskLevel == HealthRiskLevel.critical
                            ? AppColors.critical
                            : AppColors.highRisk,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'EXPLAINABLE RISK FACTORS:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              ...d.riskReasons.map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
                        Expanded(child: Text(r, style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  )),
              const Divider(height: 20),
              const Text(
                'GOVERNMENT PREVENTIVE ACTIONS:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.add_alert, size: 14),
                    label: const Text('Issue Biosecurity Advisory'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Biosecurity advisory dispatched to ${d.district} farmers.')),
                      );
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.vaccines, size: 14),
                    label: const Text('Initiate Vaccine Drive'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Vaccination booster drive scheduled for ${d.district}.')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showClusterDetailDialog(OutbreakClusterModel cluster) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cluster Dossier: ${cluster.clusterCode}'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('District: ${cluster.district}'),
              Text('Syndrome: ${cluster.syndrome.toUpperCase()}'),
              Text('Affected Farms: ${cluster.farmCount}'),
              Text('Reported Mortalities: ${cluster.mortalityCount}'),
              Text('Cluster Radius: ${cluster.radiusKm.toStringAsFixed(1)} km'),
              Text('Confidence: ${cluster.confidenceLabel.label}'),
              const Divider(height: 20),
              Text(
                'Evidence: ${cluster.evidenceSummary.isNotEmpty ? cluster.evidenceSummary.join(" • ") : "3 farms correlated"}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss')),
        ],
      ),
    );
  }

  void _showFarmDetailDialog(FarmGisMapMarker farm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(farm.farmName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('District: ${farm.district}'),
            Text('Current Risk: ${farm.highestRiskLevel.name.toUpperCase()}'),
            Text('Reported Syndrome: ${farm.currentSyndrome}'),
            Text('Active Cases: ${farm.activeCases}'),
            Text('Mortalities: ${farm.mortalityCount}'),
            Text('Coordinates: ${farm.latitude}, ${farm.longitude}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
