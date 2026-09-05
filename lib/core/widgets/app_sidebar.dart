import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';

class SidebarNavSection {
  final String title;
  final List<SidebarNavItem> items;

  const SidebarNavSection({
    required this.title,
    required this.items,
  });
}

class SidebarNavItem {
  final String title;
  final IconData icon;
  final int index;
  final String? badge;
  final Color? badgeColor;

  const SidebarNavItem({
    required this.title,
    required this.icon,
    required this.index,
    this.badge,
    this.badgeColor,
  });
}

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final String currentRole;
  final ValueChanged<String>? onRoleChanged;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.currentRole = 'Farmer',
    this.onRoleChanged,
  });

  int get _settingsIndex {
    if (currentRole == 'Government') return 11;
    if (currentRole == 'Veterinarian') return 12;
    return 13;
  }

  int get _profileIndex {
    if (currentRole == 'Government') return 12;
    if (currentRole == 'Veterinarian') return 13;
    return 14;
  }

  List<SidebarNavSection> _getSectionsForRole(String role) {
    if (role == 'Veterinarian') {
      return const [
        SidebarNavSection(
          title: 'COMMAND',
          items: [
            SidebarNavItem(title: 'Clinical Triage', icon: Icons.dashboard_outlined, index: 0),
            SidebarNavItem(title: 'Critical Queue', icon: Icons.local_hospital_outlined, index: 1, badge: 'P1', badgeColor: AppColors.critical),
            SidebarNavItem(title: 'Assigned Cases', icon: Icons.assignment_outlined, index: 2, badge: '5', badgeColor: AppColors.info),
            SidebarNavItem(title: 'District Pool', icon: Icons.hub_outlined, index: 3),
          ],
        ),
        SidebarNavSection(
          title: 'DIAGNOSTICS & CARE',
          items: [
            SidebarNavItem(title: 'Investigations', icon: Icons.biotech_outlined, index: 4),
            SidebarNavItem(title: 'Lab Requests', icon: Icons.science_outlined, index: 5),
            SidebarNavItem(title: 'Lab Results', icon: Icons.fact_check_outlined, index: 6),
            SidebarNavItem(title: 'Treatment Plans', icon: Icons.medication_outlined, index: 7),
            SidebarNavItem(title: 'Follow-ups', icon: Icons.event_repeat_outlined, index: 8),
          ],
        ),
        SidebarNavSection(
          title: 'SURVEILLANCE & AI',
          items: [
            SidebarNavItem(title: 'Disease Alerts', icon: Icons.notifications_active_outlined, index: 9, badge: 'ALERT', badgeColor: AppColors.warning),
            SidebarNavItem(title: 'Analytics & Trends', icon: Icons.analytics_outlined, index: 10),
            SidebarNavItem(title: 'AI Assistant', icon: Icons.auto_awesome_outlined, index: 11),
          ],
        ),
      ];
    } else if (role == 'Government') {
      return const [
        SidebarNavSection(
          title: 'COMMAND CENTER',
          items: [
            SidebarNavItem(title: 'Command Center', icon: Icons.admin_panel_settings_outlined, index: 0),
          ],
        ),
        SidebarNavSection(
          title: 'SURVEILLANCE',
          items: [
            SidebarNavItem(title: 'Disease Map', icon: Icons.map_outlined, index: 1, badge: 'LIVE', badgeColor: AppColors.critical),
            SidebarNavItem(title: 'Outbreaks', icon: Icons.warning_amber_rounded, index: 2, badge: '1', badgeColor: AppColors.highRisk),
            SidebarNavItem(title: 'District Surveillance', icon: Icons.location_city_outlined, index: 3),
            SidebarNavItem(title: 'Cases', icon: Icons.sick_outlined, index: 4),
          ],
        ),
        SidebarNavSection(
          title: 'PREVENTION',
          items: [
            SidebarNavItem(title: 'Vaccination Surveillance', icon: Icons.vaccines_outlined, index: 5),
            SidebarNavItem(title: 'Biosecurity / Prevention', icon: Icons.shield_outlined, index: 6),
          ],
        ),
        SidebarNavSection(
          title: 'RESPONSE',
          items: [
            SidebarNavItem(title: 'Veterinary Response', icon: Icons.medical_services_outlined, index: 7),
            SidebarNavItem(title: 'Laboratory Surveillance', icon: Icons.science_outlined, index: 8),
          ],
        ),
        SidebarNavSection(
          title: 'INTELLIGENCE',
          items: [
            SidebarNavItem(title: 'Analytics', icon: Icons.bar_chart_outlined, index: 9),
            SidebarNavItem(title: 'Reports', icon: Icons.file_download_outlined, index: 10),
          ],
        ),
      ];
    }

    // Default: Farmer Navigation
    return const [
      SidebarNavSection(
        title: 'OVERVIEW',
        items: [
          SidebarNavItem(title: 'Dashboard', icon: Icons.dashboard_outlined, index: 0),
        ],
      ),
      SidebarNavSection(
        title: 'FARM MANAGEMENT',
        items: [
          SidebarNavItem(title: 'My Farms', icon: Icons.storefront_outlined, index: 1),
          SidebarNavItem(title: 'Flocks & Batches', icon: Icons.grid_view_outlined, index: 2),
          SidebarNavItem(title: 'Daily Records', icon: Icons.edit_note_outlined, index: 3),
        ],
      ),
      SidebarNavSection(
        title: 'ANIMAL HEALTH',
        items: [
          SidebarNavItem(title: 'Health & Disease', icon: Icons.healing_outlined, index: 4),
          SidebarNavItem(title: 'Vaccination', icon: Icons.vaccines_outlined, index: 5),
          SidebarNavItem(title: 'Treatments', icon: Icons.medication_outlined, index: 6),
          SidebarNavItem(title: 'Disease Alerts', icon: Icons.notifications_active_outlined, index: 7, badge: '3', badgeColor: AppColors.warning),
        ],
      ),
      SidebarNavSection(
        title: 'OPERATIONS',
        items: [
          SidebarNavItem(title: 'Feed & Water', icon: Icons.water_drop_outlined, index: 8),
          SidebarNavItem(title: 'Inventory Stock', icon: Icons.inventory_2_outlined, index: 9),
        ],
      ),
      SidebarNavSection(
        title: 'INTELLIGENCE',
        items: [
          SidebarNavItem(title: 'Reports & Export', icon: Icons.description_outlined, index: 10),
          SidebarNavItem(title: 'AI Assistant', icon: Icons.auto_awesome_outlined, index: 11),
          SidebarNavItem(title: 'Analytics & FCR', icon: Icons.insights_outlined, index: 12),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sections = _getSectionsForRole(currentRole);
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    return Container(
      width: isCollapsed ? AppDesign.sidebarCollapsedWidth : AppDesign.sidebarWidth,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. App Branding Header
          Container(
            height: AppDesign.headerHeight,
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 16 : 20,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FlockSense',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'SIH26128 • $currentRole',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onToggleCollapse != null)
                    IconButton(
                      icon: const Icon(Icons.menu_open_rounded, size: 18),
                      color: AppColors.slate500,
                      onPressed: onToggleCollapse,
                      tooltip: 'Collapse sidebar',
                      splashRadius: 16,
                    ),
                ],
              ],
            ),
          ),

          // 2. Navigation Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: sections.map((sec) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCollapsed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                        child: Text(
                          sec.title,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.slate500,
                          ),
                        ),
                      ),
                    ...sec.items.map((item) {
                      final isSelected = selectedIndex == item.index;

                      Widget button = Material(
                        color: isSelected ? AppColors.primarySoft : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                        child: InkWell(
                          onTap: () => onItemSelected(item.index),
                          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                          hoverColor: AppColors.slate100,
                          child: Container(
                            height: 38,
                            padding: EdgeInsets.symmetric(
                              horizontal: isCollapsed ? 12 : 12,
                            ),
                            decoration: isSelected
                                ? BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                                    border: Border.all(
                                      color: AppColors.healthyBorder.withValues(alpha: 0.8),
                                      width: 1,
                                    ),
                                  )
                                : null,
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 18,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.slate500,
                                ),
                                if (!isCollapsed) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.primaryDark
                                            : AppColors.slate700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.badge != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (item.badgeColor ?? AppColors.primary).withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(AppDesign.radiusXs),
                                        border: Border.all(
                                          color: (item.badgeColor ?? AppColors.primary).withOpacity(0.4),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        item.badge!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: item.badgeColor ?? AppColors.primaryLight,
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );

                      if (isCollapsed) {
                        return Tooltip(
                          message: item.title,
                          preferBelow: false,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: button,
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: button,
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),

          // 3. Bottom Settings & User Profile
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Settings Item
                Material(
                  color: selectedIndex == _settingsIndex ? AppColors.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                  child: InkWell(
                    onTap: () => onItemSelected(_settingsIndex),
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                    hoverColor: AppColors.slate100,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: selectedIndex == _settingsIndex
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                              border: Border.all(
                                color: AppColors.healthyBorder.withValues(alpha: 0.8),
                                width: 1,
                              ),
                            )
                          : null,
                      child: Row(
                        children: [
                          Icon(
                            Icons.settings_outlined,
                            size: 18,
                            color: selectedIndex == _settingsIndex ? AppColors.primary : AppColors.slate500,
                          ),
                          if (!isCollapsed) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selectedIndex == _settingsIndex ? FontWeight.w700 : FontWeight.w500,
                                  color: selectedIndex == _settingsIndex ? AppColors.primaryDark : AppColors.slate700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // User Info
                if (!isCollapsed)
                  Material(
                    color: selectedIndex == _profileIndex ? AppColors.primarySoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                    child: InkWell(
                      onTap: () => onItemSelected(_profileIndex),
                      borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                      hoverColor: AppColors.slate100,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selectedIndex == _profileIndex ? AppColors.primarySoft : AppColors.slate50,
                          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                          border: Border.all(
                            color: selectedIndex == _profileIndex ? AppColors.healthyBorder : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                user?.email != null && user!.email!.isNotEmpty
                                    ? user.email![0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.displayName ?? user?.email?.split('@').first ?? 'Dr. V. Sharma',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slate900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$currentRole Access',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.slate500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
