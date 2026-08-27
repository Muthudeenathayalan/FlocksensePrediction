import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.content,
    this.icon,
    this.iconColor,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDanger = false,
    this.isLoading = false,
    this.actions,
    this.maxWidth = 520.0,
  });

  final String title;
  final String? subtitle;
  final Widget? content;
  final IconData? icon;
  final Color? iconColor;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDanger;
  final bool isLoading;
  final List<Widget>? actions;
  final double maxWidth;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => child,
    );
  }

  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    IconData icon = Icons.help_outline_rounded,
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: title,
        subtitle: message,
        icon: icon,
        iconColor: isDanger ? AppColors.critical : AppColors.primary,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDesign.radiusLg),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: AppDesign.modalShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: iconColor ?? AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: AppTypography.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: AppColors.slate400,
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.divider),

              // 2. Body
              if (content != null)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: content!,
                  ),
                ),

              // 3. Actions Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppDesign.radiusLg),
                    bottomRight: Radius.circular(AppDesign.radiusLg),
                  ),
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions ??
                      [
                        AppButton(
                          label: cancelLabel,
                          variant: AppButtonVariant.outlined,
                          size: AppButtonSize.small,
                          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
                        ),
                        const SizedBox(width: 12),
                        AppButton(
                          label: confirmLabel,
                          variant: isDanger
                              ? AppButtonVariant.danger
                              : AppButtonVariant.primary,
                          size: AppButtonSize.small,
                          isLoading: isLoading,
                          onPressed: onConfirm,
                        ),
                      ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
