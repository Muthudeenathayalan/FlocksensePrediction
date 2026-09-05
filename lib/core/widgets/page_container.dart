import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';

/// Standard Web Content Container for all FlockSense Web Screens.
/// Restrains max-width to ~1500px and applies consistent 24-32px padding.
class PageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;

  const PageContainer({
    super.key,
    required this.child,
    this.maxWidth = AppDesign.maxContentWidth,
    this.padding,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: double.infinity,
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: child,
      ),
    );

    final pageContent = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: content,
    );

    return Material(
      color: AppColors.background,
      child: scrollable ? pageContent : content,
    );
  }
}

