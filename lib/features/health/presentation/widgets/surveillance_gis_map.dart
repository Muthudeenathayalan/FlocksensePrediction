import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/features/health/domain/district_surveillance_model.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/outbreak_cluster_model.dart';

/// Professional Government GIS Animal Disease Surveillance Map (SIH26128 Phase 9)
class SurveillanceGisMap extends StatefulWidget {
  final List<FarmGisMapMarker> farmMarkers;
  final List<OutbreakClusterModel> activeClusters;
  final String selectedDistrict;
  final ValueChanged<String>? onDistrictChanged;
  final ValueChanged<OutbreakClusterModel>? onClusterSelected;
  final ValueChanged<FarmGisMapMarker>? onFarmSelected;
  final double height;

  const SurveillanceGisMap({
    super.key,
    required this.farmMarkers,
    required this.activeClusters,
    this.selectedDistrict = 'All',
    this.onDistrictChanged,
    this.onClusterSelected,
    this.onFarmSelected,
    this.height = 460,
  });

  @override
  State<SurveillanceGisMap> createState() => _SurveillanceGisMapState();
}

class _SurveillanceGisMapState extends State<SurveillanceGisMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  // Layer Toggles
  bool _showHealthRisk = true;
  bool _showClusters = true;
  bool _showCriticalCases = true;
  bool _showVaccinationRisk = false;

  // Filter selection
  String _timeWindow = '72h';
  FarmGisMapMarker? _hoveredFarm;
  OutbreakClusterModel? _hoveredCluster;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Premium dark navy tactical background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // 1. Grid Lines & Map Canvas
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _GisMapCanvasPainter(
                      pulseValue: _pulseController.value,
                      farmMarkers: filteredFarms,
                      clusters: filteredClusters,
                      selectedDistrict: widget.selectedDistrict,
                      showVaccinationOverlay: _showVaccinationRisk,
                    ),
                  );
                },
              ),
            ),

            // 2. Interactive Cluster Overlay Hotspots
            ...filteredClusters.map((cluster) => _buildClusterOverlay(cluster)),

            // 3. Interactive Farm Risk Markers
            ...filteredFarms.map((farm) => _buildFarmMarker(farm)),

            // 4. Top Control Bar: District Selector, Time Window & Layer Toggles
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: _buildTopControlBar(),
            ),

            // 5. Bottom Left: Surveillance Map Legend
            Positioned(
              bottom: 14,
              left: 14,
              child: _buildMapLegend(),
            ),

            // 6. Bottom Right: Live Radar Telemetry Pill
            Positioned(
              bottom: 14,
              right: 14,
              child: _buildTelemetryPill(filteredFarms.length, filteredClusters.length),
            ),

            // 7. Hover Tooltip Overlay
            if (_hoveredFarm != null)
              Positioned(
                top: 70,
                right: 14,
                child: _buildFarmTooltip(_hoveredFarm!),
              ),
            if (_hoveredCluster != null)
              Positioned(
                top: 70,
                right: 14,
                child: _buildClusterTooltip(_hoveredCluster!),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TOP CONTROLS & LAYER TOGGLES
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildTopControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF475569)),
      ),
      child: Row(
        children: [
          // Live GIS Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.critical.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.critical),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.critical,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'GIS SURVEILLANCE',
                  style: TextStyle(
                    color: AppColors.critical,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // District Selector Dropdown
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.selectedDistrict,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Maharashtra Districts')),
                DropdownMenuItem(value: 'Nashik', child: Text('Nashik (Hotspot)')),
                DropdownMenuItem(value: 'Pune', child: Text('Pune')),
                DropdownMenuItem(value: 'Ahmednagar', child: Text('Ahmednagar')),
                DropdownMenuItem(value: 'Satara', child: Text('Satara')),
              ],
              onChanged: (val) {
                if (val != null && widget.onDistrictChanged != null) {
                  widget.onDistrictChanged!(val);
                }
              },
            ),
          ),
          const Spacer(),

          // Layer Toggle Buttons
          _buildLayerChip(
            label: 'Clusters',
            isActive: _showClusters,
            activeColor: AppColors.critical,
            onTap: () => setState(() => _showClusters = !_showClusters),
          ),
          const SizedBox(width: 6),
          _buildLayerChip(
            label: 'Critical Risk',
            isActive: _showCriticalCases,
            activeColor: AppColors.highRisk,
            onTap: () => setState(() => _showCriticalCases = !_showCriticalCases),
          ),
          const SizedBox(width: 6),
          _buildLayerChip(
            label: 'Health Risk',
            isActive: _showHealthRisk,
            activeColor: AppColors.warning,
            onTap: () => setState(() => _showHealthRisk = !_showHealthRisk),
          ),
          const SizedBox(width: 6),
          _buildLayerChip(
            label: 'Vaccine Gap',
            isActive: _showVaccinationRisk,
            activeColor: AppColors.info,
            onTap: () => setState(() => _showVaccinationRisk = !_showVaccinationRisk),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerChip({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFF475569),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.circle_outlined,
              size: 12,
              color: isActive ? activeColor : Colors.white54,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white60,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MARKER & CLUSTER RENDERING
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildClusterOverlay(OutbreakClusterModel cluster) {
    // Relative position on map canvas (Nashik coordinate anchor)
    final dx = 220.0;
    final dy = 230.0;

    return Positioned(
      left: dx - 65,
      top: dy - 65,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredCluster = cluster),
        onExit: (_) => setState(() => _hoveredCluster = null),
        child: GestureDetector(
          onTap: () => widget.onClusterSelected?.call(cluster),
          child: SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing outer warning zone
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final scale = 0.85 + (_pulseController.value * 0.25);
                    final opacity = (1.0 - _pulseController.value) * 0.45;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.critical.withOpacity(opacity),
                          border: Border.all(
                            color: AppColors.critical.withOpacity(opacity + 0.3),
                            width: 1.8,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Cluster Center Hotspot Core
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.critical,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.critical.withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${cluster.farmCount} FARMS (${cluster.radiusKm.toStringAsFixed(1)}km)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFarmMarker(FarmGisMapMarker farm) {
    // Relative coordinates mapping for Maharashtra farms
    double left = 200.0;
    double top = 200.0;

    if (farm.farmId.contains('gv')) {
      left = 180.0;
      top = 210.0;
    } else if (farm.farmId.contains('sk')) {
      left = 240.0;
      top = 220.0;
    } else if (farm.farmId.contains('pb')) {
      left = 220.0;
      top = 260.0;
    } else if (farm.farmId.contains('pn')) {
      left = 340.0;
      top = 310.0;
    } else if (farm.farmId.contains('st')) {
      left = 320.0;
      top = 390.0;
    }

    Color color;
    switch (farm.highestRiskLevel) {
      case HealthRiskLevel.critical:
        color = AppColors.critical;
        break;
      case HealthRiskLevel.high:
        color = AppColors.highRisk;
        break;
      case HealthRiskLevel.moderate:
        color = AppColors.warning;
        break;
      case HealthRiskLevel.low:
        color = AppColors.success;
        break;
    }

    return Positioned(
      left: left - 12,
      top: top - 12,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredFarm = farm),
        onExit: (_) => setState(() => _hoveredFarm = null),
        child: GestureDetector(
          onTap: () => widget.onFarmSelected?.call(farm),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1.5,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                farm.highestRiskLevel == HealthRiskLevel.critical
                    ? Icons.priority_high
                    : Icons.home_work_outlined,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TOOLTIP CARDS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildFarmTooltip(FarmGisMapMarker farm) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF475569), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: farm.highestRiskLevel == HealthRiskLevel.critical
                      ? AppColors.critical
                      : AppColors.highRisk,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  farm.highestRiskLevel.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  farm.farmName,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 14),
          _buildTooltipRow('District', farm.district),
          _buildTooltipRow('Syndrome', farm.currentSyndrome),
          _buildTooltipRow('Active Cases', '${farm.activeCases} case'),
          _buildTooltipRow('Mortalities', '${farm.mortalityCount} birds'),
          _buildTooltipRow('GPS Coordinates', '${farm.latitude.toStringAsFixed(4)}, ${farm.longitude.toStringAsFixed(4)}'),
        ],
      ),
    );
  }

  Widget _buildClusterTooltip(OutbreakClusterModel cluster) {
    return Container(
      width: 290,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.critical, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.critical.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.critical, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${cluster.clusterCode} (${cluster.syndrome.toUpperCase()})',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 14),
          _buildTooltipRow('Hotspot District', cluster.district),
          _buildTooltipRow('Distinct Farms', '${cluster.farmCount} farms'),
          _buildTooltipRow('Reported Affected', '${cluster.affectedCount} birds'),
          _buildTooltipRow('Cluster Radius', '${cluster.radiusKm.toStringAsFixed(1)} km'),
          _buildTooltipRow('Cluster Confidence', cluster.confidenceLabel.label),
          _buildTooltipRow('Severity', cluster.severity.toUpperCase()),
          _buildTooltipRow('Status', cluster.status.name.replaceAll('_', ' ').toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildTooltipRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MAP LEGEND & TELEMETRY
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendDot(AppColors.critical, 'Critical Farm'),
          const SizedBox(width: 8),
          _buildLegendDot(AppColors.highRisk, 'High Risk'),
          const SizedBox(width: 8),
          _buildLegendDot(AppColors.warning, 'Moderate'),
          const SizedBox(width: 8),
          _buildLegendDot(AppColors.success, 'Baseline'),
          const SizedBox(width: 8),
          _buildLegendDot(const Color(0xFFE11D48), 'Cluster Hotspot (10km)'),
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

  Widget _buildTelemetryPill(int farmCount, int clusterCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.radar, color: AppColors.info, size: 14),
          const SizedBox(width: 6),
          Text(
            'Active Feed: $farmCount Farms • $clusterCount Clusters • Grid OK',
            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Custom Canvas Painter rendering topographic regional grid, district paths, and radar scans
class _GisMapCanvasPainter extends CustomPainter {
  final double pulseValue;
  final List<FarmGisMapMarker> farmMarkers;
  final List<OutbreakClusterModel> clusters;
  final String selectedDistrict;
  final bool showVaccinationOverlay;

  _GisMapCanvasPainter({
    required this.pulseValue,
    required this.farmMarkers,
    required this.clusters,
    required this.selectedDistrict,
    required this.showVaccinationOverlay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Tactical Topographic Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.6)
      ..strokeWidth = 0.8;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw Maharashtra State Contour Guide
    final contourPaint = Paint()
      ..color = const Color(0xFF334155).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(120, 80)
      ..lineTo(280, 100)
      ..lineTo(450, 160)
      ..lineTo(560, 260)
      ..lineTo(500, 420)
      ..lineTo(320, 450)
      ..lineTo(140, 360)
      ..lineTo(100, 220)
      ..close();

    canvas.drawPath(path, contourPaint);

    // 3. Draw District Boundary Corridors
    final districtPaint = Paint()
      ..color = const Color(0xFF475569).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Nashik District Polygon
    final nashikPath = Path()
      ..moveTo(150, 160)
      ..lineTo(270, 170)
      ..lineTo(260, 280)
      ..lineTo(160, 270)
      ..close();
    canvas.drawPath(nashikPath, districtPaint);

    // Pune District Polygon
    final punePath = Path()
      ..moveTo(270, 260)
      ..lineTo(390, 270)
      ..lineTo(380, 370)
      ..lineTo(270, 360)
      ..close();
    canvas.drawPath(punePath, districtPaint);

    // Label Nashik Hotspot Sector
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'NASHIK SURVEILLANCE SECTOR',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(155, 145));

    // Label Pune Sector
    final punePainter = TextPainter(
      text: const TextSpan(
        text: 'PUNE SECTOR',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    punePainter.paint(canvas, const Offset(280, 250));
  }

  @override
  bool shouldRepaint(covariant _GisMapCanvasPainter oldDelegate) => true;
}
