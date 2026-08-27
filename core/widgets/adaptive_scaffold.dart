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

          // 2. Main Content Canvas with Top Header
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
}
