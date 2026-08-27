import 'package:flutter/material.dart';
import 'package:flock_sense/core/responsive/app_breakpoints.dart';

/// Renders different widget trees based on the current screen width
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.tablet) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= AppBreakpoints.mobile) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

/// Helper builder for fine-grained responsive conditions
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < AppBreakpoints.mobile;
        final isTablet =
            constraints.maxWidth >= AppBreakpoints.mobile &&
            constraints.maxWidth < AppBreakpoints.tablet;
        final isDesktop = constraints.maxWidth >= AppBreakpoints.tablet;

        return builder(context, constraints, isMobile, isTablet, isDesktop);
      },
    );
  }
}
