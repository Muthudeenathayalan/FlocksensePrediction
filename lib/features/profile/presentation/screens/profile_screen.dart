import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_providers.dart';
import 'package:flock_sense/features/farms/presentation/providers/selected_farm_provider.dart';
import 'package:flock_sense/features/profile/presentation/screens/app_settings_screen.dart';
import 'package:flock_sense/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:flock_sense/features/profile/presentation/screens/feedback_screen.dart';
import 'package:flock_sense/features/profile/presentation/screens/notification_settings_screen.dart';
import 'package:flock_sense/features/profile/presentation/screens/privacy_security_screen.dart';
import 'package:flock_sense/features/support/presentation/screens/help_support_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusLg)),
        title: const Text('Sign out of FlockSense?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('You will be logged out of your session and returned to the sign-in screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      if (ctx.mounted) {
        Navigator.pushNamedAndRemoveUntil(ctx, AppRoutes.initial, (_) => false);
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final authProfile = ref.watch(currentUserProfileProvider).value;
    final activeFarm = ref.watch(activeFarmContextProvider);

    final name = (authProfile?.name.isNotEmpty ?? false)
        ? authProfile!.name
        : (user?.displayName?.isNotEmpty == true ? user!.displayName! : 'User Administrator');
    final email = user?.email ?? authProfile?.email ?? 'demo@flocksense.in';
    final role = authProfile?.role.label ?? 'Commercial Poultry Farmer';
    final phone = (authProfile?.phoneNumber?.isNotEmpty ?? false)
        ? authProfile!.phoneNumber!
        : (user?.phoneNumber ?? '+91 98450 12345');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Web Header
          WebPageHeader(
            title: 'User Profile & Account',
            subtitle:
                'Manage user identity credentials, role permissions, active farm association, and system preferences.',
            actions: [
              AppButton(
                label: 'Sign Out',
                icon: Icons.logout_rounded,
                variant: AppButtonVariant.danger,
                size: AppButtonSize.small,
                onPressed: () => _logout(context),
              ),
            ],
          ),

          // 2. Responsive Multi-Column Layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              return isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Identity Card
                        SizedBox(
                          width: 360,
                          child: _buildIdentityCard(context, name, email, role, phone, initial, activeFarm),
                        ),
                        const SizedBox(width: 24),
                        // Right Settings & Controls
                        Expanded(
                          child: _buildSettingsSections(context),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildIdentityCard(context, name, email, role, phone, initial, activeFarm),
                        const SizedBox(height: 24),
                        _buildSettingsSections(context),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(
    BuildContext context,
    String name,
    String email,
    String role,
    String phone,
    String initial,
    ActiveFarmContext activeFarm,
  ) {
    return Column(
      children: [
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppDesign.subtleShadow,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: AppTypography.cardTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(fontSize: 13, color: AppColors.slate500),
              ),
              const SizedBox(height: 12),
              AppDesign.statusChip(
                role.toUpperCase(),
                AppColors.primaryLight,
                textColor: AppColors.primary,
                icon: Icons.verified_user_rounded,
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 16),

              // Contact & Facility Rows
              _infoTile(Icons.phone_rounded, 'Mobile Contact', phone),
              const SizedBox(height: 12),
              _infoTile(
                Icons.home_work_rounded,
                'Active Facility',
                activeFarm.farmName.isNotEmpty ? activeFarm.farmName : 'Green Valley Broiler Farm',
              ),
              const SizedBox(height: 12),
              _infoTile(
                Icons.location_on_rounded,
                'Assigned Region',
                'Coimbatore District, TN',
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Edit Profile Information',
                  icon: Icons.edit_rounded,
                  variant: AppButtonVariant.outlined,
                  size: AppButtonSize.small,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.slate400),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSections(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Preferences
        AppDesign.sectionTitle('Application & Notifications'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _settingRow(
                context,
                Icons.tune_rounded,
                AppColors.primary,
                'App & Display Settings',
                'Dark mode theme, language, and metric measurement units',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _settingRow(
                context,
                Icons.notifications_active_rounded,
                AppColors.warning,
                'Notification Preferences',
                'Critical disease alerts, daily mortality spikes, and vaccination reminders',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Security & Account
        AppDesign.sectionTitle('Security & Access Governance'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _settingRow(
                context,
                Icons.shield_outlined,
                AppColors.indigo,
                'Privacy & Security Credentials',
                'Two-factor authentication, active login sessions, and password management',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Help & Feedback
        AppDesign.sectionTitle('Support & Assistance'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _settingRow(
                context,
                Icons.help_outline_rounded,
                AppColors.primary,
                'Knowledge Base & Support',
                'User tutorials, disease diagnostic protocols, and emergency helpline',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _settingRow(
                context,
                Icons.chat_bubble_outline_rounded,
                AppColors.indigo,
                'Send App Feedback',
                'Report bugs or suggest biometric prediction feature improvements',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingRow(
    BuildContext context,
    IconData icon,
    Color iconColor,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.slate900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.slate500),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.slate400, size: 20),
      onTap: onTap,
    );
  }
}
