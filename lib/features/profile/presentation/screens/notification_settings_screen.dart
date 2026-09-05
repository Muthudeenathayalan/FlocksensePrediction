import 'package:flutter/material.dart';
import 'package:flock_sense/core/services/notification_service.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/app_loading_indicator.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _daily = true;
  bool _mortality = true;
  bool _vaccine = true;
  bool _feed = false;
  bool _outbreaks = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await NotificationService.getPreferences();
    if (!mounted) return;
    setState(() {
      _daily = prefs['daily'] ?? true;
      _mortality = prefs['mortality'] ?? true;
      _vaccine = prefs['vaccine'] ?? true;
      _feed = prefs['feed'] ?? false;
      _outbreaks = true;
      _loaded = true;
    });
  }

  Future<void> _savePrefs() async {
    await NotificationService.savePreferences(
      daily: _daily,
      mortality: _mortality,
      vaccine: _vaccine,
      feed: _feed,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification preferences saved successfully'),
        backgroundColor: AppColors.primary,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Channels',
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
              title: 'Notification & Alert Subscriptions',
              subtitle:
                  'Configure real-time syndromic alerts, veterinary escalation triggers, and operational reminders.',
              breadcrumb: 'Profile / Notifications / Channels',
            ),

            if (!_loaded)
              const Padding(
                padding: EdgeInsets.all(40),
                child: AppLoadingIndicator(),
              )
            else ...[
              // 2. Critical Health & Disease Alerts
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppDesign.sectionTitle('Clinical & Biosecurity Alerts'),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('High Mortality Spike Warnings',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      subtitle: const Text('Instant notification when daily mortality exceeds 0.25% threshold',
                          style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                      value: _mortality,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _mortality = val),
                    ),
                    const Divider(height: 16, color: AppColors.divider),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Regional Disease & Outbreak Cordon Alerts',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      subtitle: const Text('Alerts when an active outbreak is verified within a 15km cluster buffer',
                          style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                      value: _outbreaks,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _outbreaks = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Operational Reminders
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppDesign.sectionTitle('Operational Reminders & Schedule'),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Daily Record Evening Reminder (7:00 PM)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      subtitle: const Text('Daily push reminder to submit mortality, feed, and water consumption logs',
                          style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                      value: _daily,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _daily = val),
                    ),
                    const Divider(height: 16, color: AppColors.divider),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vaccination Schedule Reminders',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      subtitle: const Text('Notifies 24 hours prior to scheduled flock immunization events',
                          style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                      value: _vaccine,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _vaccine = val),
                    ),
                    const Divider(height: 16, color: AppColors.divider),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Low Feed Silo Stock Warning',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      subtitle: const Text('Alert when available feed falls below 3 days of projected intake',
                          style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                      value: _feed,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _feed = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppButton(
                    label: 'Send Test Notification',
                    icon: Icons.notifications_active_outlined,
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.small,
                    onPressed: () async {
                      await NotificationService.showTestNotification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Test notification dispatched')),
                        );
                      }
                    },
                  ),
                  Row(
                    children: [
                      AppButton(
                        label: 'Cancel',
                        variant: AppButtonVariant.outlined,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        label: 'Save Preferences',
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: _savePrefs,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
