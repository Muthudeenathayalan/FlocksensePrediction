import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';

/// 1. Live IoT Radar Pulse Widget
/// Continuous expanding radar halo indicating live telemetry packet ingestion.
class LiveTelemetryPulse extends StatefulWidget {
  final Color color;
  final double size;

  const LiveTelemetryPulse({
    super.key,
    this.color = AppColors.healthy,
    this.size = 8.0,
  });

  @override
  State<LiveTelemetryPulse> createState() => _LiveTelemetryPulseState();
}

class _LiveTelemetryPulseState extends State<LiveTelemetryPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Expanding Radar Ring
            Container(
              width: widget.size + (_animation.value * 12),
              height: widget.size + (_animation.value * 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(
                  alpha: (1.0 - _animation.value) * 0.45,
                ),
              ),
            ),
            // Core Indicator Dot
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 2. Interactive Float & Glow Hover Card
/// Smooth micro-interaction for cards on mouse hover.
class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final double elevation;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.elevation = 4.0,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(AppDesign.radiusSm);

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -3.5 : 0, 0),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.surface,
            borderRadius: radius,
            border: _isHovered
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 1.2)
                : (widget.border ?? Border.all(color: AppColors.border)),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                    const BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : AppDesign.subtleShadow,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 3. Live Sensor Telemetry Ticker Strip
/// Real-time streaming sensor readings with subtle pulsing animation.
class LiveSensorTicker extends StatefulWidget {
  const LiveSensorTicker({super.key});

  @override
  State<LiveSensorTicker> createState() => _LiveSensorTickerState();
}

class _LiveSensorTickerState extends State<LiveSensorTicker> {
  Timer? _timer;
  double _temp = 27.2;
  double _humidity = 63.4;
  int _ammonia = 12;
  int _co2 = 850;
  int _secondsAgo = 1;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        // Minor realistic telemetry jitter
        _temp = double.parse((27.0 + (timer.tick % 5) * 0.1).toStringAsFixed(1));
        _humidity = double.parse((63.0 + (timer.tick % 4) * 0.2).toStringAsFixed(1));
        _ammonia = 11 + (timer.tick % 3);
        _co2 = 840 + (timer.tick % 6) * 5;
        _secondsAgo = 1;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(color: AppColors.border),
        boxShadow: AppDesign.subtleShadow,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 750;
          return Wrap(
            spacing: 20,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LiveTelemetryPulse(size: 8, color: AppColors.healthy),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE SENSOR BUS #01',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              _buildSensorPill(Icons.thermostat_outlined, 'Shed Temp', '$_temp°C', AppColors.healthy),
              _buildSensorPill(Icons.water_drop_outlined, 'Humidity', '$_humidity%', AppColors.healthy),
              _buildSensorPill(Icons.air_outlined, 'Ammonia (NH3)', '$_ammonia ppm', AppColors.healthy),
              _buildSensorPill(Icons.co2_outlined, 'CO2 Level', '$_co2 ppm', AppColors.healthy),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSensorPill(IconData icon, String label, String value, Color statusColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.slate500),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11.5, color: AppColors.slate600),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
          child: Text(
            value,
            key: ValueKey(value),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
            ),
          ),
        ),
      ],
    );
  }
}
