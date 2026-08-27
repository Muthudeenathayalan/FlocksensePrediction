import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/health/presentation/widgets/outbreak_cluster_alert_card.dart';

/// Dedicated Screen for Veterinarian Disease Alerts & Cluster Warnings
class VeterinarianDiseaseAlertsScreen extends StatelessWidget {
  final String? district;

  const VeterinarianDiseaseAlertsScreen({
    super.key,
    this.district,
  });

  @override
  Widget build(BuildContext context) {
    final districtName = district ?? 'Nashik';

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebPageHeader(
            title: 'Disease Alerts & Spatial Cluster Warnings',
            subtitle: 'Regional epidemiological alerts, syndromic anomalies, and multi-farm spatial containment in $districtName',
          ),
          OutbreakClusterAlertCard(
            district: districtName,
            isFarmerView: false,
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Veterinary Advisory Protocols', style: AppTypography.cardTitle),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Maintain strict 5 km containment ring around confirmed viral respiratory clusters.\n'
                  '2. Enforce dead bird disposal audits and vehicle tire disinfection at farm gates.\n'
                  '3. Collect cloacal and tracheal swab specimens for cold-chain PCR transmission to Central Lab, Pune.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.slate900, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
