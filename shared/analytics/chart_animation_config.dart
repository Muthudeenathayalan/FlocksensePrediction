import 'package:flutter/material.dart';

/// Centralized Animation Configurations for FlockSense Analytics
class ChartAnimationConfig {
  ChartAnimationConfig._();

  /// Standard duration for initial chart entrance (line drawing, bar growth)
  static const Duration initialLoad = Duration(milliseconds: 750);

  /// Duration for real-time Firebase stream updates and value tweens
  static const Duration realtimeUpdate = Duration(milliseconds: 450);

  /// Duration for time range filter transitions (7D -> 30D -> 90D)
  static const Duration filterTransition = Duration(milliseconds: 350);

  /// Duration for hover/tap tooltip fade and movement
  static const Duration tooltipTransition = Duration(milliseconds: 180);

  /// Duration for KPI number count-up transitions
  static const Duration kpiCount = Duration(milliseconds: 650);

  /// Stagger delay between sequential bar or node animations
  static const Duration staggerDelay = Duration(milliseconds: 50);

  /// Standard entrance easing curve
  static const Curve defaultCurve = Curves.easeOutCubic;

  /// Smooth in-out curve for value transitions
  static const Curve smoothTransitionCurve = Curves.easeInOutCubic;

  /// Springy curve for subtle emphasis
  static const Curve emphasisCurve = Curves.easeOutBack;

  /// Check if the user has enabled OS or browser reduced motion
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
}
