import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/settings/presentation/widgets/change_password_dialog.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy & Security',
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
        maxWidth: AppDesign.maxFormWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            const WebPageHeader(
              title: 'Account Security & Data Protection',
              subtitle:
                  'Manage account credentials, authentication methods, active web sessions, and platform data privacy.',
              breadcrumb: 'Profile / Security & Access',
            ),

            // 2. Authentication Credentials Card
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDesign.sectionTitle('Authentication & Password'),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                      ),
                      child: const Icon(Icons.lock_reset_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    title: const Text('Change Password',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Update your secret master password to maintain security',
                        style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                    trailing: AppButton(
                      label: 'Change Password',
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.small,
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const ChangePasswordDialog(),
                      ),
                    ),
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                      ),
                      child: const Icon(Icons.verified_user_rounded,
                          color: AppColors.emerald, size: 20),
                    ),
                    title: const Text('Two-Factor Verification (2FA)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Require SMS OTP verification for sensitive role escalations',
                        style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                    trailing: AppDesign.statusChip(
                      'ENFORCED',
                      AppColors.healthyBg,
                      textColor: AppColors.healthy,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Active Session Info Card
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDesign.sectionTitle('Active Session & Device Identity'),
                  const SizedBox(height: 12),
                  _sessionRow(
                    'Chrome Browser on Windows 11 (This Device)',
                    'IP: 172.16.69.155 • Active right now',
                    Icons.laptop_mac_rounded,
                    true,
                  ),
                  const Divider(height: 20, color: AppColors.divider),
                  _sessionRow(
                    'FlockSense Mobile App (Android 14)',
                    'Coimbatore, TN • Last synced 2 hours ago',
                    Icons.phone_android_rounded,
                    false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Data Privacy Card
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDesign.sectionTitle('Data Governance & Farm Confidentiality'),
                  const SizedBox(height: 8),
                  const Text(
                    'FlockSense complies with state animal health surveillance data protocols. Farm clinical telemetry is shared with assigned district veterinary officers solely for disease outbreak mitigation and authorized veterinary assistance.',
                    style: TextStyle(fontSize: 13, color: AppColors.slate600, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionRow(String title, String subtitle, IconData icon, bool isCurrent) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.slate500),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
            ],
          ),
        ),
        if (isCurrent)
          AppDesign.statusChip(
            'CURRENT',
            AppColors.primaryLight,
            textColor: AppColors.primary,
          ),
      ],
    );
  }
}
