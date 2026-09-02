import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/intelligence/domain/environmental_intelligence_model.dart';

/// Farmer & Clinician Component: Thermal & Environmental Intelligence (Part 4)
/// Displays Current Shed Temp, Humidity, Target Range, THI Stress, Surface Temp, and Comfort Band
class ThermalEnvironmentWidget extends StatelessWidget {
  final EnvironmentalStressResult result;
  final VoidCallback? onLogThermalScan;

  const ThermalEnvironmentWidget({
    super.key,
    required this.result,
    this.onLogThermalScan,
  });

  @override
  Widget build(BuildContext context) {
    final isAlert = result.environmentalStressLevel == EnvironmentalStressLevel.alert;
    final isHigh = result.environmentalStressLevel == EnvironmentalStressLevel.high;
    final isCritical = result.environmentalStressLevel == EnvironmentalStressLevel.critical;

    Color badgeColor = AppColors.healthy;
    if (isCritical) {
      badgeColor = AppColors.critical;
    } else if (isHigh || isAlert) {
      badgeColor = AppColors.warning;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.thermostat_outlined, color: badgeColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thermal & Environmental Telemetry', style: AppTypography.headingSmall),
                      Text(
                        'Target profile: ${result.targetProfile.productionType} (Age Day ${result.targetProfile.ageMinDays}-${result.targetProfile.ageMaxDays})',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              StatusBadge(
                label: 'STRESS: ${result.environmentalStressLevel.label}',
                type: isCritical
                    ? StatusBadgeType.critical
                    : (isHigh || isAlert ? StatusBadgeType.warning : StatusBadgeType.healthy),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 Telemetry Value Tiles
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              final tileWidth = isNarrow ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildTelemetryTile(
                    title: 'Shed Ambient Temp',
                    value: '${result.ambientTemperature.toStringAsFixed(1)}°C',
                    target: 'Target: ${result.targetProfile.targetTempMin}-${result.targetProfile.targetTempMax}°C',
                    isOutOfRange: result.ambientTemperature > result.targetProfile.targetTempMax ||
                        result.ambientTemperature < result.targetProfile.targetTempMin,
                    icon: Icons.device_thermostat_rounded,
                    width: tileWidth,
                  ),
                  _buildTelemetryTile(
                    title: 'Relative Humidity',
                    value: '${result.humidity.toStringAsFixed(0)}%',
                    target: 'Target: ${result.targetProfile.targetHumidityMin}-${result.targetProfile.targetHumidityMax}%',
                    isOutOfRange: result.humidity > result.targetProfile.targetHumidityMax ||
                        result.humidity < result.targetProfile.targetHumidityMin,
                    icon: Icons.water_drop_outlined,
                    width: tileWidth,
                  ),
                  _buildTelemetryTile(
                    title: 'THI Heat Stress',
                    value: result.thi.toStringAsFixed(1),
                    target: result.thi >= 80 ? 'Severe Heat Load' : 'Normal Range (<78)',
                    isOutOfRange: result.thi >= 78,
                    icon: Icons.speed_rounded,
                    width: tileWidth,
                  ),
                  _buildTelemetryTile(
                    title: 'Surface Temp',
                    value: result.surfaceTemperature != null
                        ? '${result.surfaceTemperature!.toStringAsFixed(1)}°C'
                        : 'Calibrated',
                    target: result.thermalHotspotCount > 0
                        ? '${result.thermalHotspotCount} Hotspots'
                        : '0 Hotspots',
                    isOutOfRange: result.thermalHotspotCount > 0,
                    icon: Icons.camera_indoor_outlined,
                    width: tileWidth,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Visual Target Comfort Band Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Flock Thermal Comfort Band (24h Trend)',
                        style: AppTypography.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Comfort Window: ${result.targetProfile.targetTempMin}°C — ${result.targetProfile.targetTempMax}°C',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (result.ambientTemperature / 45.0).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: AppColors.slate200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      result.ambientTemperature > result.targetProfile.warningTempMax
                          ? AppColors.critical
                          : (result.ambientTemperature > result.targetProfile.targetTempMax
                              ? AppColors.warning
                              : AppColors.healthy),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.explanation,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.slate700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Advisory
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.slate500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  result.advisory,
                  style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryTile({
    required String title,
    required String value,
    required String target,
    required bool isOutOfRange,
    required IconData icon,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOutOfRange ? AppColors.warningLight.withOpacity(0.3) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(
          color: isOutOfRange ? AppColors.warning.withOpacity(0.5) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.caption,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: isOutOfRange ? AppColors.warning : AppColors.slate500),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.headingMedium.copyWith(
              color: isOutOfRange ? AppColors.critical : AppColors.slate900,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            target,
            style: AppTypography.caption.copyWith(color: AppColors.slate600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
