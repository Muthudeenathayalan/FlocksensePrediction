import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/core/widgets/metric_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/health/data/government_surveillance_service.dart';
import 'package:flock_sense/features/health/data/outbreak_cluster_service.dart';
import 'package:flock_sense/features/health/domain/district_surveillance_model.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/outbreak_cluster_model.dart';
import 'package:flock_sense/features/health/presentation/widgets/surveillance_gis_map.dart';

/// Dedicated Full-Screen GIS Disease Surveillance Map Screen (SIH26128 Phase 9)
class GovernmentGisMapScreen extends StatefulWidget {
  const GovernmentGisMapScreen({super.key});

  @override
  State<GovernmentGisMapScreen> createState() => _GovernmentGisMapScreenState();
}

class _GovernmentGisMapScreenState extends State<GovernmentGisMapScreen> {
  String _selectedDistrict = 'All';
  String _selectedMapLayer = 'All Layers';
  bool _showQuarantineRings = true;
  bool _showHighDensityCorridors = true;

  void _showClusterDetailDialog(OutbreakClusterModel cluster) {
    AppDialog.show(
      context: context,
      child: _GisClusterDossierModal(cluster: cluster),
    );
  }

  void _showFarmDetailDialog(FarmGisMapMarker farm) {
    AppDialog.show(
      context: context,
      child: _GisFarmDossierModal(farm: farm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OutbreakClusterModel>>(
      stream: OutbreakClusterService.streamActiveClusters(),
      builder: (context, clusterSnap) {
        final clusters = clusterSnap.data ?? [];

        return StreamBuilder<List<FarmGisMapMarker>>(
          stream: GovernmentSurveillanceService.streamFarmGisMarkers(),
          builder: (context, farmSnap) {
            final farms = farmSnap.data ?? [];
            final totalFarms = farms.length;
            final criticalFarms = farms.where((f) => f.highestRiskLevel == HealthRiskLevel.critical).length;
            final warningFarms = farms.where((f) => f.highestRiskLevel == HealthRiskLevel.high || f.highestRiskLevel == HealthRiskLevel.moderate).length;
            final compliantFarms = farms.where((f) => f.highestRiskLevel == HealthRiskLevel.low).length;

            return PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Dedicated Header with Quick Map Actions
                  WebPageHeader(
                    title: 'GIS Disease Surveillance & Spatial Epidemic Map',
                    subtitle: 'Real-time spatial clustering, risk heatmaps, quarantine buffer zones, and geocoded poultry facilities.',
                    actions: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDistrict,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.slate900),
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text('All Administrative Districts')),
                              DropdownMenuItem(value: 'Nashik', child: Text('Nashik District (Active Cluster)')),
                              DropdownMenuItem(value: 'Pune', child: Text('Pune District')),
                              DropdownMenuItem(value: 'Ahmednagar', child: Text('Ahmednagar District')),
                              DropdownMenuItem(value: 'Dhule', child: Text('Dhule District')),
                              DropdownMenuItem(value: 'Jalgaon', child: Text('Jalgaon District')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedDistrict = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppButton(
                        label: 'Export Map Layers',
                        icon: Icons.layers_outlined,
                        size: AppButtonSize.small,
                        variant: AppButtonVariant.outlined,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Exporting GeoJSON spatial boundaries and quarantine layers...')),
                          );
                        },
                      ),
                    ],
                  ),

                  // 2. Spatial Telemetry & Density KPIs
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Monitored Facilities',
                          value: '$totalFarms Geocoded',
                          subtitle: '98.2% spatial coverage',
                          icon: Icons.location_on_outlined,
                          accentColor: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricCard(
                          title: 'Active Outbreak Zones',
                          value: '${clusters.length} Cluster (10 km)',
                          subtitle: 'Nashik Northern Belt',
                          delta: 'Critical',
                          isPositiveDelta: false,
                          icon: Icons.crisis_alert_rounded,
                          accentColor: AppColors.critical,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricCard(
                          title: 'Elevated Vigilance',
                          value: '$warningFarms Farms',
                          subtitle: 'Within 15km perimeter',
                          icon: Icons.warning_amber_rounded,
                          accentColor: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricCard(
                          title: 'Tier-1 Secure Farms',
                          value: '$compliantFarms Verified',
                          subtitle: 'Zero clinical anomalies',
                          icon: Icons.verified_user_outlined,
                          accentColor: AppColors.healthy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Full Interactive GIS Map Canvas with Tactical Controls
                  SurveillanceGisMap(
                    farmMarkers: farms,
                    activeClusters: clusters,
                    selectedDistrict: _selectedDistrict,
                    onDistrictChanged: (dist) => setState(() => _selectedDistrict = dist),
                    onClusterSelected: _showClusterDetailDialog,
                    onFarmSelected: _showFarmDetailDialog,
                    height: 560,
                  ),
                  const SizedBox(height: 16),

                  // 4. Map Layer Controls & GIS Legend Bar
                  _buildGisControlAndLegendBar(),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGisControlAndLegendBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Layer Toggles
          Row(
            children: [
              const Text('Surveillance Layers:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.slate700)),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('10km Quarantine Cordon', style: TextStyle(fontSize: 12)),
                selected: _showQuarantineRings,
                selectedColor: AppColors.critical.withOpacity(0.15),
                onSelected: (val) => setState(() => _showQuarantineRings = val),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('High-Density Corridors', style: TextStyle(fontSize: 12)),
                selected: _showHighDensityCorridors,
                selectedColor: AppColors.info.withOpacity(0.15),
                onSelected: (val) => setState(() => _showHighDensityCorridors = val),
              ),
            ],
          ),

          // Right: Semantic Map Legend
          Row(
            children: [
              _buildLegendPin(AppColors.critical, 'Active Outbreak / Critical (Score >= 76)'),
              const SizedBox(width: 16),
              _buildLegendPin(AppColors.warning, 'Elevated Risk (Score 51-75)'),
              const SizedBox(width: 16),
              _buildLegendPin(AppColors.healthy, 'Normal / Tier-1 Compliant'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPin(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.slate600)),
      ],
    );
  }
}

class _GisClusterDossierModal extends StatelessWidget {
  final OutbreakClusterModel cluster;
  const _GisClusterDossierModal({required this.cluster});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 580,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.critical.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.crisis_alert_rounded, color: AppColors.critical, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cluster.clusterCode, style: AppTypography.cardTitle),
                      Text('${cluster.district}, ${cluster.state} • Spatial Outbreak Cluster', style: AppTypography.bodySmall),
                    ],
                  ),
                ],
              ),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(height: 28),
          _buildDetailRow('Syndromic Profile', cluster.possibleDisease),
          _buildDetailRow('Cluster Radius', '${cluster.radiusKm} km Spatial Buffer'),
          _buildDetailRow('Linked Facilities', '${cluster.farmCount} Commercial Farms (${cluster.farmIds.join(", ")})'),
          _buildDetailRow('Reported Morbidity', '${cluster.affectedCount} birds showing clinical signs'),
          _buildDetailRow('Cumulative Mortality', '${cluster.mortalityCount} deaths recorded in 72h window'),
          _buildDetailRow('Center GPS Coordinates', '${cluster.centerLatitude.toStringAsFixed(4)}° N, ${cluster.centerLongitude.toStringAsFixed(4)}° E'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'Enforce Quarantine',
                size: AppButtonSize.small,
                icon: Icons.shield_outlined,
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Level-3 Quarantine cordon enforced for ${cluster.clusterCode}.')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.slate700))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.slate900))),
        ],
      ),
    );
  }
}

