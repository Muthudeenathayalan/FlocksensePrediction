import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/health/domain/district_surveillance_model.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/outbreak_cluster_model.dart';

/// Real-Time Tile-Based GIS Animal Disease Surveillance & Farm Map (SIH26128)
/// Features real OpenStreetMap / Satellite / Dark tile layers, exact GPS pins,
/// meter-accurate 3km/10km containment circles, zoom/pan navigation, and interactive farm dossiers.
class SurveillanceGisMap extends StatefulWidget {
  final List<FarmGisMapMarker> farmMarkers;
  final List<OutbreakClusterModel> activeClusters;
  final String selectedDistrict;
  final ValueChanged<String>? onDistrictChanged;
  final ValueChanged<OutbreakClusterModel>? onClusterSelected;
  final ValueChanged<FarmGisMapMarker>? onFarmSelected;
  final double height;
  final String? focusFarmId;

  const SurveillanceGisMap({
    super.key,
    required this.farmMarkers,
    required this.activeClusters,
    this.selectedDistrict = 'All',
    this.onDistrictChanged,
    this.onClusterSelected,
    this.onFarmSelected,
    this.height = 560,
    this.focusFarmId,
  });

  @override
  State<SurveillanceGisMap> createState() => _SurveillanceGisMapState();
}

enum MapTileType {
  satellite,
  street,
  dark,
  voyager,
}

