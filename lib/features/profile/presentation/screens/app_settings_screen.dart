import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  String _language = 'English (US)';
  String _unit = 'Metric (kg, °C)';
  bool _autoSync = true;
  bool _highContrast = false;
  bool _compactTables = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Application Settings',
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
              title: 'Application & UI Preferences',
              subtitle:
                  'Customize system measurement units, display density, offline sync intervals, and localization.',
              breadcrumb: 'Profile / Settings / Preferences',
            ),

            // 2. Localization & Measurement Units Card
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDesign.sectionTitle('Localization & Measurement Standards'),
                  const SizedBox(height: 12),

                  // Language
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('System Language',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate800)),
                          SizedBox(height: 2),
                          Text('Language used across telemetry charts and tables',
                              style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                        ],
                      ),
                      DropdownButton<String>(
                        value: _language,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'English (US)', child: Text('English (US)')),
                          DropdownMenuItem(value: 'Tamil (தமிழ்)', child: Text('Tamil (தமிழ்)')),
                          DropdownMenuItem(value: 'Hindi (हिंदी)', child: Text('Hindi (हिंदी)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _language = v);
                        },
                      ),
                    ],
                  ),

                  const Divider(height: 24, color: AppColors.divider),

                  // Measurement Units
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Measurement Units',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate800)),
                          SizedBox(height: 2),
                          Text('Body mass, feed weight, and ambient temperature',
                              style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                        ],
                      ),
                      DropdownButton<String>(
                        value: _unit,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'Metric (kg, °C)', child: Text('Metric (kg, °C)')),
                          DropdownMenuItem(value: 'Imperial (lbs, °F)', child: Text('Imperial (lbs, °F)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _unit = v);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Telemetry & Data Sync Card
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDesign.sectionTitle('Data Synchronization & Offline Cache'),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Background Cloud Sync',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Automatically upload pending offline farm records upon reconnecting',
                        style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                    value: _autoSync,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _autoSync = val),
                  ),

                  const Divider(height: 16, color: AppColors.divider),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Compact Data Tables',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Reduce row padding for dense multi-shed analytics view',
                        style: TextStyle(fontSize: 12, color: AppColors.slate500)),
                    value: _compactTables,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _compactTables = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Save Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'Save Preferences',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preferences saved successfully'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