class _GisFarmDossierModal extends StatelessWidget {
  final FarmGisMapMarker farm;
  const _GisFarmDossierModal({required this.farm});

  @override
  Widget build(BuildContext context) {
    final isCritical = farm.highestRiskLevel == HealthRiskLevel.critical;
    return Container(
      width: 520,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(farm.farmName, style: AppTypography.cardTitle),
                  Text('${farm.district}, Maharashtra • Poultry Facility Dossier', style: AppTypography.bodySmall),
                ],
              ),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(height: 28),
          _buildDetailRow('Facility ID', farm.farmId),
          _buildDetailRow('Current Syndrome', farm.currentSyndrome.isNotEmpty ? farm.currentSyndrome : 'Respiratory & Enteric Monitoring'),
          _buildDetailRow('Current Health Status', isCritical ? 'CRITICAL RISK (Under Investigation)' : 'Normal / Monitored'),
          _buildDetailRow('Active Clinical Cases', '${farm.activeCases} Incidents'),
          _buildDetailRow('Cumulative Mortality', '${farm.mortalityCount} Deaths logged'),
          _buildDetailRow('GPS Coordinates', '${farm.latitude.toStringAsFixed(4)}° N, ${farm.longitude.toStringAsFixed(4)}° E'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.slate700))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.slate900))),
        ],
      ),
    );
  }
}
