import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/metric_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/profile/presentation/screens/feedback_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support Center',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            WebPageHeader(
              title: 'Knowledge Base & Customer Assistance',
              subtitle:
                  'Browse operational FAQs, veterinary disease response guides, technical documentation, and contact emergency support.',
              breadcrumb: 'Support / Knowledge Base',
              actions: [
                AppButton(
                  label: 'Submit Feedback / Inquiry',
                  icon: Icons.chat_rounded,
                  size: AppButtonSize.small,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                  ),
                ),
              ],
            ),

            // 2. Emergency Hotline Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 768;
                return GridView.count(
                  crossAxisCount: isDesktop ? 3 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isDesktop ? 3.0 : 4.0,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    MetricCard(
                      title: 'Veterinary Emergency Helpline',
                      value: '1800-425-3456',
                      subtitle: '24/7 State Animal Disease Triage',
                      icon: Icons.emergency_rounded,
                      accentColor: AppColors.danger,
                    ),
                    MetricCard(
                      title: 'Technical SaaS Support',
                      value: 'support@flocksense.in',
                      subtitle: 'Response within 2 hours',
                      icon: Icons.headset_mic_rounded,
                      accentColor: AppColors.primary,
                    ),
                    MetricCard(
                      title: 'Platform Version',
                      value: 'v2.4.0 (Enterprise)',
                      subtitle: 'Offline Sync Engine Active',
                      icon: Icons.verified_rounded,
                      accentColor: AppColors.emerald,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // 3. FAQ Accordions Card
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDesign.sectionTitle('Frequently Asked Questions (FAQs)'),
                  const SizedBox(height: 8),

                  _faqTile(
                    'How does the AI Early Warning Health Risk Matrix work?',
                    'FlockSense evaluates multi-parameter inputs including daily mortality spikes, feed intake deviations (> 7%), water consumption drops, and the Temperature-Humidity Index (THI). When anomaly scores exceed baseline thresholds, the system automatically alerts assigned veterinarians and suggests immediate biosecurity protocols.',
                  ),
                  const Divider(height: 1, color: AppColors.divider),

                  _faqTile(
                    'Can I log daily records when offline in rural shed areas?',
                    'Yes! FlockSense features a local Hive storage layer. You can record daily mortality, feed, and water metrics completely offline. Once internet connectivity is restored, the platform automatically synchronizes pending logs with Cloud Firestore.',
                  ),
                  const Divider(height: 1, color: AppColors.divider),

                  _faqTile(
                    'How is Feed Conversion Ratio (FCR) calculated?',
                    'FCR is computed as (Cumulative Feed Consumed in kg) ÷ (Total Live Weight Gain in kg). FlockSense continuously compares live batch FCR against Cobb 500 and Ross 308 breed standard benchmarks to pinpoint performance lags.',
                  ),
                  const Divider(height: 1, color: AppColors.divider),

                  _faqTile(
                    'How do I generate and export audit reports for lenders or auditors?',
                    'Navigate to the Reports & Export section in the sidebar. Select your desired date range, farm shed, and batch identifier, then choose between PDF Audit Summary, Excel Spreadsheet (.xlsx), or CSV data stream format.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqTile(String question, String answer) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(vertical: 4),
      childrenPadding: const EdgeInsets.only(bottom: 16),
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.slate900,
        ),
      ),
      children: [
        Text(
          answer,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.slate600,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
