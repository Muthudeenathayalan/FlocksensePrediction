import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/health/presentation/widgets/outbreak_cluster_alert_card.dart';
import 'package:flock_sense/features/health/presentation/widgets/farm_prevention_dashboard_card.dart';

/// Dedicated Screen for Farmer Disease Alerts & Regional Outbreak Advisories (SIH26128)
class FarmerDiseaseAlertsScreen extends StatelessWidget {
  final String? district;

  const FarmerDiseaseAlertsScreen({
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
            title: 'Farm Disease Alerts & Bio-Security Warnings',
            subtitle: 'Regional syndromic early warnings, anonymized cluster buffers, and mandatory farm biosecurity advisories',
          ),
          OutbreakClusterAlertCard(
            district: districtName,
            isFarmerView: true,
          ),
          const SizedBox(height: 20),
          const FarmPreventionDashboardCard(
            farmId: 'farm_gv_01',
            farmName: 'Green Valley Poultry Farm',
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.security_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Recommended Farm Biosecurity Actions', style: AppTypography.cardTitle),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Activate vehicle wheel dip with 2% sodium hydroxide solution at entry gates.\n'
                  '• Restrict non-essential farm visitors and external feed transport drivers.\n'
                  '• Monitor daily feed and water consumption anomalies in all active sheds.\n'
                  '• Promptly report any spike above 3 dead birds/day via the Health Report Wizard.',
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
