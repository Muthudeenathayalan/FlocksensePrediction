import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _ctrl = TextEditingController();
  int _rating = 5;
  String _category = 'Feature Improvement';
  bool _sending = false;

  final _categories = [
    'Feature Improvement',
    'AI Health Predictions',
    'Report Exports',
    'Offline Sync / Performance',
    'Bug Report',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your feedback or observation')),
      );
      return;
    }
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you! Your feedback has been received.'),
        backgroundColor: AppColors.primary,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Send App Feedback',
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
              title: 'Share Feedback & Product Insights',
              subtitle:
                  'Help us refine FlockSense AI predictions, user experience, and farm management workflows.',
              breadcrumb: 'Profile / Support / Send Feedback',
            ),

            // 2. Feedback Form Card
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDesign.sectionTitle('Feedback Category'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _category == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.primaryLight,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.slate700,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _category = cat);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  AppDesign.sectionTitle('Platform Experience Rating'),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 32,
                          color: starValue <= _rating
                              ? AppColors.warning
                              : AppColors.slate300,
                        ),
                        onPressed: () => setState(() => _rating = starValue),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),
                  AppDesign.sectionTitle('Your Notes & Observations'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ctrl,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 14, color: AppColors.slate900),
                    decoration: InputDecoration(
                      hintText:
                          'Share what you like or describe any difficulty encountered with daily logging, mortality alerts, or FCR charts...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.slate400),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                AppButton(
                  label: 'Submit Feedback',
                  icon: Icons.send_rounded,
                  isLoading: _sending,
                  onPressed: _sending ? null : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
