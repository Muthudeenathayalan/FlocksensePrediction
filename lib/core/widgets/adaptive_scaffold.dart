import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/widgets/app_sidebar.dart';
import 'package:flock_sense/core/widgets/web_header.dart';

/// Permanent Web Application Shell for FlockSense Web Platform
class AdaptiveScaffold extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final String currentRole;
  final ValueChanged<String>? onRoleChanged;

  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.currentRole = 'Farmer',
    this.onRoleChanged,
  });

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Permanent Left Web Sidebar with explicit fixed width
          SizedBox(
            width: _isSidebarCollapsed
                ? AppDesign.sidebarCollapsedWidth
                : AppDesign.sidebarWidth,
            child: AppSidebar(
              selectedIndex: widget.selectedIndex,
              onItemSelected: widget.onDestinationSelected,
              isCollapsed: _isSidebarCollapsed,
              currentRole: widget.currentRole,
              onRoleChanged: widget.onRoleChanged,
              onToggleCollapse: () =>
                  setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            ),
          ),

          // 2. Main Content Canvas with Top Prototype Ribbon & Header
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Interactive SIH Prototype Ribbon ──────────────────────────
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    border: Border(
                      bottom: BorderSide(color: AppColors.healthyBorder, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppDesign.radiusXs),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'SIH PROTOTYPE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'FlockSense • Smart Poultry Disease Surveillance & Prediction Platform',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.healthy,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Telemetry (2.4s sync)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.healthy,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildRolePill('Farmer', Icons.agriculture_rounded),
                      const SizedBox(width: 6),
                      _buildRolePill('Veterinarian', Icons.medical_services_rounded),
                      const SizedBox(width: 6),
                      _buildRolePill('Government', Icons.policy_rounded),
                    ],
                  ),
                ),
                WebHeader(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  actions: widget.actions,
                  currentRole: widget.currentRole,
                  onRoleChanged: widget.onRoleChanged,
                ),
                Expanded(
                  child: widget.body,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildRolePill(String role, IconData icon) {
    final isSelected = widget.currentRole == role;
    return InkWell(
      onTap: () {
        if (widget.onRoleChanged != null) {
          widget.onRoleChanged!(role);
        }
      },
      borderRadius: BorderRadius.circular(AppDesign.radiusSm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDesign.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
          boxShadow: isSelected ? AppDesign.subtleShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.slate600,
            ),
            const SizedBox(width: 5),
            Text(
              role,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.slate700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