class _SurveillanceGisMapState extends State<SurveillanceGisMap>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late AnimationController _pulseController;

  // Selected tile layer
  MapTileType _currentTileType = MapTileType.street;

  // Layer Toggles
  bool _showClusters = true;
  bool _showCriticalCases = true;
  bool _showHealthRisk = true;

  // Selected / Hovered elements
  FarmGisMapMarker? _hoveredFarm;
  FarmGisMapMarker? _selectedFarm;
  OutbreakClusterModel? _hoveredCluster;
  OutbreakClusterModel? _selectedCluster;

  // District focus coordinates
  static const Map<String, LatLng> _districtCenters = {
    'all': LatLng(19.25, 74.1),
    'nashik': LatLng(19.9975, 73.7898),
    'pune': LatLng(18.5204, 73.8567),
    'thane': LatLng(19.2183, 72.9781),
    'ahmednagar': LatLng(19.0948, 74.7480),
    'satara': LatLng(17.6805, 74.0183),
  };

  static const Map<String, double> _districtZooms = {
    'all': 7.6,
    'nashik': 11.8,
    'pune': 11.2,
    'thane': 11.5,
    'ahmednagar': 11.0,
    'satara': 11.0,
  };

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  String _getTileUrl(MapTileType type) {
    switch (type) {
      case MapTileType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapTileType.street:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapTileType.dark:
        return 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
      case MapTileType.voyager:
        return 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
    }
  }

  void _recenterOnMyFarm() {
    final myFarm = widget.farmMarkers.firstWhere(
      (f) =>
          f.farmId == 'farm_01' ||
          f.farmName.toLowerCase().contains('my farm') ||
          f.farmName.toLowerCase().contains('green valley'),
      orElse: () => widget.farmMarkers.isNotEmpty
          ? widget.farmMarkers.first
          : FarmGisMapMarker(
              farmId: 'farm_01',
              farmName: 'Green Valley Poultry Farm',
              district: 'Nashik',
              latitude: 19.9975,
              longitude: 73.7898,
              highestRiskLevel: HealthRiskLevel.low,
              activeCases: 0,
              mortalityCount: 2,
              currentSyndrome: 'Healthy',
              lastReportedAt: DateTime.now(),
            ),
    );

    setState(() {
      _selectedFarm = myFarm;
      _selectedCluster = null;
    });

    _mapController.move(LatLng(myFarm.latitude, myFarm.longitude), 13.8);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom + 1).clamp(4.0, 18.0));
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom - 1).clamp(4.0, 18.0));
  }

  void _focusDistrict(String district) {
    final key = district.toLowerCase();
    final center = _districtCenters[key] ?? _districtCenters['all']!;
    final zoom = _districtZooms[key] ?? 8.0;
    _mapController.move(center, zoom);
  }

  @override
  Widget build(BuildContext context) {
    // Filter markers based on selected district and active layers
    final filteredFarms = widget.farmMarkers.where((farm) {
      if (widget.selectedDistrict != 'All' &&
          farm.district.toLowerCase() != widget.selectedDistrict.toLowerCase()) {
        return false;
      }
      if (!_showCriticalCases && farm.highestRiskLevel == HealthRiskLevel.critical) {
        return false;
      }
      if (!_showHealthRisk && farm.highestRiskLevel != HealthRiskLevel.critical) {
        return false;
      }
      return true;
    }).toList();

    final filteredClusters = widget.activeClusters.where((cluster) {
      if (!_showClusters) return false;
      if (widget.selectedDistrict != 'All' &&
          cluster.district.toLowerCase() != widget.selectedDistrict.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    final initialCenter = _districtCenters[widget.selectedDistrict.toLowerCase()] ??
        const LatLng(19.9975, 73.7898);
    final initialZoom = _districtZooms[widget.selectedDistrict.toLowerCase()] ?? 11.5;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDesign.radiusLg - 1),
        child: Stack(
          children: [
            // 1. Real Tile-Based Map (OpenStreetMap / Satellite / Dark)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: initialZoom,
                minZoom: 4.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                // Real Tile Layer
                TileLayer(
                  urlTemplate: _getTileUrl(_currentTileType),
                  userAgentPackageName: 'com.flocksense.app',
                  maxZoom: 18,
                ),

                // 2. Outbreak Containment Circles (3km inner strict containment + 10km surveillance cordon)
                CircleLayer(
                  circles: [
                    ...filteredClusters.expand((cluster) {
                      final center = LatLng(cluster.centerLatitude, cluster.centerLongitude);
                      return [
                        // Outer 10km surveillance ring
                        CircleMarker(
                          point: center,
                          radius: cluster.radiusKm * 1000,
                          useRadiusInMeter: true,
                          color: AppColors.warning.withOpacity(0.12),
                          borderColor: AppColors.warning.withOpacity(0.7),
                          borderStrokeWidth: 1.8,
                        ),
                        // Inner 3km critical containment zone
                        CircleMarker(
                          point: center,
                          radius: 3000,
                          useRadiusInMeter: true,
                          color: AppColors.critical.withOpacity(0.24),
                          borderColor: AppColors.critical,
                          borderStrokeWidth: 2.2,
                        ),
                      ];
                    }),
                  ],
                ),

                // 3. Outbreak Cluster Center Hotspot Badges
                MarkerLayer(
                  markers: filteredClusters.map((cluster) {
                    return Marker(
                      point: LatLng(cluster.centerLatitude, cluster.centerLongitude),
                      width: 170,
                      height: 48,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCluster = cluster;
                            _selectedFarm = null;
                          });
                          widget.onClusterSelected?.call(cluster);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.critical,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.critical.withOpacity(0.6),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.crisis_alert_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  '${cluster.clusterCode} (${cluster.radiusKm.toStringAsFixed(1)}km)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // 4. Real Geocoded Farm Pins
                MarkerLayer(
                  markers: filteredFarms.map((farm) {
                    final isMyFarm = farm.farmId == 'farm_01' ||
                        farm.farmName.toLowerCase().contains('my farm') ||
                        farm.farmName.toLowerCase().contains('green valley');

                    Color pinColor;
                    switch (farm.highestRiskLevel) {
                      case HealthRiskLevel.critical:
                        pinColor = AppColors.critical;
                        break;
                      case HealthRiskLevel.high:
                        pinColor = AppColors.highRisk;
                        break;
                      case HealthRiskLevel.moderate:
                        pinColor = AppColors.warning;
                        break;
                      case HealthRiskLevel.low:
                        pinColor = isMyFarm ? const Color(0xFF059669) : AppColors.healthy;
                        break;
                    }

                    return Marker(
                      point: LatLng(farm.latitude, farm.longitude),
                      width: isMyFarm ? 140 : 120,
                      height: 64,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFarm = farm;
                            _selectedCluster = null;
                          });
                          widget.onFarmSelected?.call(farm);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pin Card Label
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isMyFarm ? const Color(0xFF064E3B) : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isMyFarm ? const Color(0xFF34D399) : pinColor,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isMyFarm)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 3),
                                      child: Icon(Icons.star_rounded, color: Colors.amber, size: 10),
                                    ),
                                  Flexible(
                                    child: Text(
                                      isMyFarm ? 'MY FARM' : farm.farmName.split(' ').take(2).join(' '),
                                      style: TextStyle(
                                        color: isMyFarm ? const Color(0xFFA7F3D0) : Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Map Pin Head
                            Container(
                              width: isMyFarm ? 26 : 22,
                              height: isMyFarm ? 26 : 22,
                              decoration: BoxDecoration(
                                color: pinColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: pinColor.withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  isMyFarm
                                      ? Icons.storefront_rounded
                                      : (farm.highestRiskLevel == HealthRiskLevel.critical
                                          ? Icons.priority_high_rounded
                                          : Icons.home_work_outlined),
                                  size: isMyFarm ? 14 : 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // 5. Top Controls Strip: District Selector, Map Style (Satellite/Street/Dark), Layer Chips
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: _buildTopControlToolbar(),
            ),

            // 6. Floating Navigation & Zoom Action Bar (Right side)
            Positioned(
              top: 76,
              right: 14,
              child: _buildFloatingZoomControls(),
            ),

            // 7. Live Telemetry HUD Pill (Bottom Left)
            Positioned(
              bottom: 14,
              left: 14,
              child: _buildTelemetryPill(filteredFarms.length, filteredClusters.length),
            ),

            // 8. Semantic Map Legend Strip (Bottom Right)
            Positioned(
              bottom: 14,
              right: 14,
              child: _buildMapLegend(),
            ),

            // 9. Interactive Floating Telemetry Dossier Modal
            if (_hoveredFarm != null || _selectedFarm != null)
              Positioned(
                top: 76,
                left: 14,
                child: _buildFarmDossierOverlay(_selectedFarm ?? _hoveredFarm!),
              ),

            if (_hoveredCluster != null || _selectedCluster != null)
              Positioned(
                top: 76,
                left: 14,
                child: _buildClusterDossierOverlay(_selectedCluster ?? _hoveredCluster!),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TOP CONTROLS & LAYER BAR
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildTopControlToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
        children: [
          // Live Pulse Beacon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.critical.withOpacity(0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.critical.withOpacity(0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.critical,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.critical.withOpacity(1.0 - _pulseController.value),
                            blurRadius: 6 * _pulseController.value,
                            spreadRadius: 2 * _pulseController.value,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE REALTIME MAP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // District Quick Focus Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF475569)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.selectedDistrict,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Maharashtra')),
                  DropdownMenuItem(value: 'Nashik', child: Text('Nashik (Hotspot)')),
                  DropdownMenuItem(value: 'Pune', child: Text('Pune')),
                  DropdownMenuItem(value: 'Thane', child: Text('Thane / Mumbai')),
                  DropdownMenuItem(value: 'Ahmednagar', child: Text('Ahmednagar')),
                  DropdownMenuItem(value: 'Satara', child: Text('Satara')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    widget.onDistrictChanged?.call(val);
                    _focusDistrict(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Map Tile Style Switcher
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF475569)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTileTypeButton('🗺️ Street', MapTileType.street),
                _buildTileTypeButton('🛰️ Satellite', MapTileType.satellite),
                _buildTileTypeButton('🌃 Dark', MapTileType.dark),
                _buildTileTypeButton('🏙️ Clean', MapTileType.voyager),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Layer Toggle Buttons
          _buildLayerChip(
            label: 'Quarantine Rings',
            icon: Icons.shield_outlined,
            isActive: _showClusters,
            activeColor: AppColors.critical,
            onTap: () => setState(() => _showClusters = !_showClusters),
          ),
          const SizedBox(width: 6),
          _buildLayerChip(
            label: 'Critical Hotspots',
            icon: Icons.error_outline_rounded,
            isActive: _showCriticalCases,
            activeColor: AppColors.highRisk,
            onTap: () => setState(() => _showCriticalCases = !_showCriticalCases),
          ),
          const SizedBox(width: 6),
          _buildLayerChip(
            label: 'Healthy Farms',
            icon: Icons.check_circle_outline_rounded,
            isActive: _showHealthRisk,
            activeColor: AppColors.healthy,
            onTap: () => setState(() => _showHealthRisk = !_showHealthRisk),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildTileTypeButton(String label, MapTileType type) {
    final isSelected = _currentTileType == type;
    return InkWell(
      onTap: () => setState(() => _currentTileType = type),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLayerChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFF475569),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isActive ? activeColor : Colors.white60),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white60,
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FLOATING ZOOM & CENTER CONTRONS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildFloatingZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMapActionButton(
            tooltip: 'Recenter on My Farm (Green Valley, Nashik)',
            icon: Icons.my_location_rounded,
            color: const Color(0xFF34D399),
            onTap: _recenterOnMyFarm,
          ),
          const Divider(height: 1, color: Color(0xFF334155)),
          _buildMapActionButton(
            tooltip: 'Zoom In (+)',
            icon: Icons.add_rounded,
            color: Colors.white,
            onTap: _zoomIn,
          ),
          const Divider(height: 1, color: Color(0xFF334155)),
          _buildMapActionButton(
            tooltip: 'Zoom Out (-)',
            icon: Icons.remove_rounded,
            color: Colors.white,
            onTap: _zoomOut,
          ),
          const Divider(height: 1, color: Color(0xFF334155)),
          _buildMapActionButton(
            tooltip: 'Fit Regional View',
            icon: Icons.fullscreen_rounded,
            color: Colors.white70,
            onTap: () => _focusDistrict('All'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapActionButton({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: color, size: 19),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // FLOATING TELEMETRY DOSSIER MODALS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildFarmDossierOverlay(FarmGisMapMarker farm) {
    final isMyFarm = farm.farmId == 'farm_01' ||
        farm.farmName.toLowerCase().contains('my farm') ||
        farm.farmName.toLowerCase().contains('green valley');

    Color badgeColor;
    switch (farm.highestRiskLevel) {
      case HealthRiskLevel.critical:
        badgeColor = AppColors.critical;
        break;
      case HealthRiskLevel.high:
        badgeColor = AppColors.highRisk;
        break;
      case HealthRiskLevel.moderate:
        badgeColor = AppColors.warning;
        break;
      case HealthRiskLevel.low:
        badgeColor = AppColors.healthy;
        break;
    }

    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor),
                ),
                child: Icon(
                  isMyFarm ? Icons.verified_rounded : Icons.storefront_outlined,
                  color: badgeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            farm.farmName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() {
                            _selectedFarm = null;
                            _hoveredFarm = null;
                          }),
                          child: const Icon(Icons.close_rounded, size: 16, color: Colors.white60),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${farm.district} District, Maharashtra',
                      style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 18),

          // Real GPS Coordinates Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF475569)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed_rounded, color: AppColors.info, size: 13),
                const SizedBox(width: 6),
                Text(
                  'GPS: ${farm.latitude.toStringAsFixed(4)}° N, ${farm.longitude.toStringAsFixed(4)}° E',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.healthy.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'RTK ±3m',
                    style: TextStyle(color: AppColors.healthy, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Telemetry Stats Grid
          _buildTelemetryDataRow('Health Triage Status', farm.highestRiskLevel.name.toUpperCase(), badgeColor),
          _buildTelemetryDataRow('Active Clinical Cases', '${farm.activeCases} Incidents', Colors.white),
          _buildTelemetryDataRow('Recorded Mortalities', '${farm.mortalityCount} birds', Colors.white),
          _buildTelemetryDataRow('Current Syndromic Profile', farm.currentSyndrome, Colors.white70),
          _buildTelemetryDataRow('Biosecurity Score', isMyFarm ? '94% (Tier-1 Compliant)' : '82%', AppColors.healthy),

          const SizedBox(height: 12),
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isMyFarm ? AppColors.primary : const Color(0xFF334155),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: Text(
                isMyFarm ? 'Manage My Farm Telemetry' : 'Open Epidemiological Dossier',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                widget.onFarmSelected?.call(farm);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterDossierOverlay(OutbreakClusterModel cluster) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.critical, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.critical.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.critical.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.critical),
                ),
                child: const Icon(Icons.crisis_alert_rounded, color: AppColors.critical, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cluster.clusterCode,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() {
                            _selectedCluster = null;
                            _hoveredCluster = null;
                          }),
                          child: const Icon(Icons.close_rounded, size: 16, color: Colors.white60),
                        ),
                      ],
                    ),
                    Text(
                      '${cluster.district} Outbreak Hotspot Zone',
                      style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 18),

          _buildTelemetryDataRow('Suspected Pathogen', cluster.possibleDisease, AppColors.critical),
          _buildTelemetryDataRow('Quarantine Buffer Radius', '${cluster.radiusKm.toStringAsFixed(1)} km Containment Ring', Colors.white),
          _buildTelemetryDataRow('Connected Facilities', '${cluster.farmCount} Commercial Farms', Colors.white),
          _buildTelemetryDataRow('Morbidity / Affected', '${cluster.affectedCount} birds showing signs', Colors.white),
          _buildTelemetryDataRow('Cumulative Mortality', '${cluster.mortalityCount} recorded deaths', AppColors.critical),
          _buildTelemetryDataRow('Cluster Status', cluster.status.name.replaceAll('_', ' ').toUpperCase(), Colors.amber),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.critical,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: const Icon(Icons.shield_outlined, size: 14),
              label: const Text(
                'Enforce Containment Protocol',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                widget.onClusterSelected?.call(cluster);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryDataRow(String label, String val, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Flexible(
            child: Text(
              val,
              style: TextStyle(color: valColor, fontSize: 11, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BOTTOM TELEMETRY STRIP & LEGEND
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildTelemetryPill(int farmCount, int clusterCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.radar_rounded, color: AppColors.info, size: 14),
          const SizedBox(width: 7),
          Text(
            'GPS Telemetry: $farmCount Farms Geocoded • $clusterCount Active Outbreak Rings • Sync: Live',
            style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendDot(const Color(0xFF059669), 'My Farm'),
          const SizedBox(width: 10),
          _buildLegendDot(AppColors.critical, 'Critical Hotspot'),
          const SizedBox(width: 10),
          _buildLegendDot(AppColors.warning, 'Monitoring'),
          const SizedBox(width: 10),
          _buildLegendDot(AppColors.healthy, 'Tier-1 Clean'),
          const SizedBox(width: 10),
          _buildLegendDot(const Color(0xFFE11D48), '3km Quarantine Ring'),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
